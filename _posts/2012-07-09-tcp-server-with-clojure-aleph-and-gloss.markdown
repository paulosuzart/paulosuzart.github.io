---
layout: post
title: "TCP Server with Clojure Aleph and Gloss"
date: 2012-07-09 11:57
comments: true
categories: clojure
---

Hi Ho! Its been a long time without writing here. As you might know, I've just launched a new web/mobile [(Guiato)](http://www.guiato.com.br) platform to help retailers reach their customers with their existing brochures/pamphlets/flyers but now, electronically.

It was as a 4 months adventure, including 20 days in Germany to plan and bring all the platform to Brazil. But now it is time to clojure a bit more. And we are just beginning.
<!--more-->
My team and I have a simple google docs with amazing funny statements - or facts - we say. But it is too much sophisticated, so I decided to write our own system (Clacts) to register and read this facts using [Clojure](http://clojure.org), [Aleph](https://github.com/ztellman/aleph/wiki) as TCP server, [Gloss](https://github.com/ztellman/gloss/wiki) for encoding/decoding messages and [SQLite](http://www.sqlite.org/) for storing facts. Amazing! Isn't it? :) Well at last it was funny.

I started creating a very simple protocol to allow clients to connect via telnet. So it is:

{% highlight bash %}
PUT <author> <via> <fact>
LSA <author>|*
{% endhighlight %}

We have two main commands, `PUT` and `LSA`. For `PUT`, author is the guy speaking, via is who noted it, and the fact is the statement itself. And for `LSA` command, you can pass the author's name and the system will return all the facts spoken by the author. `*` means you want to read all the facts.

Any other command will be handled as error. Enter Gloss, a lib that allows you to draw how sequence of bytes will be converted to clojure data structures, and how clojure data will be converted to byte sequences. Here is the definition of Clacts the protocol:

{% highlight clojure %}

(def p (string :utf-8 :delimiters " "))
(def lp (string :utf-8 :delimiters ["\r\n"]))

(defcodec PUTC ["PUT" p p lp])
(defcodec LSAC ["LSA" lp])
(defcodec REPC ["REP" lp])
(defcodec LSRC ["LSR" (string :utf-8 :suffix " ")
                      (string :utf-8 :suffix " ")
                      (string :utf-8 :suffix " ")
                      (string :utf-8 :suffix "\r\n")])

(defcodec ERRC (string :utf-8))

(defcodec CMDS
  (header
    p
    (fn [h] (condp = h
    	"PUT" PUTC
    	"LSA" LSAC
    	"REP" REPC
    	"LSR" LSRC
    	ERRC))
    (fn [b] (first b))))

{% endhighlight %}

Gloss uses the concept of frames and codecs to model your bytes. As a shortcut, i'm using `p` and `lp` to identify parameters ended in `" "` and parameters ended in `\r\n`. That is, `p` and `lp` are frames that will be converted to strings, with UTF-8 encoding.

Given the building block frames `p` and `lp` we can start to form the commands. We have `PUTC`, a codec that is composed by the word `PUT` plus two `p` frames and one `lp` frame. So this: `PUT Agustinho Brisola Estou acostumado a criar my propria cloud`, will be converted to: `["PUT" "Agustinho" "Brisolla" "Estou acostumado a criar minha propria cloud"]`. Bang! We have bytes straight to a clojure vector. And testing it is pretty straight forward. Look:

{% highlight clojure %}
(use 'gloss.core 'gloss.io)
(import java.nio.ByteBuffer)

(def buffer (java.nio.ByteBuffer/wrap (.getBytes "PUT Agustinho Brisolla Teste Fact\r\n")))

(decode PUTC buffer)

;; ["PUT" "PUT" "Agustinho" "Brisolla Teste Fact"]

{% endhighlight %}

There are actually more codecs (`REPC` and `LSRC`) to handle generic responses and `LSA` responses respectively. But once you understand the commands, the answers are natural consequences.

Hell yeah! Neat and handy. But clients can actually use different commands, how to understand which command to decode an handle appropriately?

For these cases (and others for sure) Gloss allows you to define a `header`, which is some part of the frame that behaves as an indicative for the rest of the frames. In this case, look to the codec `CMDS`. It is composed by a header that, depending on its content, indicates the other commands.

The `head` function is a bit strange at first, but once you get it, you can go really far. `head` takes 3 args, *(i)* its own frame, *(ii)* a function that given the header it points to the right codec for the rest of the message, and *(iii)* another function that given the body of a frame, extracts the value of the header. Easy?

Take `PUT Agustinho Brisolla Teste Fact\r\n` command as an example. `PUT` is extracted by this `string` calling `frist` on it. This is the function that maps the body to header. And given the header, that is a `p` (the first string separated by space), I check its value and return the appropriate codec: `PUTC`.

Note the default value for `ERRC`. This is for the cases where some smart user types an unknown command.

Great, but we have to handle the requests coming from telnet clients. Now it is Aleph time:

{% highlight clojure %}

(defn handler
  "TCP Handler. Decodes the issued command and calls the appropriate
  function to excetion some action."
  [ch ci]
  (receive-all ch
    (fn [b]
      (let [deced (decode prt/CMDS b)]
        (println "Processing command: " deced)
        (condp = (first deced)
          "PUT" (put-fact (rest deced) ch)
          "LSA" (list-facts (second deced) ch)
          (handle-err ch ci))))))

(start-tcp-server handler {:port 10000})

{% endhighlight %}

When you start the tcp server without defining the frame to handle, Aleph delivers to the `handler` a series of `ByteBuffers`, what is perfect for this case. The handler function decodes the frames against the `CMDS` codec and calls the correspondent function passing as argument the channel to respond to.

Not that there is a default function - `handle-err` being called in case of unknown commands. It will respond to clients random error messages.

The functions to list and put facts into the database use the same `CMDS` codec to encode reply messages. Look:

{% highlight clojure %}

(defn put-fact
  "Inserts the fact into db according to proto/PUTC.
  Takes the decoded data end the channel to respond."
  [data ch]
  (with-connection db
    (insert-record :facts
      {:date   (str (System/currentTimeMillis))
       :author (first data)
       :via    (second data)
       :fact   (last data)}))
  (enqueue ch (encode prt/CMDS ["REP" "Fact recorded!! Have fun with it."])))

{% endhighlight %}

`REP` is a command encoded by `REPC` codec as defined above. The codec is defined by the header of the message (`REP`). What is pretty useful and saves your from using `if` to do that.

You may argue: "Why not use HTTP/Restful thing?" And I say: because this is more fun :)

You can find the full project on my github: [https://github.com/paulosuzart/clact](https://github.com/paulosuzart/clact). There you can see more details regarding interacting with SQLite, that wasn't covered here.

UPDATE 2012/08/03
=================
The great brain [@ztellman](http://twitter.com/ztellman), the creator of gloss, gave me a hand [pulling](https://github.com/paulosuzart/clact/pull/1) some changes in the code. What he suggested was to specify the frame for the server. So Aleph takes care of the protocol being encoded/decoded and you interact solely with clojure data structures. The change was:

{% highlight clojure %}
(start-tcp-server handler {:port (:port opts), :frame prt/CMDS})

;;what leads us to check for commands like this:

(receive-all ch
    (fn [cmd]
      (println "Processing command: " cmd "From " ci)
      (condp = (first cmd)
        "PUT" (put-fact (rest cmd) ch)
        "LSA" (list-facts (second cmd) ch)
        (handle-err ch ci)))))

;; instead of the previous version manually decoding bytes:

(receive-all ch
  (fn [b]
    (let [deced (decode prt/CMDS b)]
      (println "Processing command: " deced)
      (condp = (first deced)
        "PUT" (put-fact (rest deced) ch)
        "LSA" (list-facts (second deced) ch)
        (handle-err ch ci))))))

;;the same applies for sending response back to the client:

(enqueue broad-put ["REP"
                    (format "####Fact recorded by %s!! By %s: %s."
                     via author fact)]))

;; no need for manual encoding :)
{% endhighlight %}

This is great because the best thing on every clojure lib is use pure clojure data structures to keep things uniform.

Thanks to Zach for the precious tips.
