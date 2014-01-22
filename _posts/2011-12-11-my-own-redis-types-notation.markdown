---
layout: post
title: "My own REDIS types notation"
date: 2011-12-11 17:20
comments: true
categories: clojure redis
---

One of the greatest [NoSQL](http://en.wikipedia.org/wiki/NoSQL) [key-value](http://en.wikipedia.org/wiki/NoSQL#Key-value_store) databases I value most, is [redis](http://redis.io/). It is simple, fast and tasty.

You interact with redis through its protocol. They are divided by commands that you can apply to its different data structures. These structures are Key, String, Hashes, Lists, Sets, Sorted Sets and channels (this one used for [pub/sub pattern](http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern)).

Since redis is key-value, it means you can store only keys with values. Right? It may sound bad at the beginning, but you get the way as you try. I'm just a newbe in redis world and I'm feeling comfortable with it.

So, due to its key-value nature you should create some structures around you main structure to help you query your data. Suppose you are using a redis `HASH` to store user information. In a javascript notation:

	HMSET  users:21 name Abraão mail somemailhere@gmail.com status pending-mail-confirmation

`HMSET` is a command to store all the `HASH` entries into a `HASH` identified by `user:21` key. And for some reason, your system get all users pending mail confirmation and send them a remember. There is no way to get all the users that has mail confirmation pending other than check every user status, what would be expensive. A helper structure may save you from this.

    SADD users:pending:confirmation 21

Bingo. Now your background process can pick up users to remember mail confirmation from the `SET` identified by `users:pending:confirmation` key.

Suppose you also want to show a welcome message to the user in the first time it visits you. You may use another helper structure.

    SADD messages:welcome 21

Thus, your system queries a `SET` identified by `messages:welcome` key to check if it should show a welcome message to the user. And finally, at the moment of user's creation, your system wants to send some information through mail also in a back ground process. Again a helper structure. 

    LPUSH users:send:mail somemailhere@gmail.com

Lot of thing to just create a user. Now imagine a big code base and even complex interactions with other helper structures like sorted sets to store information related to age, date, etc. It was my situation last week while interacting with redis. 

To make things clear and easy to remember and document. I created a simple, yet helpful (for me at least) notation to document redis structures and the sequence of interactions. Te symbols are:

![redis Types Notation](https://s3.amazonaws.com/suzart.blogs.posts/redislayout/Slide1.jpg)

Now our user's creation process using the notation we have:

![User's creation interactions](https://s3.amazonaws.com/suzart.blogs.posts/redislayout/Slide4.jpg)

It is simple and is helping a lot. Another good thing I started to do is to write queries in plain english (portuguese actually :)) to help identify which types of queries a structure is helping me to answer. To see a text version of it, visit this [new post](http://paulosuzart.github.com/blog/2011/12/11/my-own-redis-types-text-notation/).

I'm using [clj-redis](https://github.com/mmcgrana/clj-redis/) interact with redis.

