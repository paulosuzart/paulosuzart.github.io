---
layout: post
title: "OCaml Improved"
date: 2021-11-16 21:22
comments: true
tags: [ocaml]
---

In the [last post](./2021-11-14-ocaml-dream.md) we spent some time playing with [Dream](https://aantron.github.io/dream) while doing very basic stuff in [OCaml](https://ocaml.org/). We saw how using Sets vs Hashtables could make a difference in performance and worked around it to allow solutins both using [Sets](https://ocaml.org/api/Set.html) and Hashtables. In this post we will see how to atain polymorphic behaviour of OCaml programs by using [Modules](https://ocaml.org/learn/tutorials/modules.html). 

<!--more-->

# Modules

Coming from Java - mostly - the idea of Modules is something alien to some extent. Especially in the [language's page about them](https://ocaml.org/learn/tutorials/modules.html). The explanation revolves more around how module help you organize code, how you open / include them, etc. Then you have [First-Class Modules](https://dev.realworldocaml.org/first-class-modules.html) in Real World OCam that is more or less a punch in the face.

I had to read many times and do some try and error until I manage to get to the state I will share in a second. Alhough I can't fully provie a better explanation about modules, they are certainly very powerful tool of the language and a good bulk of polymorphism and parametrization will flow through them.

There even a second level of complexity with the so-called [Functors](https://dev.realworldocaml.org/functors.html) (no, they are not the Haskell [Functors](https://mmhaskell.com/monads/functors) I throught at first).

I will leave the theory and syntax explanatio for those links above and let's see what I got while improving my program.

# The problem

The core pice of the problem from the previous solution is here:

```ocaml
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
  solve' (String.to_seq word) CharSet.empty add

(* Finds the first repeated character in a word using a hash table *)
let solve_ht word =
  let size = String.length word and seq = String.to_seq word in
  solve' seq (Hashtbl.create size) add_ht
```

Both `solve` and `solve_ht` (functions respectivelly called from the request handler for Set based and Hashtable based solutions) need to provide two extra parameters to the `solve'` function. One is the `container` empty instance (Hashtable or Set) and a function that know how to add elements to the desired containers, provided that the interfaces are different.

The solution works but it's pretty basic, conceptually speaking. It's more of a [clojure](https://clojure.org/) style of doing things. But how would that look like with modules?

# The Solution

Let's start with the `interface`, or he signature of what we are trying to generify:

```ocaml
module type CHAR_CONTAINER =
  sig
    type container
    val contains : container -> char -> bool
    val add : container -> char -> container
    val empty : unit -> container
  end
```

To comply with the solution we needed a way to get a `empty` container, whatever it is. We need a way to `add` elements to it. And, as you will see with the improved logic using patter matching with guards, we need a way to look up into the container, here represented by `contains`. I know, you Java developer will be thinking: These interfaces are commong in the [Collections framework](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Collection.html), why the heck are you creating an interface for it? Well... 

Comparisons apart, here is what we call `CHAR_CONTAINER`. Something that has the provided signature so our solution function can rely on it instead of forwarded arbitrary functions. How would a conformant implementation for Sets look like? Here we have it:

```ocaml
module SetContainer = 
  struct
    module CharSet = Set.Make(Char)
    type container = CharSet.t

    let contains con c = CharSet.find_opt c con |> Option.is_some
    let add con c = CharSet.add c con
    let empty () = CharSet.empty
  end
```

Beautiful, huh? A way to understand the `type container` like `MyClass<Set>`, where you parametrize your class with some generics. Here we are saying that the `container` type for this module is actually a `Set` of `Char`.

The implementation for contains wraps the `find_opt` that looks up and return an optional. I'm just converting it to a `bool`. And then `add` and `empty` follows pretty basic.

Hashtable version is quite similar. Take a look:

```ocaml
module HashTblContainer = 
  struct
    type container = (char, char) Hashtbl.t
  
    let contains con c = Hashtbl.find_opt con c |> Option.is_some
    let add con c = Hashtbl.replace con c c; con
    let empty () = Hashtbl.create 10
  end
```

The `container` is obviously different. But the rest of the implementation is quite similar. I used a `create 10` as an arbitrary size. We can change `empty` to take an extra contex but I intentionally want to live the signatures like this so in a next post we can talk about [Monoids](https://typelevel.org/cats/typeclasses/monoid.html).

Before we see how we pass the modules to our `solve` function, let's quickly revisit how the new solution look like:

```ocaml
let solve word (module M : CHAR_CONTAINER) =
  let rec solve' con word' = match word'() with
      Seq.Cons (c, _) when M.contains con c -> Some c
    | Seq.Cons (c, xs) -> solve' (M.add con c) xs
    | Nil -> None in
  let empty = M.empty () and word_seq = String.to_seq word in
  solve' empty word_seq
```

Much shorter and elegant. The problem it tries to solve is, given a sequence of chars, detect the first repeated letter. The logic now takes a module that conforms with `CHAR_CONTAINER` and the `word` itself. Then starts the `solve'` that will match the `Seq` of `char` and if the first char is contained in the container, it returns right away. Otherwise, the char is added to the container and the function called again. And finally, if the sequence is exhausted (`Nil`) it returns `None`.

The two functions that dispatch to the `solve` functio need to do the heavey lift of summoning the appropriate CHAR_CONTAINER:


```ocaml
let solve_set word =
  let mySet = (module SetContainer : CHAR_CONTAINER) in
  solve word mySet

let solve_ht word =
  let myHtable = (module HashTblContainer : CHAR_CONTAINER) in
  solve word myHtable
```

The are then conditionally called from the request handler. The interface remain the same and if you run the code provided in the post repository, you can access `http://localhost:8080/find_repeated?word=BBana` and get back a beautify `Found B`.

# Conclusion

The first conclusion is something that I always say: the more you understand the problem, the more you improve your solution iteratively. The first version was using a convoluted implementation that is much more expensive, using `length`, etc. It was using also these arbitrary functions and providing different values as containres to the solving function. Turing its signature much worse.

Using `module` it was possible to have an algorithm that would rely a certain interface and the underlying implementation is a mere detail.

This post makes a good case for talking about Libraries like [Cats](https://typelevel.org/cats/) (*I hope I can stay away from the war going on in the community*), [ScalaZ](https://scalaz.github.io/7/) (always terribel documentation) or Type Classe in [Haskell](http://learnyouahaskell.com/types-and-typeclasses). And the most important, how uniformizing the way things interact can bring high degree of reusability and understanding across different domains.






