---
layout: post
title: "Going back to Go (golang)"
date: 2014-07-07 13:44
comments: true
categories: [golang]
---

Intro
=====

Hi people, a while ago I made a clear expression of my kinda frustration with clojure ecosystem in the clojure mailling list. I'm not going to share the link here because my post it self was confusing and answers even more. 

In sumarry the furstration comes from TOO TOO TOO MUCH '[ANN]' posts on the list as if it was open source and more specifically, few of them are really bringing value to clojure as other languages have strong libs/tools.

Ok, lets move on. Back in 2011 I wrote a very simple tool for called [gb](https://github.com/paulosuzart/gb) just for the sake of learning [Go](http://golang.org). In the end it is quite good code and useful if you want to build and use id. It is inspired by [Apache Benchmark](http://httpd.apache.org/docs/2.2/programs/ab.html) with less features.

After that, I stopped with Go and went deep in clojure. But the destiny brought me back to Go (I can write about later). I could write a lot about Why Go, but you can find good [articles](http://nathany.com/why-go/) and [videos](http://www.gophercon.com/speakers/) out there. In summary I would say:

   - Native clean [concurrency](http://www.golang-book.com/10/index.htm): Golang routines and Channels are amazing abstractions for writing concurrent code, making your brain free to mix and match your logic instead of haveing it busy with concurrency challenges.
   - Pragmatic - Go has no method overloading, no interface implementation keyword (just write the same methods defined in a interface and you are done), no reserved words for public/private/etc (low case for private, upper for public functions and attributes).
   - [Pointes and references](http://spf13.com/post/go-pointers-vs-references) - This will meke things even faster with lesse copies between invocations, etc.
   - Single binary - No classpath, etc. Build your code in a single binary file with no dependecies. It is just an executable.
   - Simple - The language itself is very simple. Easy to understand specially if written by others.
   - Backed by Google - I used to have more crazy times when I would use anything (including any lib announced ain a '[ANN]' post in a mailing list), but it is not sustainable. No maintanance, no support, no clear future are few characteristics of this type of lib. Share code on Github is not open source. Go is backed by Google, what makes it with longer and responsible life.
   - Performance - Golang is super fast. See [this comparison](http://www.techempower.com/benchmarks/#section=data-r9&hw=peak&test=json&s=2&l=co4&p=3s-0&w=trv3) for example.

What Am I doing?
================

I'm writing some kind of tracking system build with [go standard lib](http://golang.org/pkg/, [Gorilla HTTP Toolkit](http://www.gorillatoolkit.org/) and [BoltDB](https://github.com/boltdb/bolt). I'll not share any of my code now, hope I can share the whole tool that is 60% done and evolving fast.

BoltDB is *"pure Go key/value store"* with the goals of providing *"a simple, fast, and reliable database for projects that don't require a full database server such as Postgres or MySQL"*.

I hit BoltDB while learning about [Implementing a Key Value Storate](http://codecapsule.com/2012/11/07/ikvs-implementing-a-key-value-store-table-of-contents/). It is a very interesting topic but I have no time - and possibily no brain - to implement mine. I then went for a simple persistent queue (like (Kestrel)[https://github.com/twitter/kestrel]), but I made the favor to myself of `rm -rf` my source code folder that had n git. Ok, it is already overtaken :(

These days, [@BoltDB](https://twitter.com/boltdb) shared with me a [interesting benchmark](https://gist.github.com/benbjohnson/91b05a83f6668e3baeab):

{% highlight bash %}
# Sequentially insert 1M key/value pairs (in 1000 record batches).
$ bolt bench --count 1000000 --batch-size 1000
# Write 3.939999671s  (3.939us/op)  (253871 op/sec)
# Read  1.003326413s  (40ns/op) (25000000 op/sec)
 
---------
 
# Randomly insert 1M key/value pairs (in 1000 record batches).
$ bolt bench --count 1000000 --batch-size 1000 --write-mode rnd
# Write 56.84787703s  (56.847us/op) (17591 op/sec)
# Read  1.010560605s  (42ns/op) (23809523 op/sec)

{% endhighlight %}

If in the end can reach half of such throughtput after adding some logic on top fo BoltDB, I'll many times more than enough.

Just to not have a blog post without code. Lets take a look at sample extracted from real code:


{% highlight go linenos %}

type BoltStorage struct {
  DB         *bolt.DB
  writerChan chan [3]interface{} //not so agnostic but enough now
}

func (this *BoltStorage) writer() {
  for data := range this.writerChan {
    bucket := data[0].(string)
    keyId := data[1].(string)
    dataBytes := data[2].([]byte)
    this.DB.Update(func(tx *bolt.Tx) error {
      sesionBucket, err := tx.CreateBucket([]byte(bucket))
      if err != nil {
        // TODO: Handle instead of panic
        panic(err)
      }
      sesionBucket.Put([]byte(keyId), dataBytes)
      return nil
    })
  }
}

func NewBoltStorage(dbPath string) *BoltStorage {
  db, err := bolt.Open(dbPath, 0666, nil)
  writerChan := make(chan [3]interface{})
  boltStorage := &BoltStorage{DB: db, writerChan: writerChan}

  go boltStorage.writer()
  if err != nil {
    panic(err)
  }
  return boltStorage
}

writerChan <- [3]interface{}{"3212123", "1478812031", data}

{% endhighlight %}


Notice that there is a single channel consumed by a go routine. This is the guy that will interact with BoltDB. I'm also using keys that can be ordered while using `ForEach` to iterate over a Bucket of tracked data.

Notice how simple it is to create a go routine at the line `28`. And even more easy it is to create a channel at at line 25 and consume it 7.

Ok, hope I can finish this project as soon as possible so I can share more thoughts and lessons.

Cheers!	



