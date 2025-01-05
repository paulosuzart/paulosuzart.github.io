---
layout: post
title: "Trying Zig's Http Client and Json Parser"
date: 2025-01-05 11:33
comments: true
tags: [zig, rust]
---

[Zig](https://ziglang.org/) has been peaking in hype for a while now. At least two big projects are built in Zig: [Tiger Beetle](https://tigerbeetle.com/) and [Bun](https://bun.sh/), and some big names keep talking about it, like [ThePrimeTime](https://www.youtube.com/@ThePrimeTimeagen) and Turso [here](https://turso.tech/blog/why-i-am-not-yet-ready-to-switch-to-zig-from-rust), [here](https://turso.tech/blog/zig-helped-us-move-data-to-the-edge-here-are-our-impressions-67d3a9c45af4) and [here](https://turso.tech/blog/zig-helped-us-move-data-to-the-edge-here-are-our-impressions-67d3a9c45af4).

But how does it feel?

In this post, we will try it and try to get a sense of the language and its features.

<!-- more -->

# First, what happened to my Rust adventures?

I've completed the whole [Advent of Rust at Rustfinity](https://www.rustfinity.com/advent-of-rust) and all [Practices](https://www.rustfinity.com/practice/rust/challenges) they offer. These are language-focused content, as opposed to algorithm-related stuff. And, contrary to what people say, I had zero fights with the borrower checker all this time—not because I'm a [Rust](https://www.rust-lang.org/) ninja, but because I managed to get into the phase where you learn to do things the "Rust way."

I'm actively promoting Rust and sharing articles ([mine](https://paulosuzart.github.io/blog/2024/11/30/rust-spa-with-sycamore/) and others), tooling, and more at work. Even though I know we will never get any Rust to production.

It was essential to get this contact with Rust (for the second time; my first interaction dates back to 2015, as you can see [here](https://crates.io/crates/rust-pm/)) because it allowed me to have a baseline of programming low lever with guardrails versus programming low level without many guardrails in Zig.

# The language

Zig has excellent learning content, including non-official material like [openmymind](https://www.openmymind.net/learning_zig/). The [Zig Guide](https://zig.guide/) and the [lang ref](https://ziglang.org/documentation/master/) are extremely good. I can't add much there. So, I will focus on my first impressions (no specific ordering):

1. There are no strings (what?)
1. No, if you are a DevOps eng hacking a bit here and there to get your work done with Go, you won't easily pick Zig as a replacement.
1. Ultimately, it's a 0.13.0 version language, and you will face 0.13.0 reality.
1. There's a thrill in completely controlling the computer, but there's also the feeling that an almost certain memory leak is around the corner in production.
1. You don't have the memory expressed as types like in Rust. You either read the docs (if they are well written) or read the code to understand what you will own and need to free up.
1. Tiger Beetle and [Turso](https://turso.tech/blog/a-deep-look-into-our-new-massive-multitenant-architecture#rewrite-everything) mention [DST - Deterministic Simulation Testing](https://docs.tigerbeetle.com/about/vopr/). You can't thoroughly test a system like this to discover where leaks will occur, so DST is a good tool to catch them (?).
1. People always talk about [comptime](https://ziglang.org/documentation/master/#comptime), and it is indeed a cool feature. It replaces generics and runtime reflection simultaneously (if you come from Java like me). It's an underestimated feature.
1. The amount of non-business logic-related stuff developers need to consider may push Zig out of fast-paced product startups. I can't imagine some of the companies I worked with having developers think about a ton of business logic and still take care of the memory plumbings. It will just not happen.
1. Zig can access the Linux Kernel and power infrastructure, such as a new Kubernetes implementation, better API Gateways, a Database, etc.
1. One-liners in Rust are a dozen lines or more in Zig because there are no decent "collections" like features. Rust manages to be as low-level yet so abstract (thus, people call it a zero-cost abstraction language).
1. The error handling approach for Zig is one of the best, if not the best.

Take my takes with a grain of salt. I may change my mind as I learn more and see the project develop in all directions.

# Our Example
Ok, as you may know, I created a [OCaml](https://ocaml.org/) program called [sterred_ml](https://github.com/paulosuzart/starred_ml). It goes to GitHub and fetches my starred items, spitting out a markdown with all the languages, as you can see in my [awesome repo](https://github.com/paulosuzart/awesome/).

We won't do a full implementation, but just enough to fetch the data, parse the response JSON, and print some stuff. For that we need the structs representing the response

```zig
pub const Owner = struct {
    login: []const u8,
};

pub const Repo = struct {
    name: []const u8,
    owner: Owner,
    description: ?[]const u8,
    topics: [][]u8,
    language: ?[]const u8,
};
```
No `#[derive(Debug, Copy)]` or anything like that, just the structs resembling Go, to some extent.

## Http

And we need something to call the GitHub endpoint. For that, we can create a struct referencing an HTTP Client.
```zig
/// A Starred API client. Taks the bearer token and the http client.
pub fn GithubStarredAPI() type {
    return struct {
        const Self = @This();
        allocator: Allocator,
        uri: std.Uri,
        bearerToken: []const u8,
        client: *Client,

        pub fn init(allocator: Allocator, bearerToken: []const u8, client: *Client) Self {
            return .{
                .bearerToken = bearerToken,
                .client = client,
                .allocator = allocator,
                .uri = Uri.parse(URI) catch unreachable,
            };
        }

        // Parsed result must be managed by the call site.
        pub fn fetchFirstPage(self: *Self) StarredApiError!std.json.Parsed([]lib.Repo) {
		// .. code in a moment
        }
    };
}
```

The struct has a `init`. It's a convention, not an enforced shape.

The allocator is needed because the underlying JSON parser needs one. We must also pre-allocate storage for the HTTP Client to write the response body. The return time of our `fetchFirstPage` is `StarredApiError!std.json.Parsed([]lib.Repo)`.

Let's first see what the `StarredApiError` bit is:

```zig
pub const HttpError = error{
    FetchError,
};

pub const GithubError = error{
    JsonParseError,
    NonOkResponse,
};

pub const StarredApiError = HttpError || GithubError;
```
Zig communicates which errors a function can return via the `!`. The left side of it indicates the error type. In this case, a merge between `HttpError` and `GithubError`. I did this for possible future reuse and to test the feature. We will see now how these errors can be returned (imagine "thrown" in Java world).

```zig
        pub fn fetchFirstPage(self: *Self) StarredApiError!std.json.Parsed([]lib.Repo) {
            var respStorage = std.ArrayList(u8).init(self.allocator);
            defer respStorage.deinit();
            const opts = FetchOptions{
                .location = Location{ .uri = self.uri },
                .method = GET,
                .headers = Headers{ .authorization = .{ .override = self.bearerToken } },
                .response_storage = .{ .dynamic = &respStorage },
            };

            const res = self.client.fetch(opts) catch {
                return StarredApiError.FetchError;
            };

            if (res.status != std.http.Status.ok) {
                std.debug.print("Error general: {s}", .{respStorage.items});
                return StarredApiError.NonOkResponse;
            }

            const parsed = std.json.parseFromSlice([]lib.Repo, self.allocator, respStorage.items, .{
                .ignore_unknown_fields = true,
                .allocate = .alloc_always,
            }) catch {
                return StarredApiError.JsonParseError;
            };
            return parsed;
        }
```
The `respStorage` is the storage that the Client uses to write the response body. This already feels strange, but the implementation decided not to get involved in the storage's lifetime and just writes to it, leaving the call site to decide about the storage's lifetime.

Our call to `self.client.fetch(opts)` finally triggers the HTTP call. Now, pay attention to the `catch` after that call. The `fetch` function can return a range of errors. There are so many different types of errors that the method only uses `!FetchResult` in the return type, and the compiler will infer the possible errors. My `catch` works like a `catch (Throwable e)` in Java. Whatever happens, return now a `StarredApiError.FetchError`, and that's it.

After that, there's a check on the status code and anything other than `200` returns `StarredApiError.NonOkResponse;`.

The client used is created by the `main` function like this:

```zig
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();
```
To call our `GithubStarredAPI`, we just do:

```zig
    var starredApi = GithubStarredAPI().init(allocator, bearer, &client);

    const repos = try starredApi.fetchFirstPage();
    defer repos.deinit();
```

There's a `defer repos.deinit();` and we will know why in the next section.

## JSON

The [`json`](https://ziglang.org/documentation/master/std/#std.json) module is quite nice in terms of features and pretty low-level, as well. It can parse JSON and make as little allocation as possible.

Back to our `fetchFirstPage` method, we get a parsed result back:

```zig
            const parsed = std.json.parseFromSlice([]lib.Repo, self.allocator, respStorage.items, .{
                .ignore_unknown_fields = true,
                .allocate = .alloc_always,
            }) catch {
                return StarredApiError.JsonParseError;
            };
            return parsed;
```

I didn't intend to return a `!std.json.Parsed([]lib.Repo)`, but I spent hours trying to understand why returning `repos.value` would crash the app. I wanted to return only `![]lib.Repo`, but there are at least two issues here:

1. The parser allocates things in an arena allocator and cleans up everything when `deinit` is called. Even setting `.alloc_always` would lead to the same behavior.
2. I could manually copy the parsed data into fresh structs, but that would imply manual allocation and deallocation—a total tragedy in terms of ergonomics for such a minor feature.

This is where Rust shines. Yes, it's type-heavy, but the types are there to tell you what's happening underneath. Based on the function return type, there's no way to know that the JSON parser is doing what it is doing. Zig types express nothing related to memory. Then, you are left with documentation and inspecting code.

Luckily, I found this [post about it](https://www.openmymind.net/Zigs-json-parseFromSlice/), and I accepted my fate of having to return the parsed result and warn in my document that the call site would need to free it.

We can then use our returned JSON to print it:

```zig
    std.debug.print("{} Repos returned\n", .{repos.value.len});

    for (repos.value) |r| {
        std.debug.print("Repo name is {s}/{s} ({s})\n", .{
            r.owner.login,
            r.name,
            r.topics,
        });
    }
```

## Bonus - Array slice manipulation

If you have a rust Vector and want to group by something, you don't only this:

```rust
    let mut language_groups: HashMap<String, Vec<String>> = HashMap::new();
    for person in &people {
        language_groups.entry(person.language.clone()).or_default().push(person.name.clone());
    }
```

There's no memory allocation thinking. And you have your almost on-liner group by of a slice.

But how do we group our repos by language in Zig to get some "dictionary" where the key is the language and the value is a slice of pointers to repositories? Well, we need much more than two lines. And it's not about line numbers, but the number of things the developer needs to keep in mins (this might not be the most idiomatic, but it's a way I found):

```zig
pub fn GroupBy(comptime T: type, keyFn: fn (*T) []const u8) type {
    return struct {
        const Self = @This();
        map: std.StringHashMap([]*T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .map = std.StringHashMap([]*T).init(allocator),
                .allocator = allocator,
            };
        }

        /// Returns a StringHashMap managed by GroupBy. In case elements T can't give a []u8 key.
        pub fn group(self: *Self, items: *const []T) !*std.StringHashMap([]*T) {
            for (items.*) |*item| {
                const key = keyFn(item);
                const gop = try self.map.getOrPut(key);
                if (!gop.found_existing) {
                    // Allocate a slice of one repo pointer for new languages
                    gop.value_ptr.* = try self.allocator.alloc(*T, 1);
                    gop.value_ptr.*[0] = item; // repo is now a pointer
                } else {
                    // Extend the existing slice of repo pointers
                    const current_slice = gop.value_ptr.*;
                    var new_slice = try self.allocator.realloc(current_slice, current_slice.len + 1);
                    new_slice[current_slice.len] = item; // repo is now a pointer
                    gop.value_ptr.* = new_slice;
                }
            }

            return &self.map;
        }

        pub fn deinit(self: *Self) void {
            var iter = self.map.iterator();
            while (iter.next()) |e| {
                self.allocator.free(e.value_ptr.*);
            }
            self.map.deinit();
        }
    };

pub fn getKey(r: *Repo) []const u8 {
    return r.language orelse "Not-Set";
}
```
Wow! If you come from Java and are used to the [Sream API](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/stream/package-summary.html) you will feel the hit.

The logic is the same as the Rust code above. Iterate, get the key value, and check if it's present in the final map; if not, create an array with the value in question; otherwise, add the value to the existing array. But what struck me was the need to `deinit` each pointer of the values in the HasMap.

It makes sense if you understand Zig's "No hidden allocations" philosophy. In the end, we allocated all this space in our `for` loop.

This is how you call the `GroupBy`:

```zig
    var groupBy = GroupBy(Repo, getKey).init(allocator);
    defer groupBy.deinit();

    const repo_slice: []Repo = repos[0..];

    const groupped = try groupBy.group(&repo_slice);
```

For exploration purposes, `GroupBy` takes a `keyFn: fn (*T) []const u8`. This is a function that will get each element of the iteration and then return the `[]u8` key for our HashMap.

The `getKey` function features a `r.language orelse "Not-Set";` where `orelse` is how to deal with the "Option type" denoted by `?`.

Access the full code at [https://github.com/paulosuzart/zigando/](https://github.com/paulosuzart/zigando/).

## Tests

I couldn't find a way to mock things in Zig. If you know how to do it, please share in the comments. The final stage of my tests is that I can't unit-test the `GithubStarredAPI`. I could spin up [Wiremock](https://wiremock.org/) or something similar, but perhaps at a later time.

I managed to test the `GroupBy` like this:

```zig
test "byLanguage works" {
    const allocator = std.testing.allocator;

    var repos = [_]Repo{
        .{
            .name = "repo1",
            .language = "zig",
            .owner = Owner{ .login = "ps" },
            .topics = undefined,
            .description = "sample",
        },
	///...
    };

    var groupBy = GroupBy(Repo, getKey).init(allocator);
    defer groupBy.deinit();

    const repo_slice: []Repo = repos[0..];

    const groupped = try groupBy.group(&repo_slice);

    try std.testing.expectEqual(@as(usize, 2), groupped.count());
}
```

Quite straightforward.

# Conclusion

Yes, after the compilation passed, I spent several hours trying to find the cause for panics at runtime. The test allocator is helpful as long as you have a lot of coverage. Even after the tests passed, I still wasted a ton of time.

This was a second attempt. The first was this [gist right here](https://gist.github.com/paulosuzart/37aaeb8ab1de70e68404259bf928e371) with a more procedural approach and equally ton of time wasted trying to find the panics.

One may face less panic over time, but you still can't be 99% sure if all is fine, like you can when you use regular Rust *(I heard about some headaches on perf-rust and unsafe Rust)*. You need to decide what you wanna fight: a panic in production or Rust's borrow checker at compile time. In the end, you need to worry about lifetime ownership in the same way you do with Rust, but with no assistance at all.

Yet the language feels quite good. I wish the community would create some form of auto-generation of clone, debug, and display. Otherwise, the language will remain in a niche, with several tribal idioms popping up to cope with this kind of challenge.

Some container libraries won't hurt, either. An easier way of transferring ownership, copying, etc., can bring the language closer to the daily programmer creating non-technical products for startups.

Zig found a place in my tool belt. Let's see how it evolves.
