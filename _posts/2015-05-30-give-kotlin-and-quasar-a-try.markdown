---
layout: post
title: "Give Kotlin And Quasar a Try"
date: 2015-05-30 10:31
comments: true
categories: [kotlin]
---

Hello hello! After a quick incursion into the world of <s>Rust</s> language, I'm back!

The balance since last year when I started to work on a [tracking system written](http://paulosuzart.github.io/blog/2014/07/07/going-back-to-go/) in Go is: I didn't finish it (as if it is novelty). Also,  I had the opportunity to deliver a [danjgo](https://www.djangoproject.com/) system to production with easy. I might return with the tracking stuff but not written in Go.

Kotlin
---

Ok, so I'm here to give my 2 cents on a Language that I - have to admit - ignored for a long time. A language that was launched ~5 years ago, when [Scala](http://www.scala-lang.org/) was taking over: [Kotlin](kotlinlang.org). You can find better details about why Kotlin in [their blog](http://blog.jetbrains.com/).

To be precise, yesterday they [launched the M12](http://blog.jetbrains.com/kotlin/2015/05/kotlin-m12-is-out/) with relevant changes. The good thing is that those guys are not afraid of improving the language and deprecate things for good reasons.

Kotlin can compile to JVM, JavaScript and Android. What makes it a powerful language able to cover almost all areas you are deliverying code. Not only that, here a non-exhaustive list of characteristics that attracted me:

   - **Serious crafters**. These guys are building a **language**, different from other groups that are creating a language as a masquerade just to embed a bunch of social experiments and social ideas behind them
   - **Incredible interop with Java** without bizzarre workarounds. That is why Kotlin can take advantage of all Java libs without having to reinvent the wheel using the language.
   - **Statically** typed, compiled. I've been working with Groovy (Grails) for at least 3 years. You can say *"you can write tests to give you some safety"*, ok, I respect, but I had to pay the price of dynamicity in production. What is not cheap.
   - **Null is welcome, but without NPE**. Some languages wind their optinal values in a object (`Option`, `Some`, `Either`, etc). Kotlin uses the concept of [Null Safety](http://kotlinlang.org/docs/reference/null-safety.html) where you give a hint to inform if a value can be null, so the compile prevents accidental code without forcing you to write defensive code
   - **Lambdas** - Needless to comment
   - [**Inlining**](http://kotlinlang.org/docs/reference/inline-functions.html) - This is a super important direction to go. Hope that with Java 9, we developers become more responsible and active int terms of how compiler treats our code
   - **Data Classes** - Imagine a very concise and short way to code a class that just holds values, but providing `equals`, `hashcode`, `toString` and `copy` automatically. [Data classes](http://kotlinlang.org/docs/reference/data-classes.html) are the answer
   - **Native delegation** - I can't count how many times I had to use a delegate but doing everything by hand. Kotlin supports this pattern directly, [take a look here](http://kotlinlang.org/docs/reference/delegation.html).
   - **[No checked exceptions](http://kotlinlang.org/docs/reference/exceptions.html)** \o/ -The compile never complies if you don't `throw` an exception. 

And how could I feel the language? Simple: writing a project with it. That is why I ported a `systemd` like process monitor from <s>Rust</s> to Kotlin. Krust-pm can be found in this [Github](https://github.com/paulosuzart/krust-pm/tree/master) repo.

Quasar
---

Another excelent piece of software is [Quasar from Parallel Universe](http://www.paralleluniverse.co/quasar/). I played with it using the [Pulsar Clojure](https://github.com/puniverse/pulsar) wrapper a while ago. And nothing better than interop with Java to really stretch Kotlin.

Quasar provides light Fibers and Actors to JVM and the [release 0.7.0](http://blog.paralleluniverse.co/2015/05/29/quasar-pulsar-0-7-0/) also got released yesterday. So, lets check.

If you open krust-pm project you'll see that at least two classes extends from [ProxyServerActor](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/actors/behaviors/ProxyServerActor.html). 

{% highlight kotlin %}
class ProcessManager() : ProxyServerActor("krust-pm", true),
                         ProcessManagerTrait {
    //...
}
class ManagedProcess(private val name : String,
                     private val cmd : String,
                     private val maxRetries : Int,
                     private var initScale : Int,
                     private val env : Map<String, String>) :
                     ProxyServerActor(name, true), ManagedProcessTrait {
	//...
}

val actorA = ManagedProcess("good_sleeper",
                              "./src/main/resources/sleeper.py",
                              3,
                              2,
                              mapOf<String,String>()).spawn() as ManagedProcessTrait

val actorB = ProcessManager().spawn() as ProcessManagerTrait

actorB.manage(actorA) // manage actorA is sent as a message to the actorB

{% endhighlight %}

ProxyActor is part of the excellent builtin [Behavior](http://docs.paralleluniverse.co/quasar/) Actors provided. This specific one creates a proxy of your class, that immediately becomes an actor without having to implement `doRun` or create a loop and pattern matching incoming messages. This is super, but might add a neglible overhead.

There are other provided behaviors like `Server`, `EventSource` and the great [FiniteStateMachine](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/actors/behaviors/FiniteStateMachineActor.html) that I want to taste.

So, the next great thing about Galaxy is the [Strand](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/strands/Strand.html) abstraction. Krust-pm, due to the nature o Java system process handling, employs a thread per managed process instance. And to keep a single uniform API around a thread that manages a process or any other fiber that can do anything different, I used the `of` static method from Strand to instantiate directly from a thread.

Quasar also offers the ability to [supervise actors](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/actors/behaviors/Supervisor.html) and take actions accordingly. Another important thing is the custom configuration for [Actor Mailboxes](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/actors/MailboxConfig.html) and configurable [FiberScheduler](http://docs.paralleluniverse.co/quasar/javadoc/co/paralleluniverse/fibers/FiberScheduler.html).

Moreover, if you are interested in distributing Actors across machines, there is a natural integration with [Galaxy](http://docs.paralleluniverse.co/quasar/#enabling-clustering) available.

Conclusion
----

Both Quasar and Kotlin are proving themselves as great tools to keep in mind when developing your next solution. Kotlin because it is statically typed, better than java and still flexible enough to foster elegant, expressive and intuitive code.

And Quasa because it doesn't impose any crazy concept like other Actor libs out there, also, it offers great abstractions and a straight to the point API.





