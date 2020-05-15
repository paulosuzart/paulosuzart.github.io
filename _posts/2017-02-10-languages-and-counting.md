---
layout: post
title: "15 languages and counting"
date: 2017-02-10 10:22
comments: true
categories: [programming]
---


Hello there, happy new year! In this post I’ll talk about the programming languages I got involved in somehow (either for serious playing or serious business).

Yes there are 15. I started my passion for programming languages almost 10 years ago with Scala. At that time I had been working with Java for 4 years. To be fair, the only existing language in my mind was Java. Then Scala came into play.

I’ll present them to you here in a loose chronological order: 

<!--more-->

**2. Scala**

I quickly started writing about [Scala](https://www.scala-lang.org/). Even had 18 blog posts on it in [my old blog (portuguese only)](https://codemountain.wordpress.com/category/scala/). And prepared a presentation available on [slide share](http://fr.slideshare.net/paulosuzart/scala-uma-breve-breve-mesmo-introduo). That was an amazing exciting time, I'd just escaped from the Java island I was trapped in. I could see the world.

I had the chance to put Scala in production using [Play Framework](https://www.playframework.com) 2.4 + [Slick](http://slick.lightbend.com/) from mapping a Postgres database. It still running by the time of writing. 

Why don’t I pursue or stimulate Scala use anymore? There are hundreds of post on the internet explaining why Scala failed, so I don’t need to add any extra content to them. I’m pretty convinced, for example, that, if Play Framework hadn’t been ported to Scala, it would be TODAY competing with frameworks like Django and Rails. I’m not here to try to predict anything, I’ve just got real insights from real usage of it and, I’m okay with it if you want go for it, I’m just out.

I've also technically reviewd a [Book on Scala and Lift Web](https://www.packtpub.com/application-development/lift-application-development-cookbook) (that is also pretty much dead BTW).

**3. Clojure**

This very blog has lot's of [Clojure](https://clojure.org/) posts. I felt in love with clojure in 2009, right after learning Scala. I'ts possible to see some [git repos on clojure](github.com/paulosuzart) in my github account. I enjoyed it so so much, I can still remember that times. Very good sensation.

I couldn't really put any Clojure into production. Actually my colleagues said I was sort of freaky to be able to program in such a thing (I know that is nothing special about it, bit lisp like langs are not so common in Brazil). So, impossible to find someone interested in Clojure, not to mention a experienced Clojure developer to hire.

I like as a language, but Java interoperability where sort of ugly. Furthermore, there were absolutely no killing app for Clojure. I was a member of the Clojure mailing list and *ALL* there I saw were posts prefixed with _[ANN]_ to announce some tiny poorly tested, poorly documented, non maintained wannabe library. I got tire of this, to be fair. And started to code/play less and less with Clojure.

We had some guys creating a Pedestal framework with lots of craziness, well, useless. I heard they dropped good part of what they were doing to provide just the http framework these days.

I also technically reviewd a [Book on Clojure for Domain-specific Languages](https://www.amazon.com/Clojure-Domain-specific-Languages-Ryan-Kelker/dp/1782166505).

Today the only thing I can tell is [Immutant](http://immutant.org/) and [Datomic](http://www.datomic.com/).

There are some dynamic language consequences for using Clojure, you can find on the internet.

**4. Racket**

Then Oracle buys Sun, and I thought I had to be prepared for a total dismantling of JVM ecosystem, and started looking for a lisp lang outside JVM and found [Racket](https://racket-lang.org/). At this point I had read [Land of Lisp](http://landoflisp.com/) and was supper excited about it. I also couldn't put anything to production using Racket, but played seriouslly with it [using threads and sockets](https://gist.github.com/paulosuzart/4c730a14ff9b3fff6fac) in a coding challenge for fun at work.

**5. Go Lang** - option #3

This is my first project using Go, a [distributed load testing](https://github.com/paulosuzart/gb) tool similar to Apache benchmark. Man, how I liked Go lang. I still like it and play from time to time. It's amazing how fast its ecosystem grew up. Of course having a huge company behind it helps a lot.

For me, one of the master pieces written in Go is [BoltDB](https://github.com/boltdb/bolt), check it out.

Go is my third language of choice today, although I don't have any of it in production. The only drawback, or sort of "limitation" is its typesystem, what makes it perfect for semi-low level programming, but it would bite you for writing complex Object hierarchies.

This is my option number 3 after python and Node.

**6. Groovy**

I wasn't brought to Groovy for my passion for programming languages, instead because of a real job. As a CTO at Guiato, we had several systems in Groovy and even put a [Vertx.io](http://vertx.io/) cluster to production using pure Groovy verticles. It's been 5 years since I first touched Groovy in a Grails app.

I like it, in fact it's been showing a steady growth as the best dynamic lang on top of JVM. The only thing I don't like in the Grails ecosystem is: Grails! :D

**7. Rust**

Unfortunately I left few tracks behind (intentionally erased) from my contact with Rust. I've helped a memcached client adding a hash ring to it, so it was able to support multiple servers. Also started creating a process manager ala supervisord.

People tried to put their political preferences over technical skills, what makes it's community dangerous. I also had a blog on rust giving lots of cool deep tips in the language.

Leaving rust was good, although backed by a big company, the forced mentality of embedding memory management into the type system can bring crazy syntax and almost impossible understanding.

The only track I have is [this repo](https://github.com/paulosuzart/currency_watcher), I guess.

**8. Kotlin**

[Kurst-pm](https://github.com/paulosuzart/krust-pm) was my single shot with Kotlin using the - _never 1.0 reaching_ - lib [Quasar](http://docs.paralleluniverse.co/quasar/). It's a cool language, but if I had to use it, I would just go for Java 8 and we are fine. This sounds like a needless language a good (high sized company) created just to stay in the game of companies backing languages.

Kotlin has been showing nice support for Android development, though.

**9. Python** - option #1

I always wanted to code in [Python](https://www.python.org/), it is a such a cool and stable language! Now I have at least two systems (Django) in production deployed to Heroku (besides a lots of utility scripts). I truly like the language and it is my primary option for any new project especially the kind of project you have in venture buildings: low precision of scope and intense prototyping. Not that python is a prototype language, instead its mature and modern ecosystem allows you to drastically change requirements with less effort.

For me the master pieces of python are Django, and any data science related tool (including ML and computer vision).

These days people like to attack python saying nobody adopts python 3. Well, this takes time and is a normal thing to happen. The language and ecosystem are solid and will rock on for a long time yet.

**10. Perl**

I had the chance to create a (not deployed to prod) monitoring system. You can read more details here in this blog post: [Ultrafast web development with Perl + Bootstrap + MongoDB](http://paulosuzart.github.io/blog/2013/09/20/ultrafast-web-development-with-perl-plus-bootstrap-plus-mongodb/). In fact it's fast to prototype and develop using Perl. But I don't know, just didn't want to follow on with the language, specially for its craz support for OO and a crazy new Perl version.

**11. Haskell**

I've read few awesome books like [Learn You a Haskell](http://learnyouahaskell.com). Take some time to read it and expand your knowledge on functional programming, it totally pays of. I have a post on Haskell in this very blog, you can read it [here](http://paulosuzart.github.io/blog/2015/08/21/how-much-functional-are-you/).

Although I like the language, there is a exaggeration towards FP purity that makes applying the language on average professionals team, a impossible task. I keep Haskell around just for playing and studying Type Classes, for example.

**12. Java Script ES6 / Node JS** - option #2

Well, if you ever created a web app, you've coded in js. But with the expansion of the language to the back end was really cool thing. Right now I'm working for a company where good part of back end services we write in Node.JS, and even front end with ReactJs.
Node has proven to be a rock solid platform for modern app. You start quickly and just move on. 

There is the dynamic language challenges involved, but it is part of the game. There are huge improvements in the ES6 version, though.

It's master pieces are the V8 itself, and some testing libs that I love like [Chai](http://paulosuzart.github.io/blog/2015/08/21/how-much-functional-are-you/).

This is my option number two, after python.


**13. Elixir**

This is a pretty cool language. I've studied it a lot and made a very simple service using Phoenix. You can find the code in this [repo](https://github.com/paulosuzart/versicle).

Although I like it, deploying it to production requires a new range of knowledge (specially Erlang production knowledge) that make its adoption more or less fast. It also needs to prove its value. It's a relative new language.

People need to understand they need to get real reasons to use a language and not write articles giving reasons that you can easily reduce to: "you it just because I think it is cool". Dynamic languages comes with a price, one of then is how lazy a developer can become, not to mention the maintenance and evolution of such systems. I'll personally wait a bit more before try to move anything written in Elixir to production.

They - the language creators - are doing a great job.

**14. D**

_What a hell?_ Yes, [D language](https://dlang.org/) has been arond the corner for more than a decade. But the ingredient I think it has, and makes it so invisible these days is the same Clojure, Scala, Elixir and many others have: lack of a big company backing it.

Not that a Big Company is the guarantee of success (see Dart), but it will for sure help create a good ecosystem. 

I've just written a GraphQL interpreter in D _(likely to be open to the community by my company)_. Although I liked the language and wanted to keep it in my tool belt the lack of libs, ide support, etc, makes it very difficult to create large systems. We, for example, stopped when we reached 8k lines of code, and as we approached more and more the features we were crafting, we saw how hard it was becoming to advance.

There are a strange thing in the language related to reflection. `.classinfo` for objects instantiated via interface returns something, and when invoked in a object from a class, returns pretty inconsistent ilogic results.

The [template mixins](https://dlang.org/spec/template-mixin.html) of the language makes you save your finger typing. It's brilliant! But hard to debug as you may end up concatenating strings to create a program that writes program in compile time.

**15. C++** - #option 4

I'm new to CPP, actually. But it's been awhile since I felt so productive. I'm working on a project where part of it is written in Node, and a very code part is written in C++ using [Poco](https://pocoproject.org/).

Why? Well, the world is written in C/C++. No matter how cool your language is, no matter how in the hype you are, your shit will always be run on top of it!

C++ 14 and 17 are here to stay and to tell you can be cool, safe and powerful after 30 years. The new languages on the block gave C++ very good chance to observe what worked, what failed and now this definitely part of my toolbelt.

Please take a look at this amazing IDE for C++, [CLion](https://www.jetbrains.com/clion/) by Jet Brains. It you make you cry of awe. Ant it uses [CMake](https://cmake.org/) as its build sytem. 

Conclusion
---

There are other languages that I've played seriously like [OCaml](http://www.ocaml.org/), and some I don't remember now. 

You might be asking why this list started with **2**, this is because the number **1** is Java, my first language.

Well, you don't need to be able to write code in so many different languages to pay your bills. You are good to go with two or 3 of them, and will be a good professional. But, learning more languages helps opening your mind to new ways of thinking and new ways of finding solutions, indeed.

In my next years I'll increase and strengthen my relation with Python, Go and C++ as my primary languages. So, let's take a break of new ones. It's been almost 10 years of hard learning new languages with enough depth to join full time projects on them.



