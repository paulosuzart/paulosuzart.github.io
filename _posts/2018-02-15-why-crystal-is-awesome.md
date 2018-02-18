---
layout: post
title: "Why Crystal Is Awesome"
date: 2018-02-15 14:00
comments: true
categories: [ docker, crystal ]
---

Few months ago posted again about [Racket](http://racket-lang.org) and created a simple cod to [remove docker tags from Dockerhub using this language](http://paulosuzart.github.io/blog/2017/11/27/removing-dockerhub-tags-with-racket/). This time We'll do the same but using [Crystal Language](https://crystal-lang.org) as a background to talk about this language.

<!--more-->

I'll follow the same post structure as shown in the ["Why Racket is Awesome"](http://paulosuzart.github.io/blog/2015/04/02/why-racket-is-awesome/) post and add some more stuff here and there. Let's begin. Bear it is not an exhaustive analysis or any official promotion of the language, it is just my opinion.

# How I started looking at it

Years ago a friend of mine mentioned about but I didn't pay that much attention. The only thing a kept around my mind was: **"Fast as C, slick as Ruby"**. After working with [Groovy](http://groovy-lang.org/), [Python](https://www.python.org/) and Javascript, in the last year we decided to use [Typescript](https://www.typescriptlang.org) as we missed types.

Typescript is awesome and I have few complaints. Then as a good programming language lover, I started to look at Crystal again specially after learning about the existence of [Lucky](https://luckyframework.org), a astonishing web framework in Crystal. I even started to collaborate with issues and even with a Pull Request. Also joined the community at [Gitter](https://gitter.im/luckyframework/Lobby).

# What I've found

The language itself has a pretty [good documentation](https://crystal-lang.org/docs/). Racket still excels on this area but Crystal offers fair enough documentation to start right away. Give it a try!

The **installation** is also easy and the binaries produced by the language wraps everything, like [go](https://golang.org/), that also produces a single executable binary.

The compiler is super smart and supportive:

```
instantiating 'Prunedocker::Prunedocker#run()'
in src/prunedocker.cr:30: instantiating 'Prune#run()'

      prune.run
            ^~~

in src/prunedocker/prune.cr:86: undefined local variable or method 'setsings' (did you mean 'settings'?)

    puts "This is a dry run. Would delete the tags #{tags_to_delete.join(' ')}" if setsings.dry
                                                                                   ^~~~~~~~
```

It suggests that I could be actually trying to use `settings` (that is really in the context), not `setsings`.

**Dependency management** is done via `shards`. More details int he [shards section](https://crystal-lang.org/docs/guides/writing_shards.html) of the documentation. It is supper simple and requires no central repository as it clones tags or branches straight from github, for example. Even so, there is a pseudo central repository that lists possible all available shards (or libs as we say): [crystalshards.xyz](https://crystalshards.xyz/).

**IDE support is limited** now, but slightly fulfilled by a good compiler. Although look like ruby, you can trust defective code won't be delivered anywhere without compiling correctly. The `crystal tool format` also helps ensuring good and standardized format for your code.

Crystal is **backed by a GC**, so no memory management in your way. Nevertheless, by the time writing, it has no support for multiple cores like other good options out there (Node.js or Python for example). I mean the language support [concurrency](https://crystal-lang.org/docs/guides/concurrency.html) but if you need to scale out in the same server, you are going to need more instances of your process running. If I understood right, they must add support for multiple cores at some point.

**Testing** is so nice to read and write using the provided [Specs module](https://crystal-lang.org/docs/guides/testing.html) making you almost trully believe you are using a dynamic, not statically typed language.

**Types everywhere, although hidden most of the time** is a clear message to more bloated languages, when it comes to annotating types, that things can be practical yet powerful with generics, union types, etc.

Few **macro systems** are clearer and simpler as the one [offered by Crystal](https://crystal-lang.org/docs/syntax_and_semantics/macros.html). Even `method_missing` is available.

Stack [allocated Structs](https://crystal-lang.org/docs/syntax_and_semantics/structs.html) allows some extra precise control of memory allocation.

Compile time is important and hope over time it gets faster. Not so bad, though.

# What now?

I wish I can put something to production using Crystal. In the mean time, lets play with it.

The code below, that can be fully accessed in this [github repo](https://github.com/paulosuzart/prunedocker-crystal) prunes a Dockerhub repo by keeping just the latest `k` tags in the repository. It is the same goal of the post [Removing Dockerhub tags with Racket](http://paulosuzart.github.io/blog/2017/11/27/removing-dockerhub-tags-with-racket/), but now in Crystal!!!!

The code is so easy to read because there are much less symbols involved. Less `()`, less `,` and absolutely no `;`. Furthermore the semantics for class methods and instance variables makes things pretty clear. This code uses a http client as a class method, that is why you see a `@@` here for instantiating it and also setting up the authentication process. The `authenticate` method por example, is static, thus we use `self.authenticate` to point it out.

``` ruby
BASE_URL   = "https://hub.docker.com"
LOGIN_PATH = "/v2/users/login/"

class Prune
  @@token : String?

  Habitat.create do
    # assume habitat config here
  end

  def initialize
  end

  @@client = HTTP::Client.new URI.parse(BASE_URL)

  @@client.before_request do |request|
    if request.path != LOGIN_PATH
      @@token ||= authenticate
      request.headers["Authorization"] = "JWT #{@@token}"
    end
    request.headers["Content-Type"] = "application/json"
  end

  private def self.authenticate
    payload = JSON.build do |json|
      json.object do
        json.field "username", settings.user
        json.field "password", settings.password
      end
    end

    @@client.post LOGIN_PATH, body: payload do |response|
      raise InvalidCredentials.new if response.status_code != 200
      JSON.parse(response.body_io)["token"].as_s
    end
  end

  # Simply fetches tags yielding on each page
  private def fetch_tags
    path = "/v2/repositories/#{settings.user}/#{settings.repository}/tags/"
    loop do
      response = @@client.get path
      tags_payload = JSON.parse(response.body)

      yield tags_payload["results"]

      path = tags_payload["next"].as_s?
      break unless path
    end
  end

  private def delete(tags_to_delete)
    # delete body here
    end

  def run
    tags = [] of String

    fetch_tags do |result|
      tags += result.map &.["name"].as_s
    end

    delete_from = tags.size - (tags.size - settings.keep)
    tags_to_delete = tags.delete_at(delete_from..tags.size)
    delete tags_to_delete unless settings.dry

  rescue e
    # other rescues omitted for brevity
    puts "Unknown error #{e.message}"
  end
end
```

The native http client of the language is super flexible and powerful as you can see in the section:

``` ruby
  @@client.before_request do |request|
    if request.path != LOGIN_PATH
      @@token ||= authenticate
      request.headers["Authorization"] = "JWT #{@@token}"
    end
    request.headers["Content-Type"] = "application/json"
  end
```

On every request this kinda *middleware* will be invoked and take care of authenticating the user. The construct `@@token ||= authenticate` is super clever. It tries to use the class method (a static variable of the class) and if it is not set yet, it sets it's value with the result of `authenticate` call.

Another nice construct is:

``` ruby
    tags = [] of String
    fetch_tags do |result|
      tags += result.map &.["name"].as_s
    end
```

The `fetch_tags` method yields a list of tags for every page. Our goal is to accumulate just the names of the tags in the `tags` variable. All we can do is concatenate the extraction of the name that is made by `result.map &.["name"].as_s`. The `map` method takes a block as argument and Crystal offers this short version of sending a block as parameters. What `&.["name"].as_s` does is take what ever value yielded by map and call `["name"].as_s` on it. Tasty!

There are much more interesting ways to express things as you can find in the Lucky framework. All powered by useful macros and blocks.

# Conclusion

Crystal is just `0.24.1` right now. There is a long road ahead for sure. It couldn't be more promising. With a growing community, type safety and speed of C, languages like Go or Rust will have to rethink themselves in some areas at least.

I always refused to use ruby due to it's performance. That was a pity because it has the same constructs Crystal offers, but now it seems time is coming where we have cool, slick, readable code like ruby with the speed of Crystal.

Happy Crystal!