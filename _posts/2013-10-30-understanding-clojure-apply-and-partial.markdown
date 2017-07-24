---
layout: post
title: "Understanding Clojure apply and partial"
date: 2013-10-30 20:15
comments: true
categories: clojure
---

Hi guys, a really introductory post on [Clojure](http://clojure.org) `apply` and `partial`functions. I need to confess that I didn't take a look around to see how people are usually explaining these functions. For sure there are better ways to explain it even usingJavascript, but remember: it was used to teach a beginne, so no purism here.

Anyway. These sample `js` codes come from the explanation I gave to a colleague at work. And pretty much worked to illustrate both cases.
<!--more-->
Apply
=====
To a beginner it might be not that easy to imagine how they will find room for using `apply`. They think it will take millon years until it become useful. Wrong!

After listening to some "newbysh" considerations I came across the following code in Java Script, a well known language:

{% highlight javascript %}
// Imagine a function returning this
var pessoa = [21, "paulo", "red"];

// And you have the following function to user
var printer = function(age, name, color) {
    console.log("Person with name " + name + " and age " + age + " and cor " + color);
};

// You'll probably do this
printer(pessoa[0], pessoa[1], "vermelho");
// => Person with name paulo and age 21 and cor red
// But imagine you could do this:
apply(printer, pessoa);

// This would be possible using the following apply function

var apply = function(fn, args) {
  var str = "fn(";
  for (x = 0; x < args.length; x++)  {
    str = str + "args["+x+"]";
    if (x < args.length - 1) {
      str += ",";
    }
  }

  str += ");";
  console.log(str);
  eval(str);
};

// And the output is the same:
// => Person with name paulo and age 21 and cor red
{% endhighlight %}
After reading this snippet. He instantaneously understood everything and how helpful `apply` is. Wrapping up, ...

> ## ... I told him:
Use apply for variadic functions. Functions you don't know how many arguments it can take and you want to consider each element in a vector as if they were independent arguments. Or, even if you know how many args this function takes, for many times you'll have vectors with values that matches arguments of a function.

For the second case it is easier to use [destructuring](http://clojure.org/special_forms#Special%20Forms--Binding%20Forms%20(Destructuring)), but it still applies.

Partial
=======
Believe me, there are plenty ways to explain this. From the most scientific to the most simplistic. I would say below you are going to the a simplistic like explannation. But enough to bootstrap you with your clojure code.

{% highlight javascript %}
var hello = function(saud, name) {
  console.log(saud + ", " + name);
};

hello("ola", "brunolandia");

var morning = function(nome) {
  hello("Bom dia", nome);
};

morning("Brunovisk");
{% endhighlight %}

After reading the snippet...

> ## ... he then came to an end:
> But Paulo, `morning` is just reducing the `hello` function surface, then exposing another function that takes one argument and forwards it to `hello`, plus passing a constant predefined argument.

**YES**. That is it! But the most important question was: when should I use it?

[Partial functions](http://blog.jayfields.com/2011/01/clojure-partial-and-comp.html) have a plenty use cases. To not make things "scientific" and keep then simple:

Imagine you are providing functions to someone else to query a database. You might create a base function that takes an enormous number arguments that actually assemble the queries. But you want to guarantee that certain fields/constraints/indexes are present on every query.

A good choice is to partially apply this base function with your prefixed well known safe arguments and then expose this produced function to your users.

There are much more use cases for partial functions. A good motivation is to make your code more legible and elegant. A good post on it was published by Christopher Maier [right here](http://christophermaier.name/blog/2011/07/07/writing-elegant-clojure-code-using-higher-order-functions).

Well, hope you liked the text and that it can help you faster understand things that may be left behind while studying it. See you!
