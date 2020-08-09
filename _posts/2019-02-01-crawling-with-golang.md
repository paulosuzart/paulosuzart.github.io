---
layout: post
title: "Crawling with Golang and Neo4j"
date: 2019-02-01 10:32
comments: true
tags: [golang]
---

[Golang](https://golang.org/) long ago [fascinated me](https://github.com/paulosuzart/gb). It was fun time and I tried to use in many personal projects and could never do anything serious at work. But this finally changed!

One of the libs we are heavily using is [Colly](http://go-colly.org/). Let's take a look on what it can do for us an add a Graph database to the mix.

<!--more-->

# Why the heck another crawler?

Crawlers are almost a _cliché_ nowadays. And it's often used to grab data from third party websites/APIs and store it somewhere. What is fine and this is why we need them.

Now imagine your own website has 200k + pages. And the content of the website is of course managed by humans. Despite of great effort to not introduce errors, the speed of changes, deliveries, campaigns can lead to inconsistencies or surprises that public crawlers will notify you about, but only after long the error was introduced.

A good solution (of course a crawler is just part of it) is keeping an army of crawlers watching your landing pages.

# Crawling my own blog

Let's code more and talk less. Before you do it for your own company page, bear it will increase the load on your own servers and can even alter the statistics and metrics for your business. Also some [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network) may block your User agent.

```golang
//main
	driver, err := neo.NewClosableDriverPool("bolt://localhost:7687", 20)

	if err != nil {
		log.Panic("Unable to establish connection to neo4j")
	}
	defer driver.Close()

	c := colly.NewCollector(
		colly.AllowedDomains("paulosuzart.github.io"),
		colly.MaxDepth(2),
		colly.Async(true),
	)
	c.Limit(&colly.LimitRule{
		DomainGlob:  "*",
		Parallelism: 1,
		RandomDelay: 5 * time.Second,
	})

	c.OnHTML("a[href]", func(e *colly.HTMLElement) {
		targetLink := e.Request.AbsoluteURL(e.Attr("href"))
		connect(e.Request.URL.String(), targetLink, e.Request.Depth, driver)
		c.Visit(targetLink)
	})

	c.OnResponse(func(r *colly.Response) {
		merge(r.Request.URL.String(), r.Request.Depth, driver)
		fmt.Printf("Just got response for path %s\n", r.Request.URL.EscapedPath())
	})

	c.Visit("https://paulosuzart.github.io/")
	c.Wait()
```

**WARNING** *This is not you should organize your project or code in go. This has pure didactic intentions. To get more information about this topic please use [Golang Standards - Project Layout](https://github.com/golang-standards/project-layout)*.

I would say this is the minimum setup with colly. This snippet was copied from this [post github repo](https://github.com/paulosuzart/goneo-example).

By setting `AllowedDomains`, we restrict the crawler instance (it's called collector) to `paulosuzart.github.io`. This way we prevent the crawler to follow links to external websites that is not my own blog.

The `MaxDepth` is another important measure. The deeper your crawler goes, the more likely it will fetch more content. But of course this depends on your own internal links.

Finally `Limit` will allows for parallel request to a certain level. At last you don't want to bring your servers down, just boost your crawling a bit, right?

By default colly will not follow any links if you don't manually tell it to. This is because we start it asking it to visit just one page with `c.Visit("https://paulosuzart.github.io/")`. Then we need a `c.OnHTML("a[href]"...` to tell it to continue.

You can also see some interaction with neo4j through two function calls: `connect` and `merge`. They look like this:

```golang
func connect(sourceURL string, targetURL string, depth int, pool neo.DriverPool) {
	conn := getConnection(pool)
	defer conn.Close()

	_, err := conn.ExecNeo(`
	MATCH (source:Page {url: {sourceUrl}})
	MERGE (target:Page {url: {targetUrl}})
	MERGE (source)-[r:LINK]->(target) return r`,
		map[string]interface{}{
			"sourceUrl": sourceURL,
			"targetUrl": targetURL,
			"depth":     depth,
		},
	)

	if err != nil {
		log.Panic("Failed to create link data")
	}
}

func merge(absoluteURL string, depth int, pool neo.DriverPool) {
	conn := getConnection(pool)
	defer conn.Close()

	_, err := conn.ExecNeo(`
	MERGE (s:Page {url: {url}})
	return s`,
		map[string]interface{}{
			"url":   absoluteURL,
			"depth": depth,
		})
	if err != nil {
		log.Panic("Failed to merge page")
	}
}
```

More non recommended way of doing things here. Don't always panic and please do your error handling properly.

The `merge` function creates a connection from the pool, and tries to Merge an existing page with the given url. A single page may be linked from may different places, thus making it possible to have duplications. With merge, neo4j matches the existing document for you, or create a new one. Notice this function is called at `OnResponse`. This way you can make sure that upon liking this page with another one, it's already in the database.

That's why `connect` actually merges the `targetURL` but `Matches` the `sourceURL`. During the creation of the target page, then a link between the two pages is created.

# Running

The code for this post is available in this [GitHub Repo](https://github.com/paulosuzart/goneo-example). Running should be as simple as cloning the repo, issuing a `go build` and then `./goneo`.

Don't forget to do a `docker-compose up` in another terminal so neo4j is availabe for you at [http://localhost:7474/browser/](http://localhost:7474/browser/).

After running the application neo4j should show something like this:
![](https://i.imgur.com/QvJ7qOU.png =250x)


# Conclusion

Don't underestimate this simple solution. With all data collected you can run all available [Neo4j algorithms](https://neo4j.com/docs/graph-algorithms/current/). This can bring a lot of insights about your web site. I'm not talking about a low traffic website like my blog, but much more relevant products can understand a lot about it's own pages taking similar approach.



