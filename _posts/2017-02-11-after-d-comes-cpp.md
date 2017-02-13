---
layout: post
title: "After D comes C++"
date: 2017-02-10 10:22
comments: true
categories: [programming D C++]
---

As mentioned in my [previous post](http://paulosuzart.github.io/blog/2017/02/10/languages-and-counting/), we may be openning our GraphQL Grammar (using [PEGGED](https://github.com/PhilippeSigaud/Pegged)), and interpreter to generate compatible pure D Abstract Syntax Tree.

While we don't have any decision, let's talk about D and Why I ended up building an entire server in C++.

We were looking for a compiled language with powerful type system for OO purposes (That's why dropped [Go](https://golang.org/)), that wasn't Java. With Scala going down the hill, there was few options that could make any sense. They were D or C++. 

C++ has a myth that it is complex and hard (well, it might be sometimes), so we picked up D!

The language is simply awesome! If you read the [Language Reference](https://dlang.org/spec/spec.html) up get instantlly on fire. It also has [DUB](https://code.dlang.org/), a sort of poor cousing of [NPM], [Cargo](https://crates.io/) or [hex](https://hex.pm/). Just add your dependencies, and run `dub`. That is all, your code will be compiled to native code and you can run it. Take a look at this `dub.json` file, the main projec descriptor:

{% highlight json %}

{
	"name": "graphqld",
	"authors": [
		"Paulo Suzart"
	],
	
	"dependencies": {
		"pegged": "~>0.3.3",
		"accessors": "~>1.0.0",
		"d-unit": "~>0.8.1",
		"ddbc": "~>0.3.2"
	},
	"description": "D Graphql Server",
	"copyright": "Copyright © 2016, Paulo Suzart",
	"license": "proprietary",
	"-ddoxFilterArgs": ["--ex", "pegged"]
}
{% endhighlight %}




For a compiled language that needs to have libs linked, etc. This is really great stuff.

D comes with a Template system for generic programming (Like Java Generics or C++ templates, but more powerful perhaps). It extends to code generation at compile time, allowing a small code base that can produce huge codebases saving a lot of repetition. There are many cases where you have to repeat, over and over again the same code. Suppose this real case of a visitor that goes through a AST, gets the children of eath node, then visits them. You can easily reach dozens of repetitions.

The gist below shows a visitor base class `BaseGraphQLVisitor`. It visits a `Node`, gets its children, iterates over it an then calls `visitNameOfTheNodeTypeHere`. The more you have types, the more you have to type to produce such visitor.

Check it ou and try to understand what is going on:

{% gist b4a4f41d011d5950829248b5a6b944a6 %}

Look at the `BaseGraphQLVisitor`, due to the nature of the language, it holds  a map of `strings` mapping to sort of lambda functions (called delegates). If you pay extra attention, notice there is absolute no function in the class body. No, they are not inherited from a parent class, instead, they are generated at compile time. See `visitDocument`, `visitDefinition` and so on.

Watch the line 74 where the generated code is "inserted" in. `GenerateVisitMethods` is a string that looks like normal code *because I'm using `q` for quoting it instead of the usual quoting (" ")*. What it does is to call a mixin template that will generate, for each element in the passed argument array a function that looks like:

{% highlight D %}

void visitDocument(ParseTree tree) {
	if (tree.name != "GraphQL.Document")
		return;
	visitNode(tree);
}
{% endhighlight %}


`visitNode` is a function already provided in the class, that is called by the generated code. This is gold as the number of types increases. Of course this is just a case, but it's infinite what you can do with mixin templates.

The frustration
---

It's not totally related to the language, which is awesome. Unfortunately the ecosystem is limited, there are pleny `0.*` version libs. I don't know why people fear to reach `1.0`. So it quickly became hard to see future when you need good integrations with existing Database, HTTP, IDE, etc.

They are trying. See [Vibed](https://vibed.org/) and [Eclipse DDT](https://github.com/DDT-IDE/DDT). But we need more than this for real projects with real money involved.

There is also a company kinda sponsoring DConf, that are clearly bringing some retarded ideology to the conference, what may put minorities privileges before technical skills. A huge risk for any sane evolution of the language and the ecosystem.

Then C++
---

Given that we need to build such a service that is almost invisible _due to it's performance requirements_, we simply jumped to C++. Got IDEs? Sure! [CLion is great](https://www.jetbrains.com/clion/). Got Libs? Well, it wouldn't fit here, but just take a look at [Boost](http://www.boost.org/) and [POCO](https://pocoproject.org).

What about package managers. Yest we have, see [Conan](https://www.conan.io/). Got Build Tool? Of course, dear: [CMake](https://cmake.org).

Ok ok, you need test libs, right? Here you have [Catch](https://github.com/philsquared/Catch) and [Google Test](https://github.com/google/googletest). Not only that, just check out the [Facebook open source projects](https://code.facebook.com/), most of them are pure C++ 11, or C++ 14.

I just use GCC, and haven't had time to try other compilers.

Conclusion
---

When you have real money involved, don't play. Not that we were kid playing or being reckless, we really believed we could go end to end using D, but so far it's not the case. In the end, one thing we won't be worried is performance (of course if we don't do shit in our code). D has Gc, and supposedly supports coding with it disabled, but lets try it another round.

