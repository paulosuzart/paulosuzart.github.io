---
layout: post
title: "True Isomorphic Rust: One Codebase for Server and Browser with Dioxus"
date: 2026-03-03 10:00
comments: true
tags: [rust, dioxus, wasm, axum, fullstack]
---

Hey you, welcome back! This post continues the series on [hot_dog](https://github.com/paulosuzart/hot_dog), my small Dioxus fullstack app hosted on Fly.io. Last time we covered [Prometheus metrics on a separate port](/2026/02/25/prometheus-metrics-fly-io-axum-dioxus/). Today I want to zoom out and talk about the thing that makes all of that possible: a single Rust codebase that compiles to both a browser WASM bundle and a server binary — no JavaScript, no separate repos, no duplication.

<!--more-->

# The idea: one codebase, two targets

In the JavaScript world "isomorphic" apps run the same code on server and client. Dioxus takes that concept into Rust territory. You write your UI components once, and the framework handles rendering them server-side (SSR) for the first paint and then hydrating the client-side WASM bundle for interactivity. The trick Dioxus (and Rust in general) uses to pull this off cleanly is **Cargo features**.

# Cargo features as a compile-time wall

Look at `Cargo.toml`:

```toml
[dependencies]
dioxus = { version = "0.7.3", features = ["router", "fullstack", "logger"] }
libsql        = { version = "0.9.29",  optional = true }
tokio         = { version = "1.49.0",  features = ["sync", "rt-multi-thread", "net"], optional = true }
base64        = { version = "0.22.1",  optional = true }
axum-prometheus = { version = "0.10.0", optional = true }
axum          = { version = "0.8",     optional = true }
tracing-subscriber = { version = "0.3", optional = true }

[features]
default = []
web     = ["dioxus/web"]
desktop = ["dioxus/desktop"]
mobile  = ["dioxus/mobile"]
server  = ["dioxus/server", "dep:libsql", "dep:tokio", "dep:base64",
           "dep:axum-prometheus", "dep:axum", "dep:tracing-subscriber"]
```

Everything that has no business being in a browser binary — the database client, the async runtime, the HTTP layer, the metrics middleware — is `optional = true` and pulled in only by the `server` feature. When Dioxus CLI builds the WASM bundle it activates the `web` feature; when building the server binary it activates `server`. The Rust compiler enforces the split at link time: if you accidentally reference `libsql` from client-only code, it won't compile with the `web` feature.

This is not a runtime flag or a dynamic import. It is a **compile-time wall**. The browser bundle literally does not contain a single byte of database or Axum code.

# Two `main()` functions in one file

The same wall extends into `src/main.rs`:

```rust
#[cfg(feature = "server")]
#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    tracing_subscriber::fmt::init();
    // ... Axum routers, Prometheus layer, TCP listeners ...
    tokio::try_join!(
        axum::serve(listener, router),
        axum::serve(metrics_listener, metrics)
    )?;
    Ok(())
}

#[cfg(not(feature = "server"))]
fn main() {
    dioxus::launch(app);
}
```

Two `main()` functions co-exist in the same file because they are gated by `#[cfg]` — the compiler sees only one of them depending on which feature is active. The server entry point is async (needs `tokio`), the browser entry point is a plain synchronous `fn` that hands off to the Dioxus WASM runtime. There is no `if cfg!(target_arch = "wasm32")` runtime check; it all disappears at compile time.

# The shared app root

The `app` function is the bridge — it is the same for both targets:

```rust
fn app() -> Element {
    rsx! {
        document::Stylesheet { href: asset!("/assets/tailwind.css") }
        document::Stylesheet { href: asset!("/assets/dx-components-theme.css") }
        ToastProvider { Router::<Route> {} }
    }
}
```

On the server, `dioxus::server::router(app)` wraps this in an Axum router that SSR-renders it for each request. On the client, `dioxus::launch(app)` hydrates the pre-rendered HTML and makes it interactive. You write `app` once.

# Type-safe routing with `#[derive(Routable)]`

Routing is where Dioxus really shines compared to string-based routers. Routes are defined as an enum:

```rust
#[derive(Clone, Debug, PartialEq, Eq, Hash, Routable)]
pub enum Route {
    #[route("/")]
    MainView,
    #[route("/settings")]
    SettingsView,
    #[route("/about")]
    AboutView,
    #[route("/kid/:id")]
    KidHistory { id: u32 },
    #[route("/history")]
    NotesHistoryView,
}
```

A few things worth noting here:

- **Parameterized routes are typed.** `KidHistory { id: u32 }` means the `id` segment is parsed into a `u32` at the framework level. If the URL segment isn't a valid `u32`, the router handles the 404. You never touch a raw string in your component.
- **The derive macro generates the link builder.** To navigate programmatically you write `navigator().push(Route::KidHistory { id: 42 })`. No string URLs, no typos at runtime.
- **Both SSR and client routing use the same enum.** The server uses it to decide which component to render; the client uses it for in-browser navigation. One source of truth.

Each variant maps to a component:

```rust
#[component]
fn KidHistory(id: u32) -> Element {
    rsx! {
        div { style: "min-height: 100vh; background-color: #f3f4f6;",
            div { style: "max-width: 520px; margin: 0 auto; padding: 2rem 1rem;",
                KidHistoryPage { kid_id: id }
            }
        }
    }
}
```

The `id` comes in as a properly typed `u32`, extracted from the URL by the router. No `params.get("id").unwrap().parse::<u32>().unwrap()` chains.

# What you get out of it

Running `dx serve` spins up the full SSR + hot-reload dev server. Running `dx build --release --platform web` produces the optimised WASM bundle and `dx build --release --platform server` produces the server binary. Same source, two artefacts, zero duplication.

The practical win for a side project is real: there is no API layer to maintain between a separate frontend and backend. Server functions (Dioxus's RPC mechanism, not shown here) let you call server-side code directly from components, with the serialisation generated automatically. The mental model stays at the component level throughout.

# Wrapping up

The combination of Cargo feature flags and `#[cfg]` gives you a compile-time enforced boundary between server and browser code, while Dioxus provides the runtime glue that makes the same component tree render on both sides. The `#[derive(Routable)]` enum keeps routing type-safe across both environments. It is a genuinely different approach to fullstack web development, and for Rust developers it feels surprisingly natural.

The complete source is at [github.com/paulosuzart/hot_dog](https://github.com/paulosuzart/hot_dog). Have a look — it's small enough to read in an afternoon.
