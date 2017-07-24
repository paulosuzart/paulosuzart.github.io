---
layout: post
title: "How Much Functional Are You?"
date: 2015-08-21 00:22
comments: true
categories: [fp, haskell, scala]
---

Whats up? Fine? Well, I don't know exactly why but I ended up reading the [Feature Overview](https://github.com/milessabin/shapeless/wiki/Feature-overview:-shapeless-1.2.4) doc of the great [Shapeless](https://github.com/milessabin/shapeless) [Scala](http://scala-lang.org) lib.

<!--more-->

I think it was when reading more about Scala implicits. Anyway, Shapeless and also [ScalaZ tutorials](http://eed3si9n.com/learning-scalaz/index.html) docs put a huge attention to Scala type system and who to build extensible stuff using implicits and the power of the type system itself.

Red them and you will notices couple concepts frequently very often mentioned like Monads *(no, I'll not write a tutorial on it)*, Functors, Applicative, Type classes, etc. But how many times you went that deep? I personally know "Functional Programmers" that never ever talked or read about such things even sort of evangelizing functional programming.

4 years ago I wrote a [blog post (pt_BR)](https://codemountain.wordpress.com/2011/01/01/5-things-to-a-functional-brain/) stating 5 things to have a functional brain, of course that list was very limited:

  1. Lambda Calculus
  1. Say What, not How
  1. Understand partially applied functions
  1. Immutability is natural
  1. Recursion is not strange

Today, with all my words I add: **Know Haskell**. You may say: I'm learning Clojure or Scala, so why [haskell](http://haskell.org)?

Ok, more precisely read [Learn You a Haskell for Great Good!](http://learnyouahaskell.com/) book. But I mean, read right now (if you haven't)! Scala tried to bring as much haskell as possible to the JVM (call me crazy, but this is what it is), and the aforementioned libs are the stretchers of Scala's type system in order to produce the same power of haskell in the JVM.

Of course I played with that. You'll sell a lot of things stuffed in this <strike>Hacker Rank</strike> [Good Node](http://yuanhsh.iteye.com/blog/2200515) challenge.

This is not a perfect solution, mainly because I tried to put as much learned concepts as possible in the same place. So if you don't read this book and go deeper into certain concepts you'll simply not understand some expressions like `<$>`, `<*>` that lies in the heart of Applicative and Functors.

Conclusion
---
Go beyond composing functions, applying `map` against lists and passing functions around. As haskell is certainly the source of all this, you will learn / understand / see sense in libs like shapeless and scalaz much much faster.

[haskell.org](http://haskell.org) offers a huge amount of resources on functional programming, from more kinda math perspective to more practical guides.

To start, simply `apt-get install haskell-platform` and if you use [Atom.io](https://atom.io/), there are some astonishing packages for haskell that gives you full support for context aware code completion, lint, plus compile errors.

If you code Scala like you code Java, or just don't go beyond basics, you have a Ferrari in your garage, but uses your old 1962 Volks to go out. Think about it.

Here the code:
{% gist f9c1e498c79ee3d7098c %}

*WARNING: I'm definitely not the best haskell programmer out there. Don't use this code as a reference, but as a way to step into what haskell code looks like.*
