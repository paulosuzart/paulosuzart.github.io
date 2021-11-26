---
layout: post
title: "Trying ZIO Tests"
date: 2021-11-26 13:22
comments: true
tags: [scala]
---

In my [last post "My Time with ZIO"]({% post_url 2021-11-24-my-time-with-zio %}), we saw how ZIO applications could be created and assembled. But what about tests? In this post, I will share a simple test suite I've added to that original code and give a sense of ZIO Tests.

<!--more-->

The previous post was long enough; that's why I'm sharing this content in a new post. I hope it is helpful.

# ZIO Test
Considering the whole ZIO website, the [Test section](https://zio.dev/version-1.x/howto/use-test-assertions) is somewhat shy, especially compared to the entire content of ZIO 1.x. Tests are covered in the how-to section.

To write my tests entirely, I watched this excellent session by Adam Fraser on YouTube: [100 with ZIO Test by Adam Fraser: Scala in the City Conference](https://www.youtube.com/watch?v=qDFfVinjDPQ).

There's another shy content in the [Use Cases](https://zio.dev/version-1.x/usecases/usecases_testing) section of ZIO website. But although the content is not as heavy and deep as [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/), things start to make sense as you begin to map back to your knowledge zone.

# Testing my code

I wanted to do an elementary test. No integration, test container, or any embedded Kafka. Just unit test the service from the previous post. Let's recap the code:

```scala
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
```

The method `handle` takes a `CommittableRecord` and updates a `Ref` to a map. The code branches if the value of the record is null (a tombstone). The Topic I was using was compacted, so deleting entries from such Topic requires the client to emit a tombstone. That is, a message with a given key, but a null payload.

We will need to call our `handle` method providing a real or mocked `CommittableRecord` and then access our global `Ref` to run a couple of assertions. 

## Test Case 1
*Handle should add entry to the global map*. That is, with a empty global map, a new record arriving will lead to the insertion of the record to the global map:

```scala
    testM("Add entry to ref correctly") {
      val record            = new ConsumerRecord("topic", 0, 21, "a-key", "a-value")
      val committableRecord = CommittableRecord[String, String](record, Map.empty, None)

      for {
        _ <- handle(committableRecord)
        x <- ZIO.access[GlobalSet](_.get)
        c <- x.get
      } yield assert(c)(equalTo(Map("a-key" -> Entry("a-key", "a-value"))))
    }
```

We call `testM` to test our effectful operation `handle`. The method `handle` here is being imported, but I removed some boilerplate to let the code lean. And all I did was create a Kafka consumer record with some fake values and then wrap it on a `CommittableRecord`.

The other option is to actually mock `CommittableRecord` but people are a bit sensitive nowadays, check [this discussion](https://www.reddit.com/r/scala/comments/pz175l/mocking_with_scala3/) and also [this one](https://www.reddit.com/r/scala/comments/pxakhe/comment/herg7mt/). I'm also against over mocking and using [`verify`](https://www.baeldung.com/mockito-verify) everywhere. But I recognize that mocking can be beneficial when testing parts of our code that deal with third-party code. Because, although mocking will create empty objects, providing half backed objects like I did with `CommittableRecord` can produce unintended behavior.

But let's see our second case.

## Test Case 2

*Drop nonexisting entry from ref keeps it unchanged*. So considering our tests are running in sequence as part of the same suite. If we tombstone a record with a key other than the record just inserted, nothing should change.

```scala
    testM("Drop nonexisting entry from ref keeps it unchanged") {
      val record2 =
        new ConsumerRecord[String, String]("topic", 0, 21, "a-key2", null.asInstanceOf[String])
      val tombstone = CommittableRecord[String, String](record2, Map.empty, None)

      for {
        _ <- handle(tombstone)
        x <- ZIO.access[GlobalSet](_.get)
        c <- x.get
      } yield assert(c)(equalTo(Map("a-key" -> Entry("a-key", "a-value"))))
    }
```

## Test Case 3
Finally, *Drop entry from ref correctly*. This case is the handling tombstones, so the Map should become empty again if it runs successfully.

```scala
    testM("Drop entry from ref correctly") {
      val record2 =
        new ConsumerRecord[String, String]("topic", 0, 21, "a-key", null.asInstanceOf[String])
      val tombstone = CommittableRecord[String, String](record2, Map.empty, None)

      for {
        _ <- handle(tombstone)
        x <- ZIO.access[GlobalSet](_.get)
        c <- x.get
      } yield assert(c)(isEmpty)
    }
  ).provideCustomLayerShared(store ++ testEnv) @@ sequential

}
```

## Our Suite
ZIO Test uses suites as an aggregator for related tests. It is up to you to group them in a way that makes sense.

For this simple suite, we create a Spec, and we need to implement `spec` that will return our spec with tests and assertions. The key thing here is the `provideCustomLayerShared(store ++ testEnv)`. This is where we will provide the real implementations for our test to run against. In this case, we are using the real
`TaskQueue.storeLayer` and the real available implementation of our `TaskQueue` service: `TaskQueue.live`.

The tests got a bit repetitive, but I found it to be the best disposition, considerig the assertion is not applied to the output of the call to `handle`. 

```scala
object TaskQueueSpec extends DefaultRunnableSpec {
  import TaskQueue._

  val store   = TaskQueue.storeLayer
  val testEnv = (Console.live ++ store) >>> TaskQueue.live

  def spec = suite("Handle should add entry to the global map")(
    testM("Add entry to ref correctly") { 
      //...
    },
    testM("Drop non existing entry from ref keeps it unchanged") {
      //...
    },
    testM("Drop entry from ref correctly") {
      //...
    }
  ).provideCustomLayerShared(store ++ testEnv) @@ sequential

}
```

Finally, ZIO provides what they call Test Aspects, and you can find all of them [here](https://github.com/zio/zio/blob/master/test/shared/src/main/scala/zio/test/TestAspect.scala). They are not Aspect in the [AspectJ](https://en.wikipedia.org/wiki/AspectJ) sense, but a literal sense instead. So one of the aspects of my test suite is that tests must run sequentially, so the assertions will make sense. Thus you see `sequential` to instruct the Spec how to run the tests.


# Conclusion

There are open questions in my head. They stem from the fact this is just a trial with no actual production code being tested here. Mapping to my world of Spring and its surroundings comfort zone, there are a couple of things that come to my mind:

1. How to partially mock services in an extensive hierarchy of services? Will that require a lot of handwork to create all variations of environments?
1. What about solutions tightly integrated with JUnit like [Test Containers](https://www.testcontainers.org/test_framework_integration/junit_5/)? Will that work?
1. How to do [@BeforeAll](https://junit.org/junit5/docs/5.0.0/api/org/junit/jupiter/api/BeforeAll.html) and alike?
1. Will the folks at ZIO provide a mock capability like Mockito? What about [Power Mock](https://github.com/powermock/powermock)?

Time will tell, and more research from my end will answer a couple of them.

Other than that, ZIO Test is a great initiative. Instead of focusing only on the core of ZIO, the team behind it is aiming for a comprehensive, end-to-end approach, which is great!

ZIO offers a considerable number of assertions that will cover almost everything you may require. They also provide property-based testing with out-of-the-box generation of test data or constrained generation to better control which data will come out of the generators.

My example is more or less complete with a simple feature, a simple test, and an increasing admiration for ZIO. If you are looking for a more thorough and profound ZIO Test post, you may visit Pavels Sisojevs [post](https://scala.monster/zio-test/) to find much more.


The code for this test you can find on my [github](https://github.com/paulosuzart/zio-example/blob/master/src/test/scala/io/bpp/TaskQueueSpec.scala).