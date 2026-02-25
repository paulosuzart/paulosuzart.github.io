---
layout: post
title: "Prometheus Metrics on Fly.io with Axum and Dioxus"
date: 2026-02-25 10:00
comments: true
tags: [rust, dioxus, axum, fly.io, prometheus]
---

Hey you, welcome! Today I want to share something I put together while building [hot_dog](https://github.com/paulosuzart/hot_dog), a small Dioxus fullstack app that I host on [Fly.io](https://fly.io/). The mission: expose Prometheus metrics on a **separate port** from the main application, without leaking them to the public internet. Sounds simple, right? Well, it involves a few moving pieces that I think are worth talking about.

<!--more-->

The complete source is on [GitHub](https://github.com/paulosuzart/hot_dog). Let's tear it apart.

# The project

`hot_dog` is a Dioxus fullstack application. If you are not familiar with [Dioxus](https://dioxuslabs.com/), think of it as a React-inspired framework for Rust that covers web, desktop, mobile, and server-side rendering under one roof. The `fullstack` feature means the server side is powered by Axum — Dioxus wraps it up so you don't always see it directly. But knowing it's there opens some doors.

The goal here is simple: plug in [Prometheus](https://prometheus.io/) metrics via [axum-prometheus](https://crates.io/crates/axum-prometheus) and serve them on a dedicated port (9090) that Fly.io's internal monitoring can scrape — without that port ever being publicly reachable. Security through network topology, not through passwords.

# Dependencies

Let's start with the `Cargo.toml`. The project uses Cargo feature flags to split desktop, web, and server builds cleanly:

```toml
[dependencies]
dioxus = { version = "0.7.3", features = ["router", "fullstack", "logger"] }
tokio = { version = "1.49.0", features = ["sync", "rt-multi-thread", "net"], optional = true }
axum = { version = "0.8", optional = true }
axum-prometheus = { version = "0.10.0", optional = true }
tracing-subscriber = { version = "0.3", optional = true }

[features]
default = []
web = []
desktop = []
server = ["libsql", "tokio", "base64", "axum-prometheus", "axum", "tracing-subscriber"]
```

Everything server-side — `tokio`, `axum`, `axum-prometheus` — lives behind the `server` feature gate. When you build for the web target, none of that compiles in. Clean separation that makes the binary for each target leaner.

The key crate here is `axum-prometheus`. It provides a `PrometheusMetricLayerBuilder` that you attach to an Axum router as middleware. It instruments every request passing through automatically and exposes a handle to render the metrics in Prometheus text format.

# Two listeners

Here is the heart of it. The `main` function (only compiled when `--features server` is active) sets up **two independent TCP listeners**: one for the main application on port 8080, and one for metrics on port 9090.

```rust
#[cfg(feature = "server")]
#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    tracing_subscriber::fmt::init();
    use axum::{routing::get, Router};
    use axum_prometheus::PrometheusMetricLayerBuilder;

    let (prometheus_layer, metric_handle) = PrometheusMetricLayerBuilder::new()
        .with_default_metrics()
        .build_pair();

    let metrics = Router::new()
        .route("/metrics", get(|| async move { metric_handle.render() }));

    let metrics_ip = std::env::var("HD_METRICS_IP").unwrap_or_else(|_| "0.0.0.0".to_string());
    let metrics_port = std::env::var("HD_METRICS_PORT").unwrap_or_else(|_| "9090".to_string());

    let metrics_listener =
        tokio::net::TcpListener::bind(format!("{metrics_ip}:{metrics_port}")).await?;

    let router = dioxus::server::router(app).layer(prometheus_layer);

    let ip = std::env::var("IP").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let listener = tokio::net::TcpListener::bind(format!("{ip}:{port}")).await?;

    tokio::try_join!(
        axum::serve(listener, router),
        axum::serve(metrics_listener, metrics)
    )?;

    Ok(())
}
```

`PrometheusMetricLayerBuilder::build_pair()` returns two things: a **layer** you attach to the router that captures metrics per request, and a **handle** you use elsewhere to render the accumulated data. They are linked internally through an `Arc`-wrapped registry — the layer writes, the handle reads.

The `metrics` router is dead simple: a single `GET /metrics` route that calls `metric_handle.render()`, which formats everything in Prometheus text exposition format.

The main router comes from Dioxus: `dioxus::server::router(app)`. Dioxus builds an Axum `Router` under the hood, serving your SSR pages and any server functions. You just `.layer(prometheus_layer)` on top of it, and every HTTP request to your Dioxus app is now instrumented.

Finally, `tokio::try_join!` runs both servers concurrently. If either one fails, the whole future fails. This is important — you don't want the app running without observability, nor the metrics server dangling alone if the app crashes.

# Two routers

It's worth pausing here to appreciate the design. We have two completely separate `Router` instances:

1. **Application router** — serves the Dioxus fullstack app on port 8080, with the Prometheus layer attached as middleware
2. **Metrics router** — a minimal Axum router on port 9090, exposing only `/metrics`

Why keep them separate? Because the metrics endpoint doesn't need to go through all the application middleware (authentication layers, CORS, etc. that you might add later). And more importantly, it binds to a **different port** entirely. Fly.io's public-facing HTTP proxy only routes to port 8080. Port 9090 is only accessible internally within the Fly.io private network — where their Prometheus scraper lives.

This is the security trick. No firewall rules to write. No auth tokens on `/metrics`. Just topology.

# Dockerfile

The Docker setup uses a multi-stage build with [cargo-chef](https://github.com/LukeMathWalker/cargo-chef) for layer caching — a huge win for CI build times since Rust dependencies don't recompile unless `Cargo.lock` changes.

```dockerfile
FROM rust:1 AS chef
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .

# Install dx CLI
RUN curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
RUN cargo binstall dioxus-cli --root /.cargo -y --force
ENV PATH="/.cargo/bin:$PATH"

# Bundle the web release
RUN dx bundle --web --release

FROM chef AS runtime
COPY --from=builder /app/target/dx/hot_dog/release/web/ /usr/local/app

ENV PORT=8080
ENV IP=0.0.0.0

EXPOSE 8080
EXPOSE 9090

WORKDIR /usr/local/app
ENTRYPOINT [ "/usr/local/app/hot_dog" ]
```

A few things to highlight:

- The `planner` stage generates a `recipe.json` that describes dependencies without building them. The `builder` stage uses this to `cargo chef cook` — compiling only deps first, cached as a Docker layer. Your actual source code change only invalidates the last step.
- `dx bundle --web --release` is the Dioxus CLI command that compiles the server binary (`--features server` is implied by fullstack), the WASM client, and bundles static assets together.
- The runtime stage copies the bundle from `/app/target/dx/hot_dog/release/web/` and sets `IP=0.0.0.0` so the server binds to all interfaces (necessary inside a container).
- Both `EXPOSE 8080` and `EXPOSE 9090` are declared. This is documentation-level — Docker `EXPOSE` doesn't actually publish ports, but it signals intent and is used by orchestrators like Fly.io to understand what the container offers.

# Fly.io configuration

Now the part that ties it all together. The `fly.toml`:

```toml
app = 'hot-dog-still-tree-2047'
primary_region = 'fra'

[env]
  RUST_LOG = "info"

[build]

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = 'stop'
  auto_start_machines = true
  min_machines_running = 0
  processes = ['app']

[[vm]]
  memory = '1gb'
  cpu_kind = 'shared'
  cpus = 1
  memory_mb = 1024

[metrics]
  port = 9090
  path = "/metrics"
  processes = ["app"]
```

The `[http_service]` block tells Fly.io's edge proxy to route public HTTPS traffic to internal port 8080. That's your Dioxus app. `force_https` and the auto stop/start policies are quality-of-life for a low-traffic personal app — machines spin down when idle and back up on the first request.

The `[metrics]` block is where the magic happens for observability. Fly.io's internal Prometheus scraper will call `GET /metrics` on port 9090 of each running machine. Since this port is never registered in `[http_service]`, it is **not reachable from the public internet** — only accessible from within Fly.io's private network. Your metrics are safe from curious fingers and potential abuse.

You can then view the scraped metrics in Fly.io's built-in Grafana dashboards, or even connect your own Prometheus instance via the Fly.io metrics federation endpoint.

# Conclusion

What I like about this setup is how naturally the security model falls out of the architecture. You don't need to put a reverse proxy in front of your metrics, you don't need to add HTTP basic auth to `/metrics`, and you don't need firewall rules. The separation of concerns — two routers, two listeners, two ports — maps directly onto the Fly.io network model where only one of those ports is publicly exposed.

`tokio::try_join!` deserves a mention too. It's the kind of primitive that makes async Rust feel elegant: run both servers concurrently, treat them as a unit, fail fast if either goes down. No daemon management, no supervisord, just the type system and the runtime working together.

Dioxus fullstack is still maturing, and I don't recommend it for production if you need battle-tested stability. But for a personal project where you want SSR + WASM + server functions in one Rust codebase, it's a genuinely exciting stack. And as this post shows, since it's Axum under the hood, you can reach in and do things like plug in observability layers without fighting the framework.

Give [hot_dog](https://github.com/paulosuzart/hot_dog) a look if you want to see all of this in context. Feedback and PRs welcome.
