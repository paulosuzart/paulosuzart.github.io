---
layout: post
title: "Removing dockerhub tags with racket"
date: 2017-11-27 18:00
comments: true
categories: [ docker, racket ]
---

Believe it or not the most viewed blog post of all times is [Why Racket is Awesome](http://paulosuzart.github.io/blog/2015/04/02/why-racket-is-awesome/) written in 2015. I also don't understand why that dense post is the top one. And to boost the interest for [Racket](racket-lang.org), I've decided to implement a small simple utility to prune [Docker](https://www.docker.com/) tags. This way we keep only the most recent `k` tags. Let's check it out.

<!--more-->

# Why this utility?

It is not uncommon to have tags pushed to dockerhub and after some time, you have dozens if not hundreds of old tags hanging around. You could do this cleanse in many ways, including manual deletion. But wheres is the fun of being a programmer if you have to do things by hand?

This utility is extremely simple and use no extra dependencies. And as a plus, at the end of the code walk-through you'll be able to run this tool using docker itself so you don't have to setup Racket in our machine.

# The code: Lazyness

Again, there are thousand ways to implement this. I tried to use the concept of streams to grab all tags in a repo. You could have implemented it with lists of lists, etc.

So the smallest piece of code to implement our lazy stream of tags is a function that takes some repository information and the page it wants to fetch from DockerHub:

``` clojure
(define (fetch-tags user repo token page)
  (let* ([uri (string->url (format "https://hub.docker.com/v2/repositories/~a/~a/tags/?page=~a" user repo page))]
         [in (get-pure-port uri (with-auth-header token))]
         [tags-result (read-json in)])
    (displayln (format "https://hub.docker.com/v2/repositories/~a/~a/tags/page=~a" user repo page))
    tags-result))
```

Nothing special here. `fetch-tags` is as blind as: gimme the user, the repostory, a valid JWT Token and I'll fetch the `page`. It is possible to increase the page size while fetching tags, but let's keep it like this. So, to fetch page 1 we could just do a `(fetch-tags "some-user" "some-repo" "some huge token..." 1)` and it is supposed to return the response body from this endpoint as a Racket [hash](https://docs.racket-lang.org/reference/hashtables.html).

To achieve a lazy stream of tags, where the tags are fetched at page size and then made available for further processing, one can use a [`case-lambda`](https://docs.racket-lang.org/reference/lambda.html#%28form._%28%28quote._~23~25kernel%29._case-lambda%29%29) function that
on missing the page to fetch, it assumes the value `1` and if the page fetched got a `next` key, it lazy append. And if page present, it appends the next stream using `stream-append`, in this case adding 1 to the current page loaded.

``` clojure
(define tags
  (case-lambda
    [(user repo token) (tags user repo token (format "https://hub.docker.com/v2/repositories/~a/~a/tags/" user repo))]
    [(user repo token page)
     (if (equal? 'null page)
         empty-stream
         (let* ([tag-result (fetch-tags user repo token page)]
                [results (hash-ref tag-result 'results)])
           (stream-cons (first results) 
                          (stream-append
                            (rest results)
                            (tags user repo token (hash-ref tag-result 'next))))))]))
```

`case-lambda` works the same way clojure's multi arity function works. The function is applied according to the number of arguments, although a also interesing option with pattern-match support is available: [`match-lambda`](http://docs.racket-lang.org/reference/match.html?q=lambda-match#%28form._%28%28lib._racket%2Fmatch..rkt%29._match-lambda%29%29). But for our use case, `case-lambda` is enough.

To produce a lazy stream, we need to combine `(stream-cons first-expr rest-expr)` that evaluates `first-expr` as the first element of the produced stream, thus `(first result)`, and the append of two other streams: `(rest results)`, that is the tail of the first batch of tags, and whatever stream the next call will bring `(tags user repo token (hash-ref tag-result 'next))`: 

If you run this against a fair big repo, you would notice that the pages are fetched as tags are removed. **But this is actually a problem, because if we start deleting tags, fetching next pages will bring a already prune list of tags**. So keep this part as a learning purpose and lets force the evaluation of our stream like this:

``` clojure
(let* ([token (authenticate (username) (password))]
       [tags-stream (tags (username) (repository) token)])
  (prune (username) (repository) (stream->list tags-stream) (keep) token))
```

The function `stream-list` will take care of fetching everything before we move to the `prune` function that still uses stream semantics, but we are safe with the whole tags lists:

``` clojure
(define (prune user repo tags-stream keep token)
  (define tags-to-delete 
    (for/stream ([tag tags-stream]
                 [index (in-naturals 1)]
                 #:when (> index keep))
      tag))
  (stream-for-each
   (λ [tag]
     (displayln (format "Prunning tag ~a" (hash-ref tag 'name)))
     (delete-tag user repo (hash-ref tag 'name) token))
   tags-to-delete))
```

If our intention was to do something else with the stream of tags, we are likely to keep it lazy, but drop tags requires us to fetch everything before we move on.

The Racket function `drop`, `take` and stream counterparts (like `list-tail`) raises a exception if you try to take (or drop) more elements than it is available in the stream. This is unfortunate because the code above could be simpler. In this case my solution - to avoid checking stream length - was to use `for/stream` and bind a index to a element of our tags stream while iterate through then. And to skip the `k` amount of tags to be kept the `#:when` guard is used.

# Running

You can clone this source code from git [paulosuzart/prunedocker](https://github.com/paulosuzart/prunedocker). Or simply:

`docker run paulosuzart/prunedocker -u youruser -p yourpass -r a_repo -k 20`

This way you don't have to setup anything in your machine (except for Docker). Also bear the repository code is slightly different from te blog post code to hold a more didactic form.

The Dockerhub repo is [paulosuzart/prunedocker(https://hub.docker.com/r/paulosuzart/prunedocker/).


# Conclusion

In the Racket API `list-tail`, and its stream counterpart [`stream-tail`](https://docs.racket-lang.org/reference/streams.html#%28def._%28%28lib._racket%2Fstream..rkt%29._stream-tail%29%29), both presumes a known length. That is:

``` clojure
; racket will give you an exception for this:
> (take '(1 2 3) 5)
; take: index is too large for list
;   index: 5
;   list: '(1 2 3)
; [,bt for context]

; clojure will give you the maximum it can get from the list:
user=> (take 5 '(1 2 3))
(1 2 3)
```
Don't have any idea why Racket guys implemented this API like this. 

Another strange Racket API is the very raw `[net/url]`(https://docs.racket-lang.org/net/url.html) module. In order to avoid extra dependencies it is better to stick with it, but there are richer libs available like [http](https://docs.racket-lang.org/http/index.html?q=http). Maybe this is the intention, to form just the basis to build more on top.

All in all the implementation is simple and required me some time to refresh my mind on Racket and lisp like constructs. 

Hope you have enjoyed. Happy Racket!