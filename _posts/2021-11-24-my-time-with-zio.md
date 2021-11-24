---
layout: post
title: "My Time with ZIO"
date: 2021-11-24 11:22
comments: true
tags: [scala]
---

Following my study spree during my vacations, it was time to jump into [ZIO](https://zio.dev/). I have touched the project here and there but never tried to build a sample. After my last visit one year ago, what I found is a much more mature, ecosystem-like suite of capabilities, and I like what I see. Let's walk through a simple example of consuming a Kafka Topic and keeping a background process ([fiber](https://zio.dev/version-1.x/datatypes/fiber/index)) logging a "materialized" version of this topic in memory.

<!--more-->

# ZIO

The first thing to catch your eyes is the [adopters list](https://github.com/zio/zio#adopters) in the project's README. You find big names in that list, including Asana, Bank of America, DHL, TomTom, Zalando, among others. It's a pretty decent list and brings a lot of credibility to the project.

Documentation is [abundant](https://zio.dev/version-1.x/datatypes/index) and folks on [Discord server](https://discord.gg/2ccFBr4) are pretty friendly.

In the Zionomico, John accounts for a previous experience designing and building [Purescript's](https://www.purescript.org/) [Aff](https://github.com/purescript-contrib/purescript-aff) library, among other experiences that helped him learn and mature. Until he came up with what became [Scalaz 8 IO Monad](https://eed3si9n.com/learning-scalaz/IO+Monad.html) and "the seeds of ZIO had been planted, and they grew quickly" (De Goes and Fraser, 2021, pp. 3). John himself delivers the motivations and philosophy behind ZIO in this amazing talk to the [Berlin Functional Programming Group](https://www.youtube.com/watch?v=QDleESXlZJw).

And John is right, and barriers need to be lowered for people coming into FP. Typeclasses are a great tool, but if you turn everything into a Semigroup, Ring, or whatever, you lose your domain knowledge in favor of abstractions with laws with great reuse but with great distance from your business domain.

# The sample

Enough talking. I want to share a sample that I created. The goal is:
1. listen to a Kafka topic
2. accumulate all its entries on a global map
3. have a background process that keeps logging the current map value

Imagine we are trying to build a system that relies on a local state store, like in Kafka Streams. But much more superficial, no rebalance-handling or chaining into the stream pipeline, just a global map that keeps a `k,v` structure globally available.

Let's start from the beginning:

```scala
object Solver extends zio.App:

  // Run it like any simple app
  override def run(args: List[String]): ZIO[zio.ZEnv, Nothing, ExitCode] =
    var l1: ULayer[TaskQueue] = (Console.live ++ TaskQueue.storeLayer) >>> TaskQueue.live
    val env =
      TaskQueue.consumer ++ l1 ++ TaskQueue.storeLayer
    TaskQueue.app.provideCustomLayer(env).exitCode
```

Things will not make a lot of sense at this point. But this is just the main  method being called and the layers thing you can imagine as wiring dependencies
in a framework like Spring or Guice (perhaps Guice like). What is happening here is: Hey ZIO Dependency resolution, there's a service that
takes `CommitttableRecords`, logs, and inserts it into the global map. This service to work needs two other services, a `Console` and this global map. This is basically `l1` here. And finally, we provide this produced service (in the form of a layer) and horizontally compose it (like, put side to side) and provide it to `TaskQueue.app` that requires precisely the Kafka Consumer plus the `TaskQueue` plus the global map. How do we know that?

If we check the signature of our `TaskQueue.app` application (Just a ZIO that takes some environment as input and produce some value), we see:

```scala
    val app: ZIO[Has[Consumer] & TaskQueue & GlobalSet & Console & Clock, Throwable, Unit] = {
      val spaced = Schedule.spaced(5.seconds)
      for {
        fiber <- logger.schedule(spaced).fork
        _     <- run
        _     <- fiber.join
      } yield ()
    }
```

Aha! It's just a ZIO that returns `Unit`. It can also error with `Throwable`. It requires an instance of Kafka Consumer (forget the `Has` for a moment),  another for `TaskQueue`, and a bunch of built-in services provided by ZIO (`Console` and `Clock`). Yes, the dependency part of ZIO is pretty type-heavy. But things will be better in ZIO 2.0 (check [here](https://github.com/kitlangton/zio-magic), for example).

Environment aside, that is our application. Create a fiber that triggers a `logger` effect every 5 seconds. Finally, invokes the `run` effect (the one that consumes the Kafka topic) and joins the created fiber. Nothing more, nothing less to have an application consuming Kafka and doing some other work for us.

Let's take a look at the `run` effect:

```scala
    val run: ZIO[Has[Consumer] & Console & TaskQueue & Clock, Throwable, Unit] = Consumer
      .subscribeAnd(Subscription.topics("leases"))
      .plainStream(Serde.string, Serde.string)
      .tap(cr => putStrLn(s"Record key: ${cr.record.key}, value: ${cr.record.value}"))
      .tap(TaskQueue.handle(_))
      .map(cf => cf.offset)
      .aggregateAsync(Consumer.offsetBatches)
      .mapM(_.commit)
      .runDrain
```

It is possible to omit the types mostly everywhere, but I prefer the more explicit things. Again you see an Effect. It returns `Unit` and has a couple of requirements: the Kafka consumer instance (`Has[Consumer]` the `TaskQueue` instance that knows how to `TaskQueue.handle(_)`) a CommittableRecord and the `Clock` is there because it's a requirement for the offset commit.

The chain is pretty straightforward if you take the type aside: subscribe to a topic, create a [ZStream](https://zio.dev/version-1.x/datatypes/stream/index), tap into it so we log the current value. Tap again to call the handling that knows how to store the entries in the global map, commit the offsets, and that is it.

ZStream deserves a blog post or a book about it. But if you come from Java and have experience with [RxJava](https://github.com/ReactiveX/RxJava) or [Reactor](https://projectreactor.io/) that will ring a lot of bells.

Before we finally see how this `TaskQueue.handle(_)` works, let us check the `logger` that is also mentioned in the `app` Effect:

```scala
    val logger: URIO[GlobalSet & Console, Unit] = for {
      x <- ZIO.access[GlobalSet](_.get)
      _ <- putStrLn(s"Current Set: ${x}").orDie
    } yield ()
```
Logger here is not in the sense of an application logger that would send something via appenders to some logging infrastructure. It is a simple console log. It could have been encapsulated as a Layer as well, but it is a simple Effect being called straight from our `app`. The goal is to `logger.schedule(spaced).fork` so we fork a Fiber that won't block our consumer thread.

## Our Service

Finally, our service. After years of working with Spring, you think about `@Component`, `@Service` or `@Bean` when you talk about service. Simple like that. But things are slightly different, although aiming the same goal: code to interfaces, not instances. *Let some central infrastructure take care of injecting your dependencies.*

Similarly, we create our contract. A `trait`. All it does is take a `CommittableRecord` with the raw data from Kafka, and return nothing. It returns nothing because it will add the value into the global map, so it doesn't need to return anything. You may want to signal back to the caller if something went wrong, so maybe that record offset is not committed, or perhaps use a DLT. But this is a tale for an actual production code someday.

```scala
object TaskQueue {

    trait Service {
      def handle(record: CommittableRecord[String, String]): UIO[Unit]
    }
}
```

And you may have noticed that in our stream chain, we call something like `.tap(TaskQueue.handle(_))`. What? We call `handle` in some companion object, not in some instance of `TaskQueue.Service`? Yes, precisely. If you come from Spring, this corresponds to hiding your bean methods behind some form of wrapper that knows the Spring ApplicationContext, then when you call a method on the wrapper, it gets the bean from the context, and finally invokes the target method.

The goal here is more in terms of ergonomics. And the implementation becomes:


```scala
object TaskQueue {
    // ...
    def handle(record: CommittableRecord[String, String]): URIO[TaskQueue, Unit] =
      ZIO.accessM(_.get.handle(record))
}
```

The ergonomic is how instances are accessed. To avoid `ZIO.accessM` everywhere, let the wrapper access the provided instance for ou and call the `handle` method with the record argument. 

Great, so far, we saw how our `app` looks like, our `logger` looks like, and how we fork a fiber. We saw our service interface and how to call it, but where is the instance of our service then?

```scala
object TaskQueue {
    //...
    val live: URLayer[Console & GlobalSet, TaskQueue] =
      ZLayer.fromServices[Console.Service, Ref[Map[String, Entry]], TaskQueue.Service] {
        (console: Console.Service, globalSet: Ref[Map[String, Entry]]) =>
          new Service {
            override def handle(
                c: CommittableRecord[String, String]
            ): UIO[Unit] = ZIO
              .fromOption(Option(c.value))
              .flatMap(_ => globalSet.update(_ + (c.key -> Entry(c.key, c.value))))
              .orElse(globalSet.update(_.removed(c.key)))
          }
      }
    //...
```
Why `live`? Why an inline instance of `TaskQueue.Service`? What is going on here?

Well, this is the so-called [Module Pattern 1.0](https://zio.dev/version-1.x/datatypes/contextual/index#module-pattern-10). It's just a way of organizing things so people can, by convention, quickly recognize what is going on.

What is going on here is that we create a Layer (remember, a Layer is like a Service without really being a service. Perhaps it's the mapping of a bunch of other services as input, if any, to a bunch of other services as the output). This layer uses an especial `ZLayer.fromServices` that get the instances of our dependent services, the `Console` and our Global Map held by a `Ref`.

Then our `TaskQueue.Service` is constructed, defining the `handle` method. All it does is (given a non-null value for tombstones that removes entries) is add a map entry with the record key as key and the record value converted to a `Entry` to the global map (*I called `globalSet` because I was using a Set before, no especially reason*).

In Spring, dependencies would be injected via constructors using the good old [@RequiedArgsConstructor](https://projectlombok.org/features/constructor). So you can imagine that the lambda taking `console` and `globalSet` are acting as a factory while referencing both via closure.

Last, but not the least, the `Map` where all records are kept (the `TaskQueue.storeLayer` that you saw in the first snippet) is a requirement for our `TaskQueue.Service` as well as the `app` itself. It is created out of `toLayer` from a `ZRef`. It was defined in our companion object:

```scala
object TaskQueue {
    //...
    val storeLayer = ZRef.make(Map.empty[String, Entry]).toLayer
    //...
}
```


## A Note on ZLayers
I saw this [comment](https://www.reddit.com/r/scala/comments/qkdtg2/comment/hivt52u/?utm_source=share&utm_medium=web2x&context=3) in a Reddit post. The author says:

> Colleagues who are quite clear that they "like ZIO" are equally clear that ZLayer brings often overwhelming complexity to their code.

And to be honest, I spent a good half a day trying o figure out how to assemble my environment. I managed to make it work with a hand from [kit](https://twitter.com/kitlangton) in the Discord server, but it was a real trickery thing. 

Imagine this: after finally convincing the team to try ZIO, having to spend a day with the ZLayers while having a bunch of business value delayed because of this would be concerning. Still, luckily kit also posted on [twitter](https://mobile.twitter.com/kitlangton) a video showing how things look in ZIO 2.0 and this bunch of environment dependencies.

# Conclusion

ZIO feels nice. I could trace back a handful of situations where I used Reactor, but ZIO would be just a more natural fit. It also uses Fibers, that I intend to dig into with more details. Even with the warning from the doc:

> You should avoid fibers. If you can avoid fibers, then do it. 

The [Software Transactional Memory](https://zio.dev/version-1.x/datatypes/stm/index) (STM) is something I also want to give it a try. And the other concurrent primitives like [Queues](https://zio.dev/version-1.x/datatypes/concurrency/queue) and [Hubs](https://zio.dev/version-1.x/datatypes/concurrency/hub). The suite is excellent and comprehensive, and if you check the Github organization, there is a whole ecosystem that you can reliably write production applications right away.

Yes, the Layer thing can be improved and is becoming much better with 2.0. ZIO http needs to run, but with the current suite o libs, combined with Scala 3, ZIO 2 is set to explode in popularity because of its real power and flexibility, an excellent example of changing things for the better.

In my opinion, they can grow as strong and big as Spring and become the go-to ecosystem if you want to use Scala in production. Good luck, folks!

As usual, you find the complete code in my [github](https://github.com/paulosuzart/zio-example). You just need a local Kafka cluster with a topic named `leases` to make it work.