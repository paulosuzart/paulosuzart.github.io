---
layout: post
title: "Dependent Types And Safer Code"
date: 2017-06-18 13:22
comments: true
categories: [programming, idris, fp]
---

I've recently joinned a [Discord Functional Programming Server](https://discordapp.com). No, it is not a framework for developing servers using functional programming languages. Instead, a mix of IRC and Slack for discussing several functional langs. If you want to watch and participate in nice discussion and tips about clojure, elixir, elm, erlang, haskell, idris, lisp, ocaml, racket, and scala, join the server [right here](https://discord.gg/jeaFVYE).

I'd heard about [Idris](idris-lang.org) long ago, but after joining this server I was surprised by a very active channel, the #idris channel. And one of the latest messages presented a [gist](https://gist.github.com/chrisdone/672efcd784528b7d0b7e17ad9c115292) with Type Dependent `printf` function. At first may sound like a silly thing, but that was a nice opportunity to expand my mind around Type Dependent code beyond what is taught in the [Idris Tutorial](http://docs.idris-lang.org/en/latest/tutorial/index.html).

<!--more-->

In the gist you see the defintion of `printf`:

{% highlight haskell %}
  -- ...
  -- More code before this line, check the original gist
  printf : (s : String) -> interpFormat ( formatString s )
  
  -- Add a main here to show something. Continue reading
  main : IO ()
  main =  printLn $ printf "%d%s" 5 "hello!"
  -- outputs
  -- "5hello!" : String

{% endhighlight %}

As you can see, `printf` takes a `Int` and a `String` as argument *(besides the formating pattern as first `String` arg)*. But what you actually read is this function taking a formatting pattern and another parameter of type `interpFormat ( formatString s )`. Crazy hun?

This is the power of Idris Dependent Types playing here. At compile, all the next parameters are calculated by applying a sucession of functions to `s`, the formatting pattern. This is possible because types and values are both first class citzens in this lang. Thus, the combination of `interpFormat` and `formatString` have the intention to form a mini AST (Abstract Syntax Tree) of types according to this sum recursive type:

{% highlight haskell %}
data Format
  = FInt Format
  | FString Format
  | FOther Char Format
  | FEnd
{% endhighlight %}

Pay attention to Format making reference to itself. So, having `%d%s` as pattern, computes a `Format` containing (*not sure if 'containing' is the best expression to explain this*) a `Int String FEnd`. This is then interpreted by `interpFormat` that produces the arity and input types of `printf`. In this case `Int -> String -> String`. Amazing! 

If you clone the gist, add a main method and try to run `printf "%d: %s" "woops" 6` the code won't compile, printing a sounding error:

{% highlight bash %}
Printf.idr:52:17-18:When checking right hand side of main with expected type
        IO ()

When checking an application of function Prelude.Interactive.printLn:
        Type mismatch between
                String (Type of "woops")
        and
                Int (Expected type)
Holes: Printf.main
{% endhighlight %}

It is not a uncommon situation. Take for example clojure (*WARN: I'm not comparing languages nor saying one is better than the other*) and try the following code:

{% highlight clojure %}

(defn p [v] (format "%5d" v))
(p 1)
"    1" ;; printed ok

(p "3")

IllegalFormatConversionException d != java.lang.String  java.util.Formatter$FormatSpecifier.failConversion (Formatter.java:4302)
(format "%5d" "d")
IllegalFormatConversionException d != java.lang.String  java.util.Formatter$FormatSpecifier.failConversion (Formatter.java:4302)

{% endhighlight %}

All you have is runtime error. Don't be decived. You may be tempted to believe this is happening because clojure is dynamic, no compile involved. Let's try this with Java for example:

{% highlight java %}
class Main {

  public static void main(String[] args) {
    final String out = String.format("%s = %d", "joe", "#");
    System.out.println(out);
  }

}

{% endhighlight %}

Yes, the code above compiles! And when you run it you get `Exception in thread "main" java.util.IllegalFormatConversionException: d != java.lang.String`. The beautiful exception named `IllegalFormatConvensionException` derives from `RuntimeException`, what of course makes it impossible to bd detected at compile time.


Conclusion
---

At first I was too skeptical to even try Idris and all this Dependent Type thing. But it is useful and may produce more flexible and safer software. There are other languages that explore compile time programming like [D](https://github.com/dlang), but this is single and much more powerful.

Another side note on Idris (*Actually its documentation*) is how light and smooth they present the concepts, examples, etc. You end up filling you've learned a bit more of Haskell with out the heavy explanations of any Haskell tutorial out there.

Happy Idris!