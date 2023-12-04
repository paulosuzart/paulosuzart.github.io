---
layout: post
title: "Rust and Shuttle"
date: 2023-11-17 19:00
comments: true
tags: [rust, cloud]
---

[Rust](https://www.rust-lang.org/) is here to stay! After eight years since its first appearance, the language has grown a lot in terms of features, community, and power. according to [this survey](https://www.orientsoftware.com/blog/most-popular-programming-languages/), it is slightly more popular than [Golang](https://go.dev/).

But what can we make of a language if we can't ship it to the cloud? This is where [Shuttle.rs](https://www.shuttle.rs/) shines. It makes deploying rust a breeze. Let's check a simple example using Rust and Shuttle.

<!--more-->

## Rust

There are plenty of resources on the internet explaining Rust as a language. A perfect one is The [Rust Programming Language](https://doc.rust-lang.org/book/title-page.html) book. Check also some recent excellent videos like [this one](https://www.youtube.com/watch?v=usJDUSrcwqI) about "the terrible" Borrow Checker and how to survive it.

As you know, Rust has no garbage collection, which means the developer is the garbage collector assisted by the so-called [Borrow Checker](https://doc.rust-lang.org/1.8.0/book/references-and-borrowing.html). The Borrow Checker ensures the [memory safety](https://www.memorysafety.org/docs/memory-safety/) of your program and helps you consistently handle your variables. But I confess it can get in your way at times. You may do some good juggling to get to the other side, which can be frustrating. But with some community research and help, you will probably make it.

### What I like
I like it because it is fast like no other in the market. And without a [GC](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) there is little waste of resources, CPU cycles, and, ultimately, energy. All leads to [potential cost reduction](https://www.linkedin.com/pulse/saving-orders-magnitudes-memorydollars-rust-vs-java-kai-mindermann/).

I also like it because of its power constructs like [traits](https://doc.rust-lang.org/rust-by-example/trait.html), [enums](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/enums.html) (nop, not that Java enum), [pattern matching](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/patterns.html), etc. All at the speed of light.

The whole ecosystem is pretty mature now. Compared to 2015/16, when I first tried the language and had a lot of fun time, as a web-backend engineer, the support for the web, persistency, and cloud is pretty solid at the moment.

### What can be better

Sometimes, I want to throw my laptop through the window because of lifetime hell, the Borrow Checker, the missing traits, whatever they are. In other words, getting into a productive state in Rust can take time and dedication.

Some notations sometimes end up rambling. The excessive currencies of `::` also bothers me (we can get used to it, I know), but it leads to some ugly code to read. Combine it with generics and lifetime annotations, `unwrap()`, `into`()`, and you have the most horrible piece of code to read.

The module system is just nonsense. There was no need to create such a convoluted module system. But they did.

I've also noticed some polarization in the community and some politicization, which I don't like. But perhaps nothing like the [Scala Community Drama](https://github.com/halyph/mind-flow/issues/62).

If Rust becomes [Oxide](https://github.com/tuqqu/oxide-lang), it would be just perfect.

# Shuttle

I have controversial opinions about many things. They include [React](https://react.dev/), [k8s](https://kubernetes.io/), [AWS](https://aws.amazon.com/), hiring, and others. I prefer not to voice them out. But recently, I let it escape in this [LinkedIn post](https://www.linkedin.com/posts/paulosuzart_the-cloud-aware-activity-7124695977025785856-iMEF?utm_source=share&utm_medium=member_desktop).

I believe 80% of applications out there need only something like [Shuttle](https://www.shuttle.rs/). And 80% of infrastructure out there needs only something like [Kamal](https://kamal-deploy.org/). Nothing else. But the industry insists on some crazy solutions that bring new scores of problems worse than the problems they promise to solve.

I find Shuttle an incredible solution. Because 80% of the time we don't care about some [vault](https://www.vaultproject.io/) stuff mounted in your [Pods](https://kubernetes.io/docs/concepts/workloads/pods/), or if your Dockerfile is correct, or your Helm "yaml-based programming" is working. Or if you correctly mapped your paths and ports, or defined your ingress. And perhaps that sidecar is crashing on start, or the egress is not properly set, and the MTLS, so on and so forth.

Shuttle offers not only a runtime, but also what they call [Resources](https://docs.shuttle.rs/resources/overview). There are some built-in resources like [RDS](https://docs.shuttle.rs/resources/shuttle-aws-rds), [shared datbases](https://docs.shuttle.rs/resources/shuttle-shared-db), [Key-Value store](https://docs.shuttle.rs/resources/shuttle-persist), and they recently added [Turso](https://docs.shuttle.rs/resources/shuttle-turso). Turso + Shuttle is a very good kombo.

You can serve [static files](https://docs.shuttle.rs/resources/shuttle-static-folder), share [secrets](https://docs.shuttle.rs/resources/shuttle-secrets) with your applications, or create your own custom [resources](https://docs.shuttle.rs/resources/custom-resources).

# Show me the code

## The task

We must create a simple web based string comparator that takes two strings and tells if they are similar. For example, `"house"` and `"ho2e"` are considered equal because the `2` denotes two missing characters (`u` and `s`), making both words five char len, and the characters that are present match.

If you call our service like this, you get the answer:

```bash
curl https://similarr.shuttleapp.rs/compare\?a\=house\&b\=ho2e

{
    "a": "house",
    "b": "ho2e",
    "expanded_a": "house",
    "expanded_b": "ho**e",
    "result": true
}
```

The code uses [Axum](https://docs.rs/axum/latest/axum/) a lightweight but powerful framework for the web.

We take the strings `a` and `b`, run our algo, and return the expanded version plus the result `true` or `false`. This expanded version of the strings comes from how I implemented the solution. There might be other ways of solving it that don't require expanding the strings.

## `/compare` endpoint

Let's see the code right away (please read the comments):

```rust
// Our request object. Notice the Validate trait and some custom validation being used.
// We want to make sure our server will not explode by taking arbitrary length strings. And also,
// make sure the number notation in our strings won't cause a huge expansion.
#[derive(Deserialize, Validate, Debug)]
struct ComparisonRequest {
    #[validate(length(max = 50))]
    #[validate(custom(function = "valid_numbers"))]
    a: String,
    #[validate(custom(function = "valid_numbers"))]
    #[validate(length(max = 50))]
    b: String,
}

// Our custom validation allows up to 29 missing characters
fn valid_numbers(s: &String) -> Result<(), ValidationError> {
    let regex = Regex::new(r"([3-9]\d+|\d{3,})").unwrap();
    if regex.is_match(s) {
        Err(ValidationError::new("Strings support expansion up to 29 characters"))
    } else {
        Ok(())
    }
}

#[derive(Debug, Serialize)]
struct ComparisonResponse {
    a: String,
    b: String,
    expanded_a: String,
    expanded_b: String,
    result: bool,
}

// Our endpoint. It just calls our similarr::compare function
async fn compare(request: Valid<Query<ComparisonRequest>>) -> Json<ComparisonResponse> {
    let result = similarr::compare(&request.a, &request.b);
    Json(ComparisonResponse {
        a: request.a.to_string(),
        b: request.b.to_string(),
        expanded_a: result.expanded_a,
        expanded_b: result.expanded_b,
        result: result.result,
    })
}
```

Imagine `compare` function is like a method in your controller (if you come from Java/Spring). And `Query` indicates you want to receive your query string bound to your `ComparisonRequest`. Everything is validated by `Valid` from the `validator` [crate](https://docs.rs/validator/0.16.1/validator/).

I like this lib. It is flexible and complete, allowing us to define our custom validation. In our case, I created a validation to ensure numbers are not bigger than `29`.

I wanted to showcase validation because it's good practice to ensure minimal guarantee in any APIs we build. Our handle function then returns a `Json` of our `ComparisonResponse`. And that's it; the web part is concise.

## The `compare` function

The `compare` function is the only public function in our `similarr` module (double `r` intentional). It reads like this:

```rust
pub struct ComparisonResult {
    pub expanded_a: String,
    pub expanded_b: String,
    pub result: bool,
}

pub fn compare(text_a: &str, text_b: &str) -> ComparisonResult {
    let expanded_a = expand2(text_a);
    let expanded_b = expand2(text_b);

    let result = similarr(&expanded_a, &expanded_b);
    ComparisonResult {
        expanded_a,
        expanded_b,
        result
    }
}
```

The results are wrapped in a struct so we carry back the expanded strings. This is where `hou1e` becomes `hou*e`. Before calling the `similarr` function, it calls `expand2` (don't ask me why I added a `2` at the end, there's no need). Check it out (read comments):

```rust
struct NameSwapper;

impl Replacer for NameSwapper {
    fn replace_append(&mut self, caps: &Captures<'_>, dst: &mut String) {
        let iterations = caps[1].parse::<i32>().unwrap();
        let i = iter::repeat("*")
            .take(iterations as usize);
        dst.extend(i);
    }
}

// will expand the strings by replacing the numbers to n '*'
fn expand2(text: &str) -> String {
    let regex = Regex::new(r"(\d+)+").unwrap();
    regex.replace_all(text, NameSwapper).to_string()
}

// the final comparison function taking expanded strings.
fn similarr(text_a: &str, text_b: &str) -> bool {
    println!("Comparing '{}' with '{}'", text_a, text_b);

    if text_a.len() != text_b.len() {
        return false;
    }

    for a in text_a.chars().zip(text_b.chars()) {
        match a {
            ('*', _) | (_, '*') => (),
            (a, b)  if a != b => return false,
            _ => ()
        }
    }
    true
}
```

Logic is elementary. Expand the string. If `len` does not match, it's not equal. We check each character to see if they match, skipping the `*``on any side.

## Unit test

We can validate our implementation by dropping a test straight into our module `.rs` file:

```rust
// straight into src/similarr.rs
#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_truthy() {
        assert!(compare( "ap2e", "a4").result);
        assert!(!compare("ap2e", "a6").result);

        assert!(compare("casa", "ca1a").result);
        assert!(!compare("casa", "ca1x").result);

        assert!(compare("hypothetical", "h11").result);
        assert!(compare("hypothetically", "h12y").result);

        assert!(compare("1or1o", "co1p1").result);
    }
}
```

By running `cargo test -- --nocapture`, we can see our test cases passing and the output of the execution.


## Integration test

Let's test our server now using [`axum_test`](https://docs.rs/axum-test/latest/axum_test/) `TestServer`. We expect that sending `casa` and `ca1a`, our `result` is `true`. For this purpose, we can use the convenient `response.assert_json`. **IMPORTANT** In order to do so, we need to update our response struct to get `#[derive(Debug, Serialize, Deserialize, PartialEq)]` derived traits.

```rust
#[cfg(test)]
mod test {
    use axum_test::{TestServer, TestServerConfig};
    use super::*;

    #[tokio::test]
    async fn black_box_truthy() {
        let app = init_router();
        let config = TestServerConfig::builder()
            .default_content_type("application/json")
            .build();
        let server = TestServer::new_with_config(app, config).unwrap();

        let response = server.get("/compare")
            .add_query_param("a", "casa")
            .add_query_param("b", "ca1a").await;

        response.assert_json(&ComparisonResponse {
            a: "casa".to_string(),
            b: "ca1a".to_string(),
            expanded_a: "casa".to_string(),
            expanded_b: "ca*a".to_string(),
            result: true,
        });
    }
}
```

## Deploy

To tie everything together, we use Shuttle annotation in our `main` function like this:

```rust
fn init_router() -> Router {
    Router::new().route("/compare", get(compare))
        .fallback(handler_404)
}

// Here we go
#[shuttle_runtime::main]
async fn main() -> shuttle_axum::ShuttleAxum {
    Ok(init_router().into())
}
```

Let's save time here and refer to the original documentation at [Shuttle.rs](https://docs.shuttle.rs/getting-started/quick-start).

- `cargo shuttle run ` - Runs your project locally
- `cargo shuttle deploy --allow-dirty` - Deploys to Shuttle. Use `--allow-dirty` if you are doing from uncommitted changes on your repo.

You don't need to use `curl`. Access [https://similarr.shuttleapp.rs/compare?a=hypothetically&b=h12y](https://similarr.shuttleapp.rs/compare?a=hypothetically&b=h12y), and you should see the result (replace `similarr.shuttleapp.rs` by your domain).

# Conclusion

For the complete code, please check my git repo [similarr](https://github.com/paulosuzart/similarr).

After years away from Rust, it was fun to get back. The language is much more mature but also much more extensive. As opposed to other languages that are minimal, like [Clojure](https://clojure.org/) or even [V](https://vlang.io/), Rust has become something that requires some dedicated energy. But it is worth it.

Rust has the potential to take the lead in system programming, mobile, gaming, web, cloud-native, [blockchain](https://cosmwasm.com/), [edge](https://blog.cloudflare.com/workers-rust-sdk/), [embedded](https://github.com/rust-embedded), and even [front-end](https://leptos.dev/), . There's no area where Rust cannot shine.

The Shuttle.rs is in the early days. They can learn a lot with the [Nitric](https://nitric.io/) folks and offer more resources. At the same time, it's a company, a group of people with a vision that takes time to build and takes money, resources, and dedication. Some will say "it's vendor lock-in," and others will love it. But if people think twice, a massive amount of their applications have validity; that is to say, they are MVPs, small iterations, small services with few tables, or their product will just not live long enough. They can save a ton of time and money by using Shuttle.rs.

I'm excited to see where this combo will take the industry!