---
layout: post
title: "Why Racket is Awesome"
date: 2014-04-27 19:44
comments: true
categories: [racket]
---

Finally 1st post of the year! Well, not that much to say lately. But here a piece of my sensations while playing with [Racket](http://racket-lang.org/) last two weeks.

How I started looking at it
----

My first visit to Racket was possibly in the old times of version 4. But now with 6.1.1, the thing is such mature work.

Well, after a long time [far from](http://www.reddit.com/r/Clojure/comments/2r63gt/why_did_you_stop_using_clojure/cnkez0i) [Clojure](http://clojure.org/), at work we got some spare that we could use for tiny hackathons (a lot tiny BTW). We define silly scenarios where one could build using anything.

First I'd decided to go with [OCaml](https://ocaml.org/), just to taste it. Sour! I mean, it is a good language but documentation is frustrating, libraries documentation even worse. Ok, so went for [Rust](http://www.rust-lang.org/), that is a good promise and should become one of my languages once it gets out of alpha stage: it is hard to compile libs with nightly builds, everything brakes, etc.

But Rust is being crafter along with solid libraries like [Hyper](http://hyperium.github.io/hyper/hyper/index.html). Man, this is great. But lets wait things mature a bit.

So, now what? Clojure? No. Racket!

If I was a language creator/contributor I would feel ashame with this brilliant documentation since I couldn't produce such quality writings. Period.

Just take a look at (http://docs.racket-lang.org/)(http://docs.racket-lang.org/). See, you just want to start coding with it right now.

What I've found
---

Of course, good languages has more than good documentation. My experiments covered [Input/Output](http://docs.racket-lang.org/reference/input-and-output.html) and [Concurrency and Parallelism](http://docs.racket-lang.org/reference/concurrency.html). And there couldn't exist more concise concepts and API.

Threads are light and also got [Mailboxes](http://docs.racket-lang.org/reference/threads.html#%28part._threadmbox%29), IO got [Events](http://docs.racket-lang.org/reference/port-lib.html#%28part._.Port_.Events%29).

Command args line handling? No lib, just use Racket like in this [small example](https://gist.github.com/paulosuzart/4c730a14ff9b3fff6fac#file-guess-server-rkt-L73).

You also have [raco](http://docs.racket-lang.org/guide/cmdline-tools.html#%28part._compile%29) and [DrRacket](http://docs.racket-lang.org/drracket/index.html) a complete editor that shows you arrows pointing from which module functions come from, also the uses of a function in your code and a [Graphical Debug Interface](http://docs.racket-lang.org/drracket/debugger.html) and much more. This is not a complete overview of this language (I have no nuts to do such thing).

Another good thing is that Racket doesn't need a decision table to make you pick you the right construct for holding data. This is straightforward and pragmatic. Use `structs`, be happy.

When it comes to performance, Java and [Clojure](http://benchmarksgame.alioth.debian.org/u64/compare.php?lang=clojure&lang2=racket) win. I don't really know how much effort Racket guys put on this. And for lots of scnarios it makes no difference.

Have I told you Racket can also produce beatyful desktop apps? Take a look [here](http://docs.racket-lang.org/gui/index.html).

What now?
---

Ok, I'll definitely try to have more Racket in my life. It brought me back the charm of LISP. I read [Land of LISP](http://www.amazon.com/Land-Lisp-Learn-Program-Game/dp/1593272812/ref=sr_1_1?s=books&ie=UTF8&qid=1428021425&sr=1-1&keywords=land+of+lisp) few years ago, now it may be time to read [Realm of Racket](http://www.amazon.com/dp/1593274912/ref=cm_sw_su_dp)

This post is not teaching you anything but shares my findings so far. If you want to see some **code** you can access this [currency-watcher.rkt](https://gist.github.com/paulosuzart/96197abdbf68b078545c) that is silly program to query a currency conversion API and report to HipChat if things change a lot. And the The second [Gist](https://gist.github.com/paulosuzart/4c730a14ff9b3fff6fac) shows a multi thread/serialization/socket playing.

Good Luck!
