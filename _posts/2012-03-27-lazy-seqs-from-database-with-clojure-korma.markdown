---
layout: post
title: "lazy-seqs from database with clojure korma"
date: 2012-03-27 20:54
comments: true
categories: clojure
---

As you may know, I've started in a new company last early this month. It is being a huge change in all aspects, technology, people, process, environment, etc.

Well, this week I wanted to migrate some data (900k rows) from a [MySQL](http://mysql.com/) database to a [Postgres](www.postgresql.org) one. [@felipejcruz](twitter.com/felipejcruz) recommended [py-mysql2pgsql](http://pypi.python.org/pypi/py-mysql2pgsql), but I wasn't able to put it to run with dependency - or whatever that messages were - errors. Then I tried [SQLFairy](http://sqlfairy.sourceforge.net/), but does not migrate data, just the schema ddl and other cool features (worthy features).

I ended up doing this administrative task with [clojure](http://clojure.org/) and [korma](http://sqlkorma.com/), with few functional concepts to handle the entire data set as if it was in memory.

The flow is: select everything from mysql, insert every thing into postgres. No transformation, no mapping, just select, insert. Take a look at the code:

{% gist 2221654 %}

It looks more like a script than any other complex program. Korma's `defdb` and `defentity` are used to connect to databases and define its entities. Note that there are no mappings from columns or any boilerplate annotations/codes. And since the source table and destination table are equal, it is great. But what if I wanted to transform the data model? I could use the `transform` to change the shape of the data.

Then you see `fetch-every`. It wraps a korma select with two arguments, one for limit, one for offset. So, the query can be reused at any time.

Due to the volume in the scenario, I couldn't simply fetch all data and the insert all at once. I needed to paginate. But deal with pagination right in the code the is inserting and getting more data, sucks.

Clojure offers the excellent [`lazy-seq`](http://clojuredocs.org/clojure_core/clojure.core/lazy-seq) function and allows for creating laziness from anywhere. In this case, my lazy sequence is a sequence of pages. Although possible to have infinite ones, this sequence has an end. The end of sequence os reached right after the last row was read. See the `when-let` in the code.

It is what `extract-every` does. `extract-every` actually can execute any query since it is represented by a function that takes two arguments, one for limit, one for offset (`fech-every` in this case). If we call (extract-every q 20) it will limit the result in 20 rows with a offset of 0. So the head is the 20 rows representing the results, and the tail is a lazy seq of `etract-every` with a limit of 20 and a offset of 20.

The comes `persist`, the simples function in the code. It simply takes a v as argument and persists the data in the target database. It also prints the last tow saved for recovery purposes.

Wrapping up, are the `map`, or `pmap` functions. Remember that `map` applies its first argument to every entry of its second argument. So, it is simple to assemble `(map persist (extract-every 1500))`. It will save to the target database every 1500 rows or any other amount of rows.

It took 5 to 10 minutos to write the code and start the migration.

Just to play around, try:

{% highlight clojure %}
    (defn until-ten
        ([] (until-ten 0))
        ([n] (when (<= n 10) (cons n (lazy-seq (until-ten (inc n)))))))
    (until-ten)
{% endhighlight %}

It returns from 0 to 10, being a finite lazy sequence just like the source data set. One can use `take-while` to limit the results of a lazy-seq. You can compute really big sets using the laziness approach.  

Hope it may be useful.


**Update - Apr 7 2012**: *Although an interesting and working solution, this code is not that functional. First of all, because it does I/O, but there is something that could be fixed to have a better "purity". `map` or `pmap` produce new sequences. Sequences full of `nils` in this case, because `persist` returns `nil`. The only advantage is the use of `pmap`, to run it in parallel, but it is still weird to have resulting seqs of `nils`.*

*A way to solve this bizarre code is using [`doseq`](http://clojuredocs.org/clojure_core/clojure.core/doseq) instead of `map` or `pmap`. It is a function that can bind each value of a `seq` and executes its body:*

{% highlight clojure %}
    ;;using until-ten
    (doseq [i (until-ten)]
        (println "Printing " i))

    ;;using korma
    (doseq [page (extract-every fetch-every 20)]
        (persist page))
{% endhighlight %}

*In this case, `doseq` does not retains the head of sequences, so there is no `seq` with tons being produced.*

*Thanks to everyone around the world visiting this blog. See you!*
