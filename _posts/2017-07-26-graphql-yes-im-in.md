---
layout: post
title: "GraphQL, yes I'm in!"
date: 2017-07-26 13:22
comments: true
categories: [graphql]
---

[GraphQL](http://graphql.org) is without a shadow of a doubt the latest cool thing in the fields of providing a API. It's not a total novelty, given that it's been around since 2015 (publicly) and in theory, it's some how running on Facebook since 2012.

In summary, GraphQL gives clients the power to decide what they want, including to fetch related data at  - virtually - any depth level. How they do that? The answer is a query language instead of meaningless JSON payloads and blind REST like endpoints.
<!--more-->

You may argue that frameworks like [sailsjs](sailsjs.com) and [loopback](loopback.io) offer the some flexibility but still using plain old json / rest endpoints. Yes, at some extent. But there are limitations that I'm safe to say they are insurmountable. With GraphQL language you have a white board to request what you want and the result will be as powerful as the GraphQL server wants to.

If REST like endpoints always return all data, and client uses what they want we are in trouble. If your client uses 50% of the returned fields, you are wasting cpu cycles, network bandwidth and ultimatelly can be harming the user experience. There is also a commong scenario where your clientes need more data and you have to change your API, mobilize developers and do a new deployment just to now offer a new field to a client.

All these situations and more are nicely handled with GraphQL.

BaaS Back end as A Service
===

Not sure if the therm comes after the emerging GraphQL awareness. But the is now a established area in the *aaS offerings. Below a list of BaaS that I find powerful and flexible.

- [Graph.cool](graph.cool) - They are by far the team leading the GraphQL in terms of educating their own market to show the power of what they offer. They also public lots of content and tools like [graphql-up](https://www.graph.cool/graphql-up/). By the way their web console is amazing and the integrations with Lambda and Auth0 Extend is amazing.
- [Scaphold.io](scaphold.io) - This guys are also tough. They are very similar to Graph.cool and IMO they offer a better GraphQL Schema allowing good aggregations not only in the Model you are querying but also in related Models. They also have integrations to [Algolia](https://www.algolia.com), push notifications and Email sending. But they have a much poor web console for the service.
- [Reindex](https://www.reindex.io) - This started as a product in the same model of both above, but now I see the web site presenting them like a consultancy on GraphQL

Back end as a Service is emerging and many types of applications can take advantages of them. In the same wavelength of using services like Firebase (hosting, database, functions), I see the Back end as a Service with lot of potetial to continue to growth and become permanent in the making of digital initiatives that involves quick prototyping, flexibility and production ready solutions.

Which lib to use?
===

This is a hard decision to make. There are lots of libs in several languages. But the most up to date lib to the GraphQL spec is the nodejs lib provided by facebook itself. [graphql-js](http://graphql.org/graphql-js/) is powerful and although written in javascript, it fully supports [Flow](flow.org), the Facebook's js **type system** that you can opt-out at will.

Another great lib is [Lacinia](https://github.com/walmartlabs/lacinia), created by Wallmart and written in clojure. This think is a master piece and simply fits the clojure idoms like a glove.

Even better than Lacinia is [Sangria](http://sangria-graphql.org), the Scala GraphQL lib. This is simply a astonishing job. To me, one of the remarkable thing of this lib is the [Actions](http://sangria-graphql.org/learn/#actions) the resolvers need to return. This brings the [Play Framework Actions](https://www.playframework.com/documentation/2.6.x/ScalaActionsComposition) to my mind.

Sangria also offer a lots of libs that makes it easy to integrate it with marshalling. Check the [Download](http://sangria-graphql.org/download/) page.


`graphql-js` is specially useful if you are generating GraphQL schemas dynamically, which is my case. Plenty libs show cases where you are in control of your schema, where you can create them by hand (in development time) and bind it to a ORM Model, or ORM framework. But if you are creating a Back end as a Service product, the last thing you know is how the schema will be, given that the user itself will define their types, relations, etc.

This makes things a lot harder to do with a compiled language like Java, Scala or even Go. I tried to implement part of the product I work on using Scala, and it is simply way too laborious process, despite of trying to use [shapeless](https://github.com/milessabin/shapeless). The whole thing escalates to a point where you will see yourself having to write code that is not part of your business at all.

This is funny because GraphQL is **all about types** and implementing a dynamic schema generation becomes painful in typed languages. The point is that GraphQL types are described dynamically not embedded in the hosting language. I'm not saying this is impossible (actually, there are projects written in typed langs generating schemas from postgres catalog), but will require extra effort to the the same you do with your eyes cloded with a daynamic language.

A bit of Sangria
===

Bear the Sangria documentation is quite nice. I wish the code was better documented to help faster understand what is going on behind the scenes. But as the default pet schema is the Star Wars Schema, there is no mutation example (or I couldn't find).

In the example (that I clonded from [sangria-akka-http-example](https://github.com/sangria-graphql/sangria-akka-http-example/)), all I did was to add a `createHuman` mutation. The mutation can be defined as follow:

{% highlight scala %}
  // ... in SchemaDefinition.scala
  case class CreateHuman(id: String, name: String)
  implicit val createHumanFormat = jsonFormat2(CreateHuman)


  val CreateHumanInputType = deriveInputObjectType[CreateHuman](
    InputObjectTypeName("CreateHumanInputType"),
    InputObjectTypeDescription("Create Human Input")
  )

  val CreateHumanArg = Argument("input", CreateHumanInputType, description = "Create Human Input")

  val Mutation = ObjectType(
    "Mutation", fields[CharacterRepo, Unit](
      Field("createHuman", Character,
        arguments = CreateHumanArg :: Nil,
        resolve = ctx ⇒ ctx.ctx.addHuman(ctx.arg(CreateHumanArg).id, ctx.arg(CreateHumanArg).name)
      )
  ))

  // ... in Data.scala

class CharacterRepo {
    def addHuman(id: String, name: String): Human = {
    val newHuman = Human(id = id, name = Some(name), friends = List("1000", "1002", "2000", "2001"), appearsIn = List(), homePlanet = Some("Tatooine"))
    humans += newHuman
    print(newHuman)
    newHuman
  }
}
{% endhighlight %}

This allows us to issue ea GraphQL Mutation like this:

{% highlight graphql %}
mutation CreateHuman($input: CreateHumanInputType!) {
  createHuman(input: $input) {
    friends {
      name
    }
  }
}
{% endhighlight %}

Notice the `CreateHumanInputType`. This GraphQL scpecific type is dereived from a `case class CreateHuman(id: String, name: String)`. More on this in the  [Macro-Based GraphQL Type Derivation](http://sangria-graphql.org/learn/#macro-based-graphql-type-derivation) section. Is very handy and let you focus on how to name the input object, add a description and also hide fields or rename them.

Our mutation has a field `createHuman` that returs the ObjectType `Human` and as the existing schema defines all `resolve` for this type, we benefit from it and have to implement nothing to get the related friends of the newly created human (bear I've hardcoded it in `friends`).

Conclusion
===

GraphQL is here to stay in the same way REST like APIs won't die in the mid term. I'm currently working in a sort of Back end as a Service product and I believe this can be used not only between front-end <-> back end communication, but server <-> server communication with no harm.

Sangria makes it easy to implement GraphQL servers where you have full control of the schema, but I need to work more to generate and resolve schemas dynamically where data will eventually go to a database.

I won't doubt more tools around GraphQL like full proxies that will be able to route GraphQL queries to different GraphQL servers after applying some process like deep authorization (when you check if the user has permission to interacti with a specific field of a Model), query depth limit, and aggregate results of non GraphQL services (like indexing with Algolia, or any other provider that talks REST) to the response, etc.

Happy GraphQL!






