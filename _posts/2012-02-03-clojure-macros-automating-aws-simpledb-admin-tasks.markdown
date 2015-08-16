---
layout: post
title: "Clojure macros: Automating AWS SimpleDB admin tasks."
date: 2012-02-03 21:16
comments: true
categories: clojure
---
First post of the year! To talk about clojure, of course.
[I've written (pt_br)](http://codemountain.wordpress.com/2010/10/09/clojure-macros/) about clojure macros before. And yes, it is really powerful.

I'm using macros to help me setting up a connection with [Amazon SimpleDB](http://aws.amazon.com/simpledb/) to do some small administrative tasks such as listing domains, creating domains, counting items in a domain, etc.

SimpleDB hasn't a console, so you have interact with it using a pure html + js application provided by AWS, or do it by hand. I do prefer doing it by my own :). Then I created de following macro:

{% highlight clojure %}
(defmacro boot-sdb []
	'(do

		(.setLevel (java.util.logging.Logger/getLogger "com.amazonaws")
  java.util.logging.Level/WARNING)
		(.setLevel (java.util.logging.Logger/getLogger "httpclient")
  java.util.logging.Level/WARNING)
		(.setLevel (java.util.logging.Logger/getLogger "org.apache.commons.httpclient")
  java.util.logging.Level/WARNING)

		(require (quote [cemerick.rummage :as sdb]))
	 	(require (quote [cemerick.rummage.encoding :as enc]))
	 	(use (quote apix.util))

	 	(def *sdb* (sdb/create-client (env "AWS_KEYID") (env "AWS_KEY")))
	 	(def *sdbconf* (assoc enc/keyword-strings :client *sdb*))
	 	(println "Connected to SDB.")

	 	(defn lsd [] (sdb/list-domains *sdbconf*))


	 	(defn mkd [d] (sdb/create-domain *sdbconf* d))

	 	(defn rmd [d] (sdb/delete-domain *sdbconf* d))

	 	(defn countd [d] (str
		 					(format "Total items [%s]: " d)
		 					(:itemCount (sdb/domain-metadata *sdbconf* d))))

		(defn sdb-help []
			(println "Type '(lsd)' to list all domains")
	 		(println "Type '(mkd domain-name)' to create a new domain")
			(println "Type '(rmd domain-name)' to delete a domain")
			(println "Type '(countd domain)' to get the items count of domain")
			(println "Type '(sdb-help)' to see this help again"))

		(sdb-help)))
{% endhighlight %}

It saves the work of configuring the appropriate log levels as well as creating SimpleDB client using [rummage](https://github.com/cemerick/rummage) (a SimpleDB client by [@cemerick](twitter.com/cemerick)).

And why a macro? Because in some extent you can see a macro as a code template, just like [Velocity](http://velocity.apache.org/) or [String Template](http://www.stringtemplate.org/). So what this macro does is just "typing" all this code on my REPL namespace, than the defined functions and vars are automatic available in the `user` namespace.

Using it is simple:

{% highlight clojure %}
    (use 'the.macro.namespace)
    (boot-sdb)
    Connected to SDB.
    Type '(lsd)' to list all domains
    Type '(mkd domain-name)' to create a new domain
    Type '(rmd domain-name)' to delete a domain
    Type '(countd domain)' to get the items count of domain
    Type '(sdb-help)' to see this help again
    nil
{% endhighlight %}

`(boot-sdb)` "types" all the code for you, then you can call the functions like `(lsd)` to get the list of domains in your SimpleDB.

If take a closer look you may notice a function call to `(env "AWS_KEYID")`. It simply gets the environment variables set with your credentials.

You can extend the macro to have any admin task you may need. Note that the `*sdbconf*` will become available, so you can call rummage directly without having to configure all again.

That is it. Clojure is smart!
