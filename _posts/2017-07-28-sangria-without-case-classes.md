---
layout: post
title: "Sangria without case classes"
date: 2017-07-28 01:18
comments: true
tags: [graphql,scala]
---

In my [previous post](http://paulosuzart.github.io/blog/2017/07/26/graphql-yes-im-in/) I talked about how easy it is to implement a dynamically generated [GraphQL](http://graphql.org) Schema using `graphql-js` as you can simply ignores types and do your job. I then made some comments about [Sangria](http://sangria-graphql.org), perhaps the most stable and powerful GraphQL lib for Scala. Follow me in this exploration until I find a solution or a good soul can share it with us.

If you refer to the [sangria-akka-http-example](https://github.com/sangria-graphql/sangria-akka-http-example/) project, you'll see the hand made schema. Something like:
<!--more-->

{% highlight scala %}

// Data.scala

trait Character {
  def id: String
  def name: Option[String]
  def friends: List[String]
  def appearsIn: List[Episode.Value]
}

case class Droid(
                  id: String,
                  name: Option[String],
                  friends: List[String],
                  appearsIn: List[Episode.Value],
                  primaryFunction: Option[String]) extends Character

// SchemaDefinition.scala

  val Droid = ObjectType(
    "Droid",
    "A mechanical creature in the Star Wars universe.",
    interfaces[CharacterRepo, Droid](Character),
    fields[CharacterRepo, Droid](
      Field("id", StringType,
        Some("The id of the droid."),
        tags = ProjectionName("_id") :: Nil,
        resolve = _.value.id),
      Field("name", OptionType(StringType),
        Some("The name of the droid."),
        resolve = ctx ⇒ Future.successful(ctx.value.name)),
      Field("friends", ListType(Character),
        Some("The friends of the droid, or an empty list if they have none."),
        resolve = ctx ⇒ characters.deferSeqOpt(ctx.value.friends)),
      Field("appearsIn", OptionType(ListType(OptionType(EpisodeEnum))),
        Some("Which movies they appear in."),
        resolve = _.value.appearsIn map (e ⇒ Some(e))),
      Field("primaryFunction", OptionType(StringType),
        Some("The primary function of the droid."),
        resolve = _.value.primaryFunction)
    ))
{% endhighlight %}

Here the `Droid` `ObjectType` uses a `Droid` (a case class) as its internal representation. In order to circunvent such way to define GraphQL Object Types, I tried many things using [shapeless](https://github.com/milessabin/shapeless). 

To be fair, I'm far from being proficient in shapeless. And the only solution I found so far was to use `Record`s. This is a half solution because even using it, I had to set up the Record by hand. Look:

{% highlight scala %}


// SchemaDefinition.scala

  type Book = Record.`'year -> Int, 'title -> String, 'available -> Boolean`.T

  val BookType = ObjectType(
    "Book",
    "sample book",
    fields[CharacterRepo, Book](
      Field("title", StringType,
        Some("Book Title"),
        resolve = ctx ⇒ ctx.value('title)),
      Field("year", IntType,
        Some("Year of publication"),
        resolve = ctx ⇒ ctx.value('year)),
      Field("available", BooleanType,
        Some("Indicates if available"),
        resolve = ctx ⇒ ctx.value('available))
    ))

  val Query = ObjectType(
    "Query", fields[CharacterRepo, Unit](
      Field("book", BookType,
        resolve = ctx ⇒ Record(year = 2012, title = "Land of Lisp",  available = true)),
      Field("hero", Character,
{% endhighlight %}

There is a powerful macro here responsible for generating the type of our book. But I still couldn't find a way to generate the `Book` type at runtime. Bear the `resolve` here is hard coded instead of bringing something from the database, for example. Enough for our purpose though.

We were able to replace a case class by a shapeless `Record` and I think in few more tries we can replace everything by `HList`s. In fact if you create a instance of `Book`, you'll see the type as a HList with tagged type parameters and - ~~not sure~~ - some singleton types for the field labels.

{% highlight scala %}
scala> val b = Record(year = 2012, title = "Land of Lisp",  available = true)
b: shapeless.::[shapeless.labelled.FieldType[shapeless.tag.@@[Symbol,String("year")],Int],
shapeless.::[shapeless.labelled.FieldType[shapeless.tag.@@[Symbol,String("title")],String],
shapeless.::[shapeless.labelled.FieldType[shapeless.tag.@@[Symbol,String("available")],Boolean],shapeless.HNil]]] 
= 2012 :: Land of Lisp :: true :: HNil
{% endhighlight %}

In the end, the problem is not only replacing case classes for something more dynamic, but the Sangria `Field` and `ObjectType` are quite annoying to instantiate if you start moving things around and for example don't use `fields` function from `sangria.schema` package object.

Conclusion
===

While the solution in NodeJs or clojure would be simply replace the thing by `maps`, using `Map[String, Any]` in scala is not only bizarre but would led to a confusing code full of type casts and exception prone. Shapeless comes to the rescue and allows for elegant, abstract generic approach while keeping your code safe.

Ok, good results so far. I'm using this challenge to (re)warm my mind around Scala. My last and sole system in production written in scala was released almost two years ago and it is wise to refresh knowledge from time to time.

My next steps includes getting some inspiration from [Underscore.io](http://underscore.io) using [Using shapeless HLists with Slick 3](http://underscore.io/blog/posts/2015/08/08/slickless.html) blog post as basis and studying more about shapeless using the Underscore.io book and some [E.near](http://enear.github.io/2016/09/27/bits-of-shapeless-2/) blog posts.

I wouldn't be surprised if a experienced shapeless professional drop a comment and say: *hey newbie, just do this and that* :). Nonetheless, I'm enjoying the path to solve the case. If you know how to solve it or need more context on what I'm trying to do, send me a email or leave a comment.

Happy shapeless!