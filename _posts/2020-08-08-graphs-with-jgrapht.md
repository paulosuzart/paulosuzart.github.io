---
layout: post
title: "Graphs With JGraphT"
date: 2020-08-08 16:22
comments: true
categories: [ java, graphs]
---

Hey ho! What crazy times to be alive! But here we go for a new post on Graphs. To be more precise [JGrahT](https://jgrapht.org/) library, a Java library I I used quite heavily recently in my last company. In this post I'm going to use one of the Scoring algorithms provided by the library to solve a SEO related problem. The goals is to serve as an introduction to the library and some basic usage of it. Check it out!

<!--more-->

# Graphs

[Graph Theory](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)) was one of the most intimidating topics at the university for some. When you see drawings of graphs, all makes sense, until you have to do some code yourself. Then the challenges begins. Then you leave the university and may never see graphs again. I had better luck.

At [Omio](https://omio.com/) though, the idea of graphs is simply the natural way to go. Omio allow people to travel from A to B, and then you have a graph!

**DISCLAIMER:** *This post has no connection with Omio, nor reflects the way systems were developed there. This post is just inspired in a hypothetical scenario related to travel and solving the problem of bots crawling.* 

After using [Neo4j](https://paulosuzart.github.io/blog/2019/02/01/crawling-with-golang/), it was JGraphT that conquered me. It was a critical piece that allowed us to solve a 6 year long issue with Internal Linking. You can read more about this topic in this blog post: [Nailing Internal Linking with Graph Theory](https://medium.com/omio-engineering/nailing-seo-internal-linking-with-graph-theory-2c45544a024d).

# The challenge

Enough small talks. Time to see some code. Let's give a problem statement so we introduce JGraphT and the ingredients to solve the problem:

> Given a set of routes (pair of locations here represented just by their names), link from the home page of your website at most `n` pages so that upon visit, a bot can grasp page relevance, now that they are linked from the home page.

Well, in real life problem is slightly more complex. But for our pet project we just want to link from the home page, the pages that will cause the bots to "walk" the least possible in order to cover most of the graph.

**Then the Graph**

The graph can be assembled out of the list of routes that have a page representing each of them:

```csv
London,Berlin
Barcelona,Berlin
Berlin,London
Munich,Barcelona
Munich,London
Amsterdam,Barcelona
Munich,Amsterdam
```

Each route here represents a page connecting `A` to `B`. In other words, a page `P` connects location `A` to `B`. In cypher this is something like `A-[:P]->B`. Ok, image is better:

![Locations][locations]

The idea of allowing for bots to *"walk" the least possible in order to cover most of the graph* is strongly connected with the idea of centrality in Graphs. For example, the [Page Rank](https://en.wikipedia.org/wiki/PageRank) algorithm used by some Search Engines is no more than a centrality algorithm and in this case, we want a centrality algo that will give us the most conductive nodes in a graph, allowing information (in this case a bot) to flow (in this case walk) throughout this graph.

You can check couple [Centrality](https://jgrapht.org/javadoc/org.jgrapht.core/org/jgrapht/alg/scoring/package-summary.html) scoring algos provided by JGraphT. Each having their own characteristics.

In our example we are going to use Betweenness Centrality. But there's a catch. In this hypothetical scenario you find more pages than locations. Notice how Munich, Berlin, Barcelona repeats in that list. In real world you have potentially thousands of routes through cities like that. In order to save resources, it is a good idea to calculate scoring on locations instead of pages, thus reducing drastically the time you would eventually spend by taking this into production.

Let's see some code:

```java
// main method:
            var locationsGraph = importer.doImport();

            var lineConverter = new LineGraphConverter<String, DefaultEdge, DefaultEdge>(locationsGraph);

            var pagesGraph = new SimpleDirectedGraph<DefaultEdge, DefaultEdge>(DefaultEdge.class);
            lineConverter.convertToLineGraph(pagesGraph);

            var scores = new BetweennessCentrality<>(locationsGraph, true);

            var pageScores = doubleSumScoreDecorator(locationsGraph, scores, pagesGraph);

            var rootPage = new DefaultEdge();

            new TopPages(pagesGraph, pageScores, rootPage, 3);

            IO.exportPagesCSV(locationsGraph, rootPage, "/tmp/out.csv").doExport(pagesGraph);

```

Our code to solve the problem does couple things. It uses a utility (not relevant for us) to import that CSV above as a `Graph<Sring,DefaultEdge>`. *`String` for the sake of simplicity here.*

Then pay attention to `new LineGraphConverter`. What it does is to actually create the graph of pages (remember that pages are any arbitrary edge that connects two locations). In this case the edges are represented by the JGraphT provided edge called `DefaultEdge`. As the name sasys, `LineGraphConverter` creates a [line graph](https://en.wikipedia.org/wiki/Line_graph) of "pages" (image soon).

We do this because we can use the original graph of locations, potentially much smaller, to run scoring and couple algos, but then our final output graph is a graph of pages, not locations.

Now two scores are calculated. The `BetweennessCentrality` of the original locations graph and a `doubleSumScoreDecorator`. The later is a custom [`VertexScoringAlgorithm`](https://jgrapht.org/javadoc/org.jgrapht.core/org/jgrapht/alg/interfaces/VertexScoringAlgorithm.html) that simply delegates the scoring of pages to the sum of the scores of the locations. Check it:

```java
public class SumScoresDecorator<V, E, S extends Number> implements VertexScoringAlgorithm<E, S> {

    private final Graph<V, E> delegate;
    private final VertexScoringAlgorithm<V, S> decorated;
    private final Graph<E, ?> graph;
    private final BiFunction<S, S, S> adder;

    private SumScoresDecorator(Graph<V, E> delegate,
                               VertexScoringAlgorithm<V, S> decorated,
                               Graph<E, ?> graph,
                               BiFunction<S, S, S> adder) {
        this.delegate = delegate;
        this.decorated = decorated;
        this.graph = graph;
        this.adder = adder;
    }

    @Override
    public Map<E, S> getScores() {
        return graph.vertexSet().stream()
                .map(e -> new SimpleEntry<>(e, getVertexScore(e)))
                .collect(Collectors.toMap(SimpleEntry::getKey, SimpleEntry::getValue));
    }

    @Override
    public S getVertexScore(E e) {
        var source = decorated.getVertexScore(delegate.getEdgeSource(e));
        var target = decorated.getVertexScore(delegate.getEdgeTarget(e));
        return adder.apply(source, target);
    }

    /**
     * Instantiates a new <pre>SumScoresDecorator</pre>
     */
    public static <V, E> SumScoresDecorator<V, E, Double> doubleSumScoreDecorator(Graph<V, E> delegate,
                                                                                  VertexScoringAlgorithm<V, Double> decorated, Graph<E, ?> graph) {
        return new SumScoresDecorator<>(delegate, decorated, graph, Double::sum);
    }


}
```

This class is total custom and a good way to extend JGraphT by decorating the any of the existing Scoring algos. Because a page is an edge in the location graph, but a vertex in the generated line graph, this decorator simply delegates calls to the original `VertexScoringAlgorithm`(a `BetweennessCentrality` above) and sum the scores of the source and target vertex of a page in the original location graph.

If, for instance, Berlin gets score 10 and London gets score 5, in the line graph the score of this page will be 15. This way we can create our end goal algo that takes as input our pages graph, the scoring and links the top most relevant pages out of a provided root (a home page) node.

Let's see it:

```java
public class TopPages {

    private final Graph<DefaultEdge, DefaultEdge> graph;
    private final VertexScoringAlgorithm<DefaultEdge, Double> scoring;
    private final DefaultEdge root;
    private final int totalLinks;

    public TopPages(Graph<DefaultEdge, DefaultEdge> graph,
                    VertexScoringAlgorithm<DefaultEdge, Double> scoring,
                    DefaultEdge root,
                    int totalLinks) {

        this.graph = graph;
        this.scoring = scoring;

        this.root = root;
        this.totalLinks = totalLinks;
        compute();
    }

    private void compute() {
        var topPages = scoring.getScores().entrySet().stream()
                .sorted(Collections.reverseOrder(Comparator.comparingDouble(Map.Entry::getValue)))
                .limit(totalLinks)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
        graph.addVertex(root);
        topPages.forEach(page -> graph.addEdge(root, page));

    }

}
```
Because we abstracted the scoring via `VertexScoringAlgorithm`, our `TopPages` algo is able to simply use whatever underlying implementation is provided. In the `compute()` method you see the scoring being used and sorted in descending order to finally link `n`(or better saying `totalLinks`) from the home page.

The output is more or less like this:

![Output][output]

*Left top of each node the score it gets by the algo*

In the main method we provided `3` as the total links to be generated from home page. Then you get `Munich_Barcelona`, `Amsterdam_Barcelona` and `Barcelona_Berlin` to be linked from home page.

Is it the most optimal think? Yes, but... Yes because it mathematically makes it easy for bots to walk less, but you can see how two of the pages linked from Home are actually pointing to another page also already linked from Home. It is totally possible to optimize and prevent the Home to link to pages that are linked from the first layer of pages already. But it's a long discussion.

Take it with a grain of salt given that this is a very small simple example. If you [clone the repository](https://github.com/paulosuzart/jgrapht-post) and play a bit in the source file, you should be able to see quite different results. Give it a try.

Finally, the output CSV is exported and you should see something like:

```csv
travel-Berlin-to-London,travel-London-to-Berlin
travel-Munich-to-London,travel-London-to-Berlin
travel-London-to-Berlin,travel-Berlin-to-London
travel-Barcelona-to-Berlin,travel-Berlin-to-London
travel-Munich-to-Barcelona,travel-Barcelona-to-Berlin
travel-Amsterdam-to-Barcelona,travel-Barcelona-to-Berlin
travel-Munich-to-Amsterdam,travel-Amsterdam-to-Barcelona
Home,travel-Barcelona-to-Berlin
Home,travel-Amsterdam-to-Barcelona
Home,travel-Munich-to-Barcelona
```

This is the Edge List of links `Page(A-B) to Page(A-B)` pages, plus the generated links out of Home page.

# Conclusion

First and foremost, you can find runnable [code here in this repo](https://github.com/paulosuzart/jgrapht-post).

With couple lines o code we were able to apply important graph concepts like centrality and to solve a fairly real business problem. You can apply the same concepts for example to select the set of products to show in a home page of an e-commerce or even the best blog articles in a huge content heavy blog.

JGraphT is an amazing library and you can find a huge amount of algos for graphs. You can also use graph generation to randomly generate graphs for tests for example, this way you can make sure your algorithms are working with any (maybe most) graphs that may flow through it.

There are much more complex stuff on graphs, some of the problems are [NP Complete](https://en.wikipedia.org/wiki/NP-completeness). But you don't need to invent a new graph algorithm or understand all click, degeneration, coloring, etc to take advantage of it. Start small, try to think if your next problem could be a good fit and give a try to JGraphT.

I had a precious chance to fairly deep project using Graphs and it gave me much more confidence on it and how useful graphs can be in a daily basis.



[locations]: https://i.imgur.com/Ot4h3JD.png
[output]: https://imgur.com/HJb4jXW.png