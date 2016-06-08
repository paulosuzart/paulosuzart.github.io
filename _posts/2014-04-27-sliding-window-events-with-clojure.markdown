---
layout: post
title: "Sliding Window events with Clojure"
date: 2014-04-27 19:44
comments: true
categories: [clojure]
---

Hello all, I'm back to [clojure](http://clojuredocs.org) posts again. :) 

I was looking for a sliding window processing of events. This is something very common in the world of [Complex Event Processing](http://en.wikipedia.org/wiki/Complex_event_processing) that can be roughly translated to querying events adding a time dimension to the query.

We can easily find some great products/libs namely: The excelent [Oracle CEP](http://www.oracle.com/technetwork/middleware/complex-event-processing/overview/complex-event-processing-088095.html), [Jboss Drools Fusion](http://drools.jboss.org/drools-fusion.html), [Esper](http://esper.codehaus.org/), and the very useful [Clojure Werkz](http://clojurewerkz.org/) [EEP, Embedded Event Processing](https://github.com/clojurewerkz/eep).

Excepting EEP, all the others are very complete. They offer a DSL so you can query and aggregate streams of events in a very intuitive manner. But I was looking for something veeeery simple like **EEP**.

EEP comes with some basic sliding window buffers. Be it based on size, be it based on time. The point with time based windows on EEP, is that they are basically a buffer waiting for some time to be elapsed before it sends all the entries to a handler. So in this case it is not so suitable for answering questions like: *"How much my e-commerce sold in the last 4 minutes?"*

To answer that, we can't accumulate events for 4 minutes, send all of the to a handler, and empty the buffer. If so, two subsequential queries to the buffer will return wrong values. Ex.:

{% highlight bash %}
|10 USD |10 USD , 20 USD | 10 USD , 20 USD                   | 0 USD
t0       t1               t3 "time elapsed, do empty buffer!"  t4
{% endhighlight %}

Suppose every `tn` is a minute elapsed. See? If time elapses at `t3` you `sum` and get 30, but if you want to know the  total sold one minute later, you get 0! It is not what I wanted. I then decided to go for my own implementation using [Meltdown](https://github.com/clojurewerkz/meltdown).

Meltdown is the clojure api for [Reactor](https://github.com/reactor/reactor), an async, message passing and stream processing lib. The concepts behind are very simple and if you tried something like [Go Channels](http://golang.org/doc/effective_go.html#channels), [core.async](http://clojure.github.io/core.async/) or [Pulsar](http://docs.paralleluniverse.co/pulsar/), there is no mistery. Just abstract the underlaying details and go writing code.

Ok, enough. Lets see some code (The comments in the code explains everything):

{% highlight clojure %}
;; Paulo Suzart 2014
;; Code to suport a blog post at paulosuzart.github.io
(ns melt.core
  (:require [clojurewerkz.meltdown.streams :as ms :refer [create consume accept reduce*]]
            [clojurewerkz.meltdown.stream-graph :as msg]
            [clojurewerkz.meltdown.reactor :as mr]
            [clojurewerkz.meltdown.selectors :refer [$ match-all]])
  (:gen-class))

; Holds the reactor that will receive a tick event every 1s
(def ticker (mr/create :event-routing-strategy :broadcast))

; Simply notifies the reactor the current time
(defn tick []
  (mr/notify ticker "tick" {:time (System/currentTimeMillis)}))

; Starts to pump to `ticker` reactor
(future
  (loop []
    (tick)
    (Thread/sleep 1000)
    (recur)))

; So far the idea is to have a global clock used to control what should
; be inside the sliding buffer.

; Cleans the buffer if the event data arrived before the current time 
; minus the sliding interval
(defn buffer-cleaner [buff interval]
  (let [event-time (System/currentTimeMillis)
        slide (- event-time interval)]
     (filter #(> (:event-time %) slide) buff)))

; Here goes the core stuff
(defn slide [& opts]
  (let [options (apply hash-map opts)
      ; Channel used to dictate the steps taken
      ; by the slide window 
        ticker-chan (:ticker-chan options) 
      ; Channel that actually receives events 
      ; like amount sold
        source-chan (:source-chan options)
      ; Selector used to grab events from the source-chan
        selector (:selector options)
      ; The window you are interested in. 
      ; Say 5 seconds. It is milisec.
        interval (:interval options)
      ; In this case, the ticker will also 
      ; triggers a handler function. 
      ; For example, a function that sums up the amounts sold
        handler (:handler options)
      ; The buffer holding the events being slided.
        buff (ref [])]
    ; Invokes handler with the current buffer content
    (mr/on ticker-chan ($ "tick") 
      (fn [e] 
        (handler (map :event-data @buff)))) ;processes the handler
    ; Adds a new evet data to the buffer. 
    (mr/on source-chan selector 
      (fn [e] 
        (dosync 
          (alter buff conj {:event-data (:data e) 
                            :event-time (System/currentTimeMillis)}))))
    ; On the tick of the ticker, clean up old non-relevant data.
    (mr/on ticker-chan ($ "tick")
      (fn [_] (dosync 
                (ref-set buff (buffer-cleaner @buff interval))))))) 

; The reactor that holds 
(def prices (mr/create))

(slide :ticker-chan ticker 
       :source-chan prices
       :selector (match-all)
       :interval 5000
       :handler (fn [b] (println "Last 5 seconds earnings " 
                  (apply + b) (System/currentTimeMillis))))

;; just for testing:
(defn add-prices []
  (mr/notify prices "camisa" 20)
  (Thread/sleep 2000)
  (mr/notify prices "chapa" 30)
  (Thread/sleep 2000)
  (mr/notify prices "tenis" 20)
  nil
)
{% endhighlight %}

I could have embedded the ticker channel in the `slide` function. Or it could be a record implementing some protocol, etc. But this is quite simple and enough for now.

There is no mistery, but for sure the combination of Meltdown's clean interface plus clojure's ability to handle concurrency make this type of construction very straightforward.

Notice, however, that bigger your window interval, bigger your buffer. Faster you add events to the `price` reactor, faster your buffer becomes bigger. Seems no problem for the power of Reactor.

Tha is all. CEP is very useful in the filds of pattern/behavior detection and real-time analysis for detecting fraud, etc. It pays off to study and find opportunities to provide smart solutions using it.


Cheers!	



