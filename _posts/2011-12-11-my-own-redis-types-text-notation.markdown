---
layout: post
title: "My Own REDIS Types - text - Notation"
date: 2011-12-11 18:11
comments: true
categories: [clojure, redis]
---
Some seconds after the [last post](http://paulosuzart.github.com/blog/2011/12/11/my-own-redis-types-notation/), [@paraseba](http://twitter.com/paraseba) commented that a text version of this notation may be even more helpful.

Here it is:

* `$` means provided by some interaction with redis.
* `*` means provided by user.
* `key` represents a redis KEY with the value set by `SET`.
* `(listkey)` represents a redis LIST with elements manipulated by `LPUSH` and so on.
* `{hashkey [key values]}` represents a redis `HASH` with data set by `HSET` or `HMSET`.
* `#{setkey data}` represents a set or sorted set.
* `as $varname` may be used for situations where `INCR` is used to generate an ID.

<!--more-->

The last post user creation process may be written as:

	users:next as $uid
	{users:$uid data}
	#{users:pending:confirmation $uid)
	#{messages:welcome $uid}
	(users:send:mail *mail)

An instance of this process would be:

    users:next ;; suppose 21 as result
    {users:21 [name Abraao mail somemailhere@gmail.com status pending-mail-confirmation]}
    #{users:pending:confirmation 21)
    #{messages:welcome 21}
    (users:send:mail somemailhere@gmail.com)

It is the form I'm using as doc strings in a namespace. It looks great with [Marginalia](http://www.fogus.me/fun/marginalia/).

