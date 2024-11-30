---
layout: post
title: "Rust SPA with Sycamore"
date: 2024-11-30 13:00
comments: true
tags: [rust, sycamore, spa]
---

[Rust](https://www.rust-lang.org/) continues to grow substantially in the land of [programming languages](https://www.infoworld.com/article/2514539/rust-leaps-forward-in-language-popularity-index.html).
With a growing community and ecosystem in all areas of software development, including [AI](https://ai2sql.io/grok-ai), there's no corner where you can't apply Rust. And Single Page Applications are no different.

In this post, we will take a look at [Sycamore](https://sycamore.dev/), an amazing reactive UI library (like React) for shipping webassembly to production in Rust.

<!--more-->

## Sycamore

I accidentally stumbled upon [Sycamore](https://sycamore.dev/) while searching for UI frameworks for Rust. I already knew about [Leptos](https://leptos.dev/) and [Dioxus](https://dioxuslabs.com/),
leading names in this front in Rust. Needless to mention [Tauri](https://v2.tauri.app/), another titan that sends shockwaves of versatility across the language and community.

If you want a deeper comparison between Sycamore, Leptos and Dioxus, there's this [great article](https://blog.vedant.dev/leptos-vs-dioxus-vs-sycamore-vs-svelte-part-1-syntax-comparison-c58ed631896c) by
[Vendant Pandey](https://blog.vedant.dev/]. In this article we concentrate on "giving it a try" and how it feels in general.

**Disclaimer:** It's important to take into account the fact that I'm not a frontend engineer. Despite having coded in React in the past, and getting somewhat involved in FE hiring and FE projects.

### Documentation

Sycamore's documenation is pretty neat. In [_Your First App_](https://sycamore.dev/book/introduction/your-first-app) section, you get a good taste of what's coming, but if you want a more complete example, go straight to the `Hello World` of reactive frameworks: the [Todo app](https://sycamore.dev/book/introduction/todo-app) exmaple.

I wish the _JS Interop_ page, _SSR Streaming_ page and the [_Deploy_](https://sycamore.dev/book/cookbook/deploy) were a bit more dense. But in general, the doc is good enough for our purposes.


# Our SPA

To add some context, recently I had the chance to build simplified Durable Execution framework similar to [Inngest](https://inngest.com/). The framwork will execute almost plain [Java](https://docs.oracle.com/en/java/javase/index.html) code to completion even in the event of failures, redeployments, intentional delays, etc.
The framework produces a execution trace (a json) that contains valuable information for introspecting the several instances of durable execution running.

## Data format
The format is more or less like this:

* `name` - The execution name. It can be something like `ApproveExpenses`.
* `durable_execution_id` - A unique identifier for the execution.
* `scheduled_at` - The scheduled time for the durable execution.
* `completed_at` - The actual completion time of the durable execution.
* `steps` - An array of individual steps involved in the durable execution

And here's an example of what each step might look like:

* `durable_step_id` - The unique identifier of each step
* `result` - The arbitrary json that is a result of a given step when completed. (e.g. `{ "ok": false }`).
* `inTaskInfo` - Some runtime specific task information. This is very context specific, just imagine some json with lower level information.
* `outTaskInfo` - Some runtime specific task information.

## "Design"
Our page will then require the user to pase the json, and display the trace. Upon click on each step, a side panel will appear showing the specific step detail.
Each step will be disposed so that the user can visualize the start, completion time as well as a duration.

![frame1](/assets/img/sample/frame1.png)

Amd below we see the sidepanel:

![frame2](/assets/img/sample/frame2.png)

# Components

The project was set up with [tailwindcss](https://tailwindcss.com/). For that I just had to use [Trunk's](https://trunkrs.dev/) native support for tailwind. Trunk is a bundler (maybe not the best description) to ship your rust code as a webassembly application.

The support for tailwind is [described here](https://trunkrs.dev/assets/#tailwind) and requires a single line of code in our `index.html`:

```html
<!-- ... -->
<head>
    <link data-trunk rel="tailwind-css" href="input.css"/>
    <link data-trunk rel="rust" data-wasm-opt="s"/>
</head>
<!-- ... -->
```

The whole code of the SPA is vailable on GitHub [paulosuzart/hello-sycamore](https://github.com/paulosuzart/hello-sycamore), and I would like to explore the approaches I used for handling signals ([`create_sigal`](https://docs.rs/sycamore/latest/sycamore/reactive/fn.create_signal.html), memos ([`create_memo`](https://docs.rs/sycamore/latest/sycamore/reactive/fn.create_memo.html)) and also rending list ([`Keyed`](https://docs.rs/sycamore/latest/sycamore/web/fn.Keyed.html)).

## Input

[!frame3](/assets/img/sample/frame3.png)
The only way to get data into our SPA is by letting the user to paste the trace they can obtain from the running durable framework. We must:

1. Show the input text area
2. Parse the Json
3. Display error, if any. Also closing the error modal
4. Update the application state with the parsed data

```rust
#[component]
pub fn TraceInput() -> View {
    let show_error = create_signal(false);
    let set_show_error = move || show_error.set(true);
    let set_hide_error = move || show_error.set(false);
    let err_msg = create_signal(String::new());
    let err_msg_read = create_memo(move || err_msg.get_clone());
    view! {
        (if show_error.get() {
            view! {TraceInputErrorModal(on_hider_error=set_hide_error,error_msg=err_msg_read)}
        } else {
            view! {TraceInputText(on_error=set_show_error, err_message=err_msg)}
        })
    }
}
```
The `TraceInput` component is responsible for the 4 aspects above. For that, it uses a `signal` to display an error. This signal is passed to `TraceInputErrorModal`.
Notice how `TraceInputErrorModal` also takes a `on_hider_error` propery. This is a function it will use on the close icon of the error modal. By simply setting it to false,
the `vew!` macro will swap between showing the error message or the text input itself.

This same signal (`show_error`) is also used by `TraceInputText` to set the value to `true`.

What I want to highlight is the patter I used: `signal` + toggle on (`set_show_error`) + toggle off (`set_hide_error`). What I liked about this pattern is that the action of toggling the error modal is
transparent to the components involved. Let's see how it feels in the input itself:

```rust
#[component(inline_props)]
fn TraceInputText<F>(on_error: F, err_message: Signal<String>) -> View
where
    F: Fn() + Copy + 'static,
{
    let state = use_context::<State>();
    let payload = create_signal(String::new());
    let parse_json =
        move |_| match serde_json::from_str::<DurableTrace>(payload.get_clone().as_str()) {
            Ok(p) => {
                state.0.set(Some(p));
            }
            Err(e) => {
                console_error!("{}", e);
                on_error();
                err_message.set(e.to_string());
            }
        };
    view! {
        div() {
            h2() { "Durable Trace" }
            p() { "Please paste the durable trace json" }
            div() {
                label() { "Payload" }
                textarea(bind:value=payload, id="payload", name="payload")
            }
            button(on:click=parse_json ) { "Load Trace" }
        }
    }
}
```

Check the bound value to the `textarea`. It's a signal for a payload. When filled, the underlying value will match the value of the input. Then the `button` `on:click` calls our
`parse_json`. Here is where we may call `on_error()` (that setter for our signal passed as property for the input component). It is transparent.

If all is good, the app global state captured by `use_context::<State>()` is set. The `State` is defined as following:

```rust
#[derive(Debug, Clone, Copy)]
struct State(Signal<Option<DurableTrace>>);
```

Finally, let's check the `TraceInputErrorModal`:

```rust
#[component(inline_props)]
fn TraceInputErrorModal<F>(on_hider_error: F, error_msg: ReadSignal<String>) -> View
where
    F: Fn() + Copy + 'static,
{
    view! {
        div() {
            div() {
                div() {
                    button(on:click=move |_| on_hider_error()) {
                            svg() {
                                path(fill-rule="evenodd", d="M4.293", clip-rule="evenodd")
                            }
                        }
                }
                div() {
                    svg() {
                            path(stroke-linecap="round", stroke-linejoin="round")
                    }
                    h3() {
                        "Invalid Json. Please paste a valid durable trace json:"
                    }
                    p(class="text-s") { (error_msg) }
                }
            }
        }
    }
}
```
Here we react to the button click by calling `on_hider_error`. Very much transparent. There is also a `ReadSignal` create by `let err_msg_read = create_memo(move || err_msg.get_clone());`.

## Step List and Details
Steps are the powerhorse of this framework. They basically execute the computations. Besides the main visualization in a list, there's the detail side panel.

The list Uses the Sycamore's `Keyed` function:

```rust
#[component(inline_props)]
pub fn Steps(
    steps: Vec<StepTrace>,
    durable_scheduled_at: DateTime<Utc>,
    durable_completed_at: Option<DateTime<Utc>>,
) -> View {
    // ...
    let step_detail = create_signal(Option::<StepTrace>::None);
    let hide_detail = move || step_detail.set(None);
    view! {
        div() {
            Keyed(list=steps,
            view=move |step| view! {
                    StepItem(max_completion=max_completion,
                        delta_window=delta_window,
                        second_rate=second_rate, step=step,
                        step_detail=step_detail)
            },
            key=|step| step.durable_step_id.clone())
        }
        (match step_detail.get_clone() {
            Some(t) => view! { StepDetail(step_trace=t, h=hide_detail) },
            _ => view! {},
        })
    }
}
```

There are other ways of rendeing a list, but I found this way particularly useful and concise. Even though I don't need to update this list.
The `hide_detail` closure is used like the previous component to hide the sidepanel. But instead of using a flag, it directly cleans (set to `None`), the signal
that controls the visibility of the sidepanel.

## State and Local Store

We saw the use of `use_context` straight from a component in order to interact with the application state without passing it several nested levels of components. The state is provided
at the upper level of the application (before the main components are rendered).

```rust
fn main() {
    sycamore::render(|| {
        let state = State(create_signal(None));
        provide_context(state);
        App()
    })
}
```
The state starts totally empty, though. And to persist the data in the user's browser, some tricky is needed to keep the json in [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage).

```rust
#[component]
fn App() -> View {
    let state = use_context::<State>();
    let local_store = window().local_storage().unwrap().expect("No local storage");

    let saved_trace: Option<DurableTrace> = if let Ok(Some(trace)) = local_store.get_item("trace") {
        match serde_json::from_str::<DurableTrace>(&trace) {
            Ok(trace) => Some(trace),
            _ => None,
        }
    } else {
        Default::default()
    };

    state.0.set(saved_trace);
    create_effect(move || {
        state.0.with(|trace| {
            if let Some(trace) = trace {
                local_store
                    .set_item("trace", &serde_json::to_string(trace).unwrap())
                    .unwrap();
            }
        })
    });
    //...
}
```

The function `create_effect` is used to "follow" all the mentioned effects and create side effects (persist to the local store). The call to `state.0.with` will do the trick
and on each change (when the user successfuly parses a Json), the local store is updated. The `App` component is also responsible for trying to read the `localStore` and restore the application state from it.

# Conclusion
**A note:** Before we wrap up, a quick note. [Zed](http://zed.dev/) and [RustRover](https://www.jetbrains.com/rust/) struggled quite a bit to handle the project, whilst
[VSCode](https://code.visualstudio.com/) worked out of the box all the time. I was surprised to See RusRover having a hard time to deal with the macros, autocompletes, etc.

It was a pleasant experience to play with Sycamore. It is complete enough to create pretty complext applications. It is clearly behind the competition in terms of documentation, echosystem, I don't know how do they plan to chase Dioxus and Leptos. One area that requries some attention is testing, currently a [work in progress](https://sycamore.dev/book/cookbook/testing).

One more point that might not be that positive is the macro used for html elements. It uses a notation like `div(){}` as opposed to [Leptos])(https://github.com/leptos-rs/leptos/blob/d665dd4b89151e5d797df3db5cd2260cbe1e8fae/examples/counter/src/lib.rs#L17) that uses `<div></div>` notation more natural to html and speeding up some work.

Webassembly is also growing beyond the web brower. [Fermyon](https://www.fermyon.com/) is a great great example of serverless backed by web assembly applications. Webassembly portability is in its early days of exploration, I'm sure more will come soon.
