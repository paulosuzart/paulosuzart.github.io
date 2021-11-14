---
layout: post
title: "OCaml Dream"
date: 2021-11-14 08:22
comments: true
tags: [ocaml]
---

Hey you, welcome! In this blog post we will briefly touch [OCaml](https://ocaml.org/) and one of its Web Frameworks, [Dream](https://aantron.github.io/dream).
The stage is another interview code challenge that I got recently. Yes, again another challenge of that puzzle style that I love _(sarcastic laughs)_.

I just wanted to find a good reason to give a try to Dream that is not a pure `hello world`. Let's give it a go.

<!--more-->

# OCaml

I believe the first time I heard about OCaml, it came from [Jonas Bonér](http://jonasboner.com/) in some tweet or post somewhere. It's been a while and I don't fully recall it. At the time, possibily more than 12 years ago, I entered the language website and was in awe. Things were so different, I was just learning [Scala](https://www.scala-lang.org/) and a bit of [Clojure](https://clojure.org/) and in my mind, FP was just some funny way to play with lists.

I left that alien language behind until I met it again when I was working with Xen Server and realised it was mostly - or totally - [written in OCaml](http://cufp.org/archive/2008/slides/MadhavapeddyAnil.pdf). My interest fired up again for that language. But I soon started to question:

1. Why only [Jane Street](https://www.janestreet.com/technology/)?
1. How do this people persist data? To a normal database, I can't find a lot of database drivers out there.
1. What about service http? Do they use Kafka, AMQP, ZMQ? And what about Amazon S3, Google Cloud, Big Query, monitoring with datadog or distributed tracing?
1. Do they use [IoC](https://www.baeldung.com/inversion-control-and-dependency-injection-in-spring)? 
1. How do they test?
1. How do they deal with concurrency and multi core?

The quetions are just a lot and considering OCaml not that mainstream, they are super easy to find. And to this date, I'm not really sure about most of the answers.

While I still try to find the answers, I can already share a couple of nice things:

1. [ReasonML](https://reasonml.github.io/) brought a boost to OCaml. A lot of big names on it.
1. [Esy](https://esy.sh/) a package manager a la `npm`, for Reason and Ocaml. Makes setup very easy.
1. [Haxe](https://haxe.org/) is written in OCaml!
1. Yes, [Jane Stree](https://blog.janestreet.com/) uses it and this is a strong case for sure.

The language is type safe while having a light syntax that makes things very easy to reason about while keeping certain bugs out and maintenability high.

"Enough talking. Show me the code", you say.

# Dream

I found [Dream](https://aantron.github.io/dream). A name that rasonates with me and my career. Although I'm very excited with what I do and have been doing. There was a niche, an area of work that I ultimately will try to move to. The area where I can work with OCaml, [Racket](https://racket-lang.org/) and alike. I know someday I will get there. In the mean time I work with services written in http, and Dream is a super cool, succint powerful lib.

The simple tool we are tring to build is super simple you call `http://localhost:8080/find_repeated?word=Banana` and it returns a dummy html saying `Found a`. Indicating it found the first repeating char of the word you provided. 

Let's go straight to the code:

```ocaml
module CharSet = Set.Make(Char)

(* Adds a char to the Set and returns the new instance and a 
bool indicating if the insertion suceeded *)
let add achar target =
    let added = CharSet.add achar target in
    added <> target, added

(* Finds the first repeated character in a word *)
let solve word =
  let rec solve' word' set = match word'() with
    Seq.Cons (c, xs) -> 
        (match add c set with
          (true, s)  -> solve' xs s
          | _ -> Some c)
  | _ -> None in
  solve' (String.to_seq word) CharSet.empty;;

let res w = match solve w with
  Some c -> Printf.sprintf "Found %c" c
| None -> "No repetition found"

let () = 
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/find_repeated" (fun req -> match Dream.query "word" req with 
                  | None -> Dream.empty `Bad_Request
                  | Some word -> Dream.html (res word))
  ]
  @@ Dream.not_found
  ```

The parts you see `Dream` is literally setting up a http server that logs your requests and routes the `GET /find_repeated` to a function called `res`, which returns a simple string to be used as html indicating the result of the processing.

The actualy algo is delegated to `solve` that takes the word as arg, turns it into a sequence and provices a `Set` to a inner function called `solve'`. Quite a idiom in OCaml. You see `solve'` being a recursive function because `Set`s in OCaml are immutable, thus every time you add something you get a new instance out of it. This is simlar to [loop/recur](https://clojuredocs.org/clojure.core/loop) in clojure.

The logic is pretty stupid. Tries to add a character to a set, if it succeeds, it's because the char wasn't there before. If it fails, this means the char was already there and the whole processing is stopped. The `add` is kind of wrapping the native `Set.add` to return a tuple indicating if the set before and after are different. And they will be if the insertion succeeds.

You can see some pattern mathing in the char sequence and in the result of `add` that is a tuple like `(true, s)` where true matches the success insertion and `s` binds to the new set generated after adding the element.

Dream also comes with a lot of features including [Websocket](https://aantron.github.io/dream/#websockets), [SQL](https://aantron.github.io/dream/#sql) with [Caqti](https://github.com/paurkedal/ocaml-caqti/#readme), [middlewares](https://aantron.github.io/dream/#middleware) and more.

## An improvement

There's a caviat here. See the `added <> target, added;;` line? This comparison actually makes the Set to walk across the elements to check equality. We only have 25 letters in the English alphabet, but suppose you change the solution to take case into account, or take words in a text instead of letters in a word. This could easily harm things and Ocaml offers another API that not changes elements in place but also offers a handy `Hashtbl.length` to check the size of the table before and after adding an element. 

As we are fancy and have time, let's actually change our code to make it work with both solutions:

```ocaml
module CharSet = Set.Make(Char)

(* Adds a char to the Set and returns the new instance and a 
bool indicating if the insertion suceeded *)
let add achar target =
    let added = CharSet.add achar target in
    target <> added, added

let add_ht c ht = 
  let lbefore = Hashtbl.length ht in
  Hashtbl.replace ht c c;
  lbefore < Hashtbl.length ht, ht

let rec solve' word' container add_fn = match word'() with
    Seq.Cons (c, xs) -> 
        (match add_fn c container with
          (true, s)  -> solve' xs s add_fn
          | _ -> Some c)
  | _ -> None

(* Finds the first repeated character in a word usingn a set *)
let solve word =
  Dream.info (fun log -> log "Solving [%s] using set" word);
  solve' (String.to_seq word) CharSet.empty add

(* Finds the first repeated character in a word using a hash table *)
let solve_ht word =
  Dream.info (fun log -> log "Solving [%s] using hash table" word);
  let size = String.length word and seq = String.to_seq word in
  solve' seq (Hashtbl.create size) add_ht

(* Finds the repetition using Set or Hashtable *)
let res w s = 
  let res' = match s with
      Some "set" -> solve w
    | _ -> solve_ht w in
  match res' with
    Some c -> Printf.sprintf "Found %c" c
  | None -> "No repetition found"

let () = 
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/find_repeated" (fun req -> match Dream.query "word" req with 
                  | None -> Dream.empty `Bad_Request
                  | Some word -> Dream.html (res word (Dream.query "s" req)))
  ]
  @@ Dream.not_found
```

The code is mostly the same, except that the server now takes an optional parameter called `s` and if its value is `set`, the program will use a set to solve the puzzle, otherwise it uses a hash table. This code also makes use of `Dream.info` to log what is going on.

The main difference is that `solve'` became a high-order function that takes a generic container to operation upon and an arbitray add function. so the logic remains the same regardless of the underlying container it is using. There are certainly more idiomatic ways to encode the container and its add operation using types or classes, etc. But this was enough for now. The fun is there!

# Conclusion

The code use here you find in a [gist](https://gist.github.com/paulosuzart/4547930ad007ce911741816fb510b8e1).

OCaml is a language that I find beautiful and mapping to my recent work in the area of payments where you have complex business logic and interactions among
may different concepts/entities. Having the elegance of OCaml has the potential to make things clearer and more maintenable. I will certainly give it a go in real life if I have a chance to.

And here I go, chasing my dreams!

