---
layout: post
title: "Sangria without case classes Part II"
date: 2017-07-29 22:35
comments: true
categories: [graphql, scala]
---

This is a sequel of [previous post Sangria without case classes](http://paulosuzart.github.io/blog/2017/07/28/sangria-without-case-classes/) where I'm exploring shapeless in conjunction with the awesome [Sangria](http://sangria-graphql.org) lib. Mind this is total exploration and chances are (actually very likely) that it is possible to do simpler code to achieve the same effect.

In this post we will see [shapeless](https://github.com/milessabin/shapeless) `HMap`s and again, use the [sangria-akka-http-example](https://github.com/sangria-graphql/sangria-akka-http-example/) as basis for our adventure.
<!--more-->

A quick refresh of what is going on here. Sangria is a awesome GraphQL lib for scala. It uses case classes in the documentation and provide a set of macros to derive some stuff from them. What is great, but, I'm trying to expose dynamic content objects no known at compile time.

`HMap`s resembles C++ [POCO Dynamic Var](https://pocoproject.org/docs/Poco.Dynamic.Struct.html) lib. I'm not comparing exactly, but this allows us to create dynamic type safe `struct`s at runtime. Of course the API is quite different and ~~ugly~~ if compared to what shapeless did taking advantage of the scala type system.

For my scenario, I defined a parametrized class `class PersistentIS[K, V]` and just three implicits to start. Let's take a look:

  {% highlight scala %}
  // SchemaDefinition.scala
  // ...
  class PersistentIS[K, V]

  // Maps a String to a Int value
  implicit val stringToInt = new PersistentIS[String, Int]
  // Maps a String to a String value
  implicit val stringToString = new PersistentIS[String, String]
  // Maps a String to another full PersistentIS
  implicit def stringToNested = new PersistentIS[String, HMap[PersistentIS]]

  // sample instance of a HMap supporting the provided implicit mappings
  val author = HMap[PersistentIS]("name" → "Josh", "age" → 33)

{% endhighlight %}

Wow, looks like a bunch of empty classes. The first occurency of `HMap` is in the implicit definition of the maping from `String` to a `PersistentIS`, that happens to be wrapped in a `HMap`. In order to create a instance of our `PersistentIS[K, V]`, just do like in the last line of the sample code above.

Now it is time to define our GraphQL `ObjectType`:

{% highlight scala %}
  // SchemaDefinition.scala
  // ...

  lazy val AuthorType = ObjectType(
    "Author",
    "sample author",
    () ⇒
      fields[CharacterRepo, HMap[PersistentIS]](
        Field("name", StringType,
          Some("Author name"),
          resolve = defaultResolve[String]
        ),
        Field("age", IntType,
          Some("Author age"),
          resolve = ctx ⇒ ctx.value.get[String, Int]("age").get
        )
      ))

  // Notice the resolve hard coded here. Could be a database returned map
  val Query = ObjectType(
    "Query", fields[CharacterRepo, Unit](
      Field("author", AuthorType,
        resolve = ctx ⇒ HMap[PersistentIS]("name" → "Josh", "age" → 33)),
      Field("book", BookType,
  // ...
{% endhighlight %}

There is a trick here. The resolvers are different and I'll show why and how in a minute. First take a look at the `age` resolve function. It is a normal Sangria way to resolve a field from a `Val` stored in the `Context` here named `ctx `. That is, the query resolver returns a Value of type `HMap[PersistentIS]` and this resolve function extracts the needed field from it.

The point is that we need to know the type of the result value (a `Int` for `age`) but also the name of the field. I wanted to get rid of both and use just `defaultResolve` but so far I couldn't wipe them. But at least the field name I managed to get rid of. **Not that the code that I'm showing below has the sole purpose to get rid of the field name while extracting it from the `HMap[PersistentIS]`. The main goal here is a more dynamic configuration of GraphQL as well as its resolve functions**.

Here we go! A lot of code at first but in summary what is involved is a type class that defines a get method, instances of this type class for `Int` and `String`. And as a extra step the definition of the `defaultResolve[Res]`:

{% highlight scala %}
  // SchemaDefinition.scala
  // ...
  // Here the type class that gets values V from HMap[PersistentIS] given a key value K
  trait PersistentGet[K, V] {
    def get(k: K, m: HMap[PersistentIS]): V
  }

  // Here the conventional way to add the summoner (apply) and a instance helper
  object PersistentGet {
    // This allows for implicit resolution via PersistentGet[String, Int], for example
    def apply[K, V](implicit getter: PersistentGet[K, V]) = getter

    // Helps instantiate a new PersistentGet[K, V], takes as parameter the function that does the actuall work
    // against the HMap[PersistentIS]
    def instance[K, V](f: ((K, HMap[PersistentIS]) ⇒ V)) = new PersistentGet[K, V] {
      override def get(k: K, m: HMap[PersistentIS]): V = {
        f(k, m)
      }
    }
  }


  // Finally the two implementations
  implicit val getString = PersistentGet.instance[String, String]((k, m) ⇒ m.get[String, String](k).get)
  implicit val getInt = PersistentGet.instance[String, Int]((k, m) ⇒ m.get[String, Int](k).get)


{% endhighlight %}

Ok I know, looks like lots of code, etc, etc. But to be fair when you start working with type classes and concepts you also find in [Haskell](http://haskell.org) and [Cats](http://typelevel.org/cats/), you have a thinking shift. It is like you start to see code in multiple dimensions instead of the usual linear *roll from the top to the bottom of the file and you are ok to write, read and luckily understand code*.

The code above is commented, so no extra info to add. Now the most confusing part - *must confess* - of the code. The `defaultResolve` signature:

{% highlight scala %}
  def defaultResolve[Res]
    (implicit getter: PersistentGet[String, Res]) :
    (Context[CharacterRepo, HMap[PersistentIS]] => Action[CharacterRepo, Res]) = ctx ⇒ getter.get(ctx.field.name, ctx.value) 
{% endhighlight %}


Go back to the second snippet, you'll quickly grasp that `defaultResolve[String]` is actually returning a resolve function as required by Sangria. There is nothing special here actually. Just pay attention to the implicit getter that is resolved based on `[Res]`. Using this getter we then extract the value from the context value, a `HMap[PersistentIS]` and return it as `Res` that happen to be `Int` or `String`.

I wanted to remove the type parameter from `defaultResolve[String]` and use just `defaultResolve` but maybe after abstracting the whole generation of the GrpahQL `ObjectType` this will work.

Conclusion
===

`HMaps` is quite powerful and using it caused no impact in the GrpahQL exposed API, everything works normal. It results in a more dynamic behavior when compared to `Records` that requires a macro to generate the appropriate labeled `HList`.

I'm ~~in love~~ with shapeless. This thing is simply mind blowing. I thought I would be using labeled `HLists` some how. But not sure if possible due to the lack of information at compile time to get singleton types, etc. Well, need to investigate more and hope this investigation can result in another post.

Happy shapeless!