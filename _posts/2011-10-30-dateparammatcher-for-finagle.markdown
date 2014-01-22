---
layout: post
title: "DateParamMatcher for Finagle"
date: 2011-10-30 23:22
comments: true
categories: scala
---

[Twitter Finagle](http://twitter.github.com/finagle) is an amazing framework for RPC communication, and my interest is its HTTP features for creating RESTful APIs.

As I bloged at [codemountain](http://codemountain.wordpress.com/2011/10/14/twitter-finagle-primeiras-impressoes/), I'm using finagle for a personal project. Don't know how far it will go, but the facts is that I'm learning Finagle a lot.

During this project I needed to extract from the query string, a param to be parsed to a twitter.util.Time. I ended up with a Param Matcher to be used my a pattern match agains the requested path. The use of this Param Patcher is:

``` scala Using the DateParamMatcher
//...
Path(request.path) :? request.params match {
       case Root / "myPath" :? RequestTime(requestTimeParam)  => //do something
//..
}
//Where RequestTime is defined as
 object RequestTime extends DateParamMatcher("requestTimeParam")
```
The source of DateParamMatcher is the following.
``` scala Param Matcher for twitter.util.Time
import com.twitter.util.Time._
import com.twitter.util.Time
import java.text.ParseException
import com.twitter.finagle.http.path._
import com.twitter.finagle.http.ParamMap

/**
 * Extractor that takes a request parameter and converts it to a {twitter.util.Time}.
 * The date format should conform with {twitter.util.Time} default format.
 */
abstract class DateParamMatcher(name: String) {

  def unapply(params: ParamMap): Option[Time] = params.get(name) flatMap { value =>
    try {
      Some(at(value))
    } catch {
      case ex: ParseException =>
        None
    }
  }
}

```
Finagle also provides an abstract `com.twitter.finagle.http.path.ParamMatcher` as well as `LongParamMatcher` and `IntParamMatcher` in the same package. They are actually Scala  Extractors (very well explained [here](http://codemonkeyism.com/scala-goodness-extractors/) by @codemonkeyism). This is a practical way to extract values from a query string and put it available at your code already parsed. 

Note that if the param named `requestTimeParam` is not present or carries a invalid value for `Time` in the query string the `None` value is returned.

Although easy to build and extract params from query string and requested path, it is not a Finagle strength. It is kinda limited. A better abstraction is offered by [Unfiltered](https://github.com/unfiltered/unfiltered)(another [@n8han's](http://twitter.com/n8han) great job).

Hope you enjoy it.

