---
layout: post
title: "Database Functional Mapping with Slick"
date: 2015-09-23 00:22
comments: true
tags: [scala]
---

[Typesafe](http://www.typesafe.com/) guys certainly gave nice shots embracing projects like [play!](playframework.com), [akka](http://akka.io) and [Slick](http://slick.typesafe.com/).

After finally swallowing the huge change they did on play! itself since its release 1.2.4, I've been heavily playing with play! 2.4.3. I like the ability to use different persistent frameworks, but so far, it comes with the cost of sparse documentation and lack of focus on a single well understood solution and all the caveats.

<!--more-->

Anyway. Want to share some playground with Slick combined with the power of [Futures](http://docs.scala-lang.org/overviews/core/futures.html) and functional composition itself. Slick is very powerful and works basically pretending it operates on lists of objects, but behind the scenes it simply generates **type safe** sql statements.

Futures and composition
---

Look at the following sniped. This `Command` case class is kinda big to paste here, so it is cut. Same for the find method fo this DAO class.

{% highlight scala %}

//Holds data after loaded from/to database
case class Command(deleted: Boolean = false,
                   id: Option[Long] = None,
                   ...)

//Maps a table from the database
class Commands(aTag: Tag) extends Table[Command](aTag, "commands") { ... }

//Represents the collection like interface we'll be working on
lazy val commands = TableQuery[Commands]

def findAndDelete = find _ >>> delete _

def find(finder: CommandFinderQuery): Future[Command] = {
  //... Believe it will find a command
}

def delete(command: Future[Command]): Future[Int] = command.flatMap { c =>
  val q = commands.filter(_.id === c.id).map(_.deleted)
  Logger.debug(q.updateStatement)
  dbConfig.db.run(q.update(true))
}
{% endhighlight %}

So, the `delete` function takes a `Future[Command]`, that is, someone before it will actually find a command and give it to this function. All `delete` should do is to prepare a query using `filter` on `commands` table using the familiar `filter` approach.

Notice however, that after filtering, there is a `map`. This means we will only consider the field whose name is `deleted`. Couple lines below you see `dbConfig.db.run(q.update(true))`. And this is the point where the sql `UPDATE` command is really submitted to the database.

Since we are using `flatMap` on Future[Command], this then produces a new future of type `Future[Int]` that will hold the number of affected rows once it is completed.

Now take a look at `findAndDelete`. It composes the `find` function and the `delete`, so it is easy for any caller to just call it instead of chain the execution every time.

For comprehension
---

Slick also offers a monadic approach for querying multiple tables. For example, the for comprehension below:

{% highlight scala %}

for {
  group <- groups if group.name === groupName
  team <- teams if team.name === teamName && team.groupId === group.id
  cmd <- commands if cmd.teamId === team.id && cmd.seqNumber === commandSeq && !cmd.deleted
} yield cmd


{% endhighlight %}


Generates an SQL:

{% highlight sql %}
select x2."content", x2."host", x2."user_id",
       x2."team_id", x2."seq_number", x2."content_hash",
       x2."comment", x2."deleted", x2."tag", x2."starred",
       x2."id"
from "groups" x3, "teams" x4, "commands" x2
where ((x3."name" = ?) and ((x4."name" = ?) and
      (x4."group_id" = x3."id"))) and
      (((x2."team_id" = x4."id") and (x2."seq_number" = ?))
      and (not x2."deleted"))

{% endhighlight %}

This is very interesting and shows that the `for` notation will not overload your database but simply collaborate to create the query you want.

Promising and returning objects with persisted Id
---

Please don't take the following code as canonical, it was just my requirements that led me to do this. But imagine you want to add a new `Command` to the database. Instead of returning the number of affected rows or the new id only, you want a copy of the `Command` object with the id filled:

{% highlight scala %}
def ++(command: Command): Future[Command] = {
  val savedPromise = Promise[Command]

  val insertAction = commands returning commands.map(_.id) += command
  Logger.debug(insertAction.statements.mkString)
  val insertF = dbConfig.db.run(insertAction)

  insertF onFailure {
    case f => Logger.debug(s"Insert new command failed with : ${f.getMessage}")
      savedPromise.failure(f)
  }

  insertF onSuccess {
    case savedId => savedPromise.success(command.copy(id = savedId.some))
  }

  savedPromise.future
}
{% endhighlight %}


This is simply amazing. Notice the `returning` function that will make the insertAction returns a `Long` upon execution. Remember we want to deliver back a `Command`, not the produced id. The solution is to subscribe to this future inside `++`, and once it is completed, you deliver the new immutable `Command`: `savedPromise.success(command.copy(id = savedId.some))`

End
---

This is far from being a tutorial or complete example of Slick. But gives you a direction of what kind of constructs you can combine. The guys at [Underscode.io](http://underscore.io/blog/) got deeper posts. But so far, Slick shows to be a very mature solution when it comes to persistence with Scala and relational databases.

Notices it doesn't provide any caching. You would have to implement yourself. Slicks also offer the possibility to generate code from an existing database, but I personally don't like this approach.

Take care!

**important**: `>>>` and `some` comes from [Scalaz](https://github.com/scalaz/scalaz). `Logger` and `dbConfig` comes from the play! project app.
