---
layout: post
title: "Ultrafast web development with Perl + Bootstrap + MongoDB"
date: 2013-09-20 19:35
comments: true
categories: [web, perl]
---

Few weeks ago I had to fix some [perl](http://www.perl.org) scripts. Actually make some HTTP requests, etc. 

That was actually my first contact with the language. Never tried before! How can it be? Well, I ended up finding an amazing community and ecosystem (mostly covered by [CPAN](http://www.perl.org/cpan.html)).

By ecosystem, I mean libs and tools out there. Couldn't be different since it was created in 1987 (I was just a kid)!

So, I needed to develop something simple yet powerful enough to be further extended with new features. But the main requirement was: DO IT RIGHT NOW!

Ok, I could have chosen [Grails](http://www.grails.org) (my daily job), but know what? I even had time for JVM startup time. Same applies to anything on JVM, even clojure web stuff. I could also have chosen [python](http://python.org/) with [Flask](http://flask.pocoo.org/) and would be great. But what I was going to add to my toolset?

Enter Perl Dancer
=================

After a quick research on the internet I found at least 3 trusted options:

-  [Catalyst](http://www.catalystframework.org/) - No, I wanted something simpler than that. Catalyst looks awesome, and I will try it at some point
-  [Mojolicious](http://mojolicio.us/) - Nice option. Very simple. But few plugins available if compared to the one I picked up
-  [Dancer](http://perldancer.org) - YES! It is super compact, and the community around it has created tons of great plugins: [Dancer::Plugin::Mongo](http://search.cpan.org/~ajct/Dancer-Plugin-Mongo-0.03/lib/Dancer/Plugin/Mongo.pm), [Dancer::Plugin::REST](http://search.cpan.org/~sukria/Dancer-Plugin-REST-0.07/lib/Dancer/Plugin/REST.pm) and [Dancer::Plugin::FlashMessage](http://search.cpan.org/~dams/Dancer-Plugin-FlashMessage-0.314/lib/Dancer/Plugin/FlashMessage.pm) just to mention a few.

That is it, assemble plugins as you want and you are done.

Another nice point is the project folder structure created by Dancer. If you are used to frameworks like Grails and Django, you'll like it. And not only that, Dancer comes by default with per-environment configuration (yaml) files, and a general config file where you configure, plugins, powerful templates, http filters, etc.

I can't open that much of the code I wrote in few nights. But I can guarantee it was funny and quick to write. A simple Http request handler is:

``` perl
get '/job/:wok_id' => sub {
  my $job = mconfigs->find_one({wok_id => params->{'wok_id'}});
  template 'jobs/edit.tt', {
    job => $job,
    server_host => config->{server},
    server_port => config->{port},
  };
};
```

It is simple like that. You call the `get` providing the request path (notice the `:wok_id` path variable) and then your perl routine that handles the request. `mconfigs` is a simple routine that wraps the access to a MongoDB collection and a query.

Most web frameworks today offer this [Sinatra](http://www.sinatrarb.com/) approach, where you define routes and functions to handle them.

The [template system](http://www.template-toolkit.org/index.html) is flexible and very powerful. Just embbed your html/css/js [Twitter Bootstrap](http://getbootstrap.com) stuff and you have beauty. No time wasted with style cascading, user interface layout, etc.

MongoDB and keep it fast
========================

As I said: DO IT RIGHT NOW! So, set up a new database machine? Create schemas? No way! Get a ready to go mongo instance at (mongoHQ)[http://www.mongohq.com/home] and start coding right away. 

The good part of it is no set up time, no administration time, and you can grow it as you go. Well, mongoHQ here was actually used for development and I don't intend to keep it once moving to production

The benefits of mongo itself you can find around. What I want to highlight is the [aggregation](http://docs.mongodb.org/manual/aggregation/) framework in conjuntion with perl. The perl hash syntax perfectly fits mongo documents:

``` perl
  my $result = mexecutions->aggregate([
       {'$match' => {'alarm_enabled' => 1}},
       {'$group' => {'_id' =>  {'status' => '$status', 'wok_id'=> '$wok_id'},
                     'count' => {'$sum' => 1}}}
   ]);
```

Using the aggregation framework you can easily break through any limitations when working without SQL statements with incredible performance.

Deploying for real
==================

Well, your dancer application is able to process one request at time if you simply run it with `perl yourap.pl`. I need to handle much more than one request at a time. There are plenty options like ones available for ruby ([unicorn](http://rubygems.org/gems/unicorn) or [passenger](https://www.phusionpassenger.com/)). I went for [uWSGI](http://uwsgi-docs.readthedocs.org/en/latest/index.html) inspite of many good options like [Twiggy](http://search.cpan.org/~miyagawa/Twiggy-0.1023/lib/Twiggy.pm) or [Startman](http://search.cpan.org/~miyagawa/Starman-0.1000/lib/Starman.pm).

uWSGI provides a robust infrastructure and supports perl as well. But not all its features are available for perl like the [queue framework](http://uwsgi-docs.readthedocs.org/en/latest/Queue.html) and [caching stuff](http://uwsgi-docs.readthedocs.org/en/latest/WebCaching.html). The speed of execution may compensate in most cases.

Wrapping Up
===========

I'm passionate about clojure, and this blog won't change because this quick perl affair. But sincerely speaking, I haven't met any clojure equivalent for web yet. Fast to start, fast to develop, fast to test and fast to deploy. Plus strong community, plugins, etc.

I'm not expert enough in perl, but it now has a nice place among my tools. I can imagne myself with front end perl stuff and crazy distributed async clojure in the back end.


