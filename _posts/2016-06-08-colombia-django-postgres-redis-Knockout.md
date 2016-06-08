---
layout: post
title: "Django + Postgres + Redis + Knockout.js. Nice shot!"
date: 2016-06-06 08:30
comments: true
categories: [python]
---

Good News
===

Hello from Colombia! Yes, we came to Colombia in order to my wife delivery our baby. Awesome! I'm also investing some resources on a new company: [Panda Team](http://www.pandateam.com.br/en). This is a quite old dream, to have my own small company and work hard to help customers succeed in their business. Visit us!

Now the post
===

*This is a kinda translation from our [blog](http://www.pandateam.com.br/blog/) at Panda Team website. Enjoy*

Crafting web apps, specially user facing web apps, are in a constant demand. Be it either an enterprise or startup, you'll need a bunch of them. But what development stack to use with so many options?

For sure you need to take into account the requirements and restrictions of each scenario, but many of the restrictions came with the lack of knowledge on beyond mature alternatives that can bring benefit with **agility**, **simplicity** and: **your project live in a blink of an eye!**.

After years developing software, I've been recommending a sort of development kit that should cover most of needs in modern applications. Not only in terms of UIX, but mainly for apps that go live with less friction.

Lets get to know the components of this stack:

Django
---

This framework isn't new actually. Launched in 2005, and there goes 10+ years of maturity. Nowadays it is a framework that leaves behind most of the frameworks commonly used in enterprise environments. We can state some of the main advantages of [Django](https://www.djangoproject.com/).

Short bootstrap and auto-reload time that always work allows for a more smooth development pace, without stress. Its template system simply works without being a burden. And what to tell about the test suit already available in the framework by default?

Django has a pretty consistent and extensive ecosystem like good ORM, safe automatic migrations among others.

PostgreSQL
---

[Postgres](http://www.postgresql.org/) is a sturdy open source database with very good performance. It is interesting to see companies like [Heroku offering](https://www.heroku.com/postgres) Postgres as a product.

It has features that are not always used, but come at hand in many situations. They are the json storage and full text search capabilities.

Combined with Django, it is possible to develop at full speed with automatic schema creation, migrations (DDL and DML).

But there are few scenarios where our next component can handle better. Lest see.

Redis
---

It is quite common to use session, cache and queues even for small apps. [Redis](http://redis.io/) is noSQL database that is perfect for this sort of requirements.

And again, the Django community provides solid libs that, in tandem with its pluggable session and cache storages are easy to integrate into your project.

Knockout.js
---

For SPA (Singla Page Applications) or not, few js frameworks are so lightweight yet powerful like [Knockout.js](http://knockoutjs.com/). Knockout reduces the complexity with nested DOM dependencies and disticnt related objects.

Conclusion **With Caution**
---

This combination presented here is by no means the silver bullet. But I confess that many of challenges that I've faced this stack could have solved the questions with one or two more libs.

I could personaly verify the success of this kit combined with some other DevOps tools. Then you reach almost non existent friction level in your IT.

Consider trying this combination, and if you need a hand, tell me.

Cheers!
