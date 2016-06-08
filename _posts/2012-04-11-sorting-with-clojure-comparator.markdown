---
layout: post
title: "sorting with clojure comparator"
date: 2012-04-11 22:51
comments: true
categories: [clojure, elementary]
---

This is a quick post to show an example of [clojure](http://clojure.org) `comparator` for sorting a list with `sort`.

At work a friend wrote dozen lines of java to sort a list of characters that represents t-shirt sizes. The sizes are: pp, p, m, mm, g, gg, a, aa. Where 'pp' is super small, 'p' small, 'm' medium, etc. 

Some shees have all the sizes available, some not. So imagine a shirt with just g, a, gg, p sizes availabe. The screen should show: p, g, gg, a.

He requested me to do a clojure version of it. Here it goes.

{% gist 2351780 %}

The first useful function is [`map-indexed`](http://clojuredocs.org/clojure_core/clojure.core/map-indexed). Since the order of sizes is not natural, we associate numbers to them given we know the size order. So `sizes` becomes `{:a 6, :gg 5, :g 4, :pp 0, :m 2, :mm 3, :aa 7, :p 1}`.

Then I used a [`comparator`](http://clojuredocs.org/clojure_core/clojure.core/comparator). It produces a `java.util.Comparator` for the given function. In this case the comparison of the map values for each key.

To finish that, the [`sort`](http://clojuredocs.org/clojure_core/clojure.core/sort) function. It takes a given product sizes list and sorts then. So `'(p, g, gg, aa)` becomes `(p g gg a)`.

It is even silly for a blog post but what if I can convince him to replace the java methods/utils/whatever methods for a [`gen-class`](http://clojuredocs.org/clojure_core/clojure.core/gen-class) of it? Packing compiled clojure code and using them for utility functions and small piece of your application can be a good way to get used to the language and confidence to start a full application in it.

Actually to let this code reusable, one can take the list of sizes instead of hard coding it. But this is an exercise for you.  

*Thanks to USA guys, you are the top visitors here. Thank you very much.*




