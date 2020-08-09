---
layout: post
title: "Korma and clojure records"
date: 2011-12-04 19:02
comments: true
tags: clojure
---
[Korma](http://sqlkorma.com) is a [clojure](http://clojure.org) framework (by [@ibdknox](http://twitter.com/ibdknox)) that provides great SQL abstractions. You can work purely with clojure code without inserting SQL strings into your code.

Consider the following entities:

{% highlight clojure %}
     (defdb mydb (mysql
                         {:port 3306
                           :host "localhost"
                           :user "root"
                           :db "korma_post"}))

    (defentity email
	    (database mydb))

    (defentity person
	    (has-one email)
	    (database mydb))
{% endhighlight %}

<!--more-->

`email` is the representation of the email table in a mysql database. Note that you don't need to specify any fields. It is optional. In this case, both entities will return the column's name as map keys in a given select. Let's see:

{% highlight clojure %}
    (select person (with email)))
    ;;will return
    [{:id 1, :name "Paulo Suzart",
       :age 29, :id_2 1x,
       :email "paulosuzart@gmail.com",
       :person_id 1}
     {:id 2,
       :name "Rafael Felini",
       :age 27,
       :id_2 2,
       :email "rafael.felini@gmail.com",
       :person_id 2}]
{% endhighlight %}
The result look like a java Resultset. You can choose the original column names to pass around your application. And since clojure is not type safe or compiled, you may find yourself suffering in cases of database refactories.

A nice solution is to combine Korma `entities` with `transform` function and clojure `defrecord` to get rid of this problem, as well as diminish the surface contact of your code concerned with database access. One solution we (me and [@rafaelfelini](http://twitter.com/rafaelfelini)) have found was:

{% highlight clojure %}
    (defrecord Person [id name age email])

    (defentity person
	    (transform #(Person. (:id %) (:name %) (:age %) (:email %)))
	    (has-one email)
	    (database mydb))

    ;; now try again
    (select person (with email)))
    ;; will return
    (#:user.Person{:id 1,
                             :name "Paulo Suzart",
                             :age 29,
                             :email "paulosuzart@gmail.com"}
     #:user.Person{:id 2,
                             :name "Rafael Felini",
                             :age 27,
                             :email "rafael.felini@gmail.com"})
{% endhighlight %}
The `transform` function takes another function that transforms a database record (with the column names as keys) into a clojure's record. In this case `Person` is the record - that always holds the e-mail. Korma takes care of the join, assuming that the `email` table has a column called `person_id`.

Now your code is a bit more resilient to database changes with this thing layer of transformation. Actually a good practice you've done all life as developer.

Korma can do a lot of things to make your life easier, as the abililty to compose queries, and performs really nice. Think I finally found THE framework for relational data access in clojure.
