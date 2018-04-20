---
layout: post
title: "Exploring Optional Types in Java 8"
date: 2018-04-19 14:00
comments: true
categories: [ java ]
---

I guess it is the first post on Java since [my last post on it in 2008](https://codemountain.wordpress.com/category/java/). It's been 8 years since then and it's been 6 years since I switched from Java to Groovy and the to Python/Node(Typescript). But let's see how implementing Binary Tree Depth and Breadth Search feels with Java8 lambdas, [Optional](https://docs.oracle.com/javase/8/docs/api/java/util/Optional.html) and things related.

In this posts we'll also see [vavr](vavr.io) `Option` type and `List`!

<!--more-->

**TL;DR - if you want just the final code of the post, please check [master](https://github.com/paulosuzart/tree-search/tree/master/src/main/java/com/alice) and [vavr](https://github.com/paulosuzart/tree-search/tree/vavr/src/main/java/com/alice) versions**

# Billion dollars mistake

[Tony Hoare](https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare) hast stated the allowing null references was the biggest mistake on computer science ever. Every Java programmer already had to deal with `NullPointerException` (NPE) and it is a pain in the neck for sure as it leads your program to completely stop if not handled or better saying: if note avoided.

The notion of optional types are not new and now many languages delivery it some how. Check [this article](https://en.wikipedia.org/wiki/Option_type) on wikipedia.

The fact is that dealing with null references makes your code dirty, repetitive and most important unsafe. Crystal language for example doesn't allow you to get a NPE in your face ensured by the type system directly. Just to show case it, consider the tiny snippet below:

```ruby
def upSenior(age, name)
  name.upcase
end  

up = upSenior 12, "Paulo"
puts up.size
```

This should print `5` as `upSenior` will fatally return the upcase version of the variable `name`. Now lets try to upcase only if the age is greater than, say, 18.


```ruby
def upSenior(age, name)
  name.upcase
end  

up = upSenior 12, "Paulo"
puts up.size
# undefined method 'size' for Nil (compile-time type is (String | Nil))
```

This is because changing your code to introduce a possible Nil return changes the return type of `upSenior` to `String | Nil` instead of just `String` as in the first version. As `Nil` has no `upcase` method, you can't even compile your code.

This is certainly great technique, but let's explore the functional way of doing it. 


# Optional on Bintree search

I was challenged to implement a binary tree search algorithm. Actually one that searches the tree in depth and a second one in breadth. So let's consider our `Node` class, a super simple one:

```java
class Node {
  private int value;
  private Optional<Node> left;
  private Optional<Node> right;
  // ... a lot more code down here like constructors, getters and so on
}
```

We are trying to avoid nulls, right? So instead of having `left` and `right` pointing to nullable references of `Node`, we wrap both on Java's native Optional.

Taking a very simple algo into account, a depth first would look like this:

```java
// ... lots of things here
    private Optional<Node> doSearch(Optional<Node> currentNode) {
        return currentNode.flatMap(node -> {
            if (node.getValue() == this.searchFor) {
                return Optional.of(node);
            }
            // oops, there is a null here. Continue reading ;)
            return Optional.ofNullable(doSearch(node.getLeft()).orElse(doSearch(node.getRight()).orElse(null)));

        });

    }
// ... other things here
```

`currentNode` is supposed to assume in the first iteration, the value of the root node of the three, and from this point all we have to do is check if the node is the node we are looking for, and if it is not, check its children.

Mind that `currentNode` is wrapped around a `Optional`, so it might actually have no value, so we use `flatMap` to "step into" the context of the value, it it exists, and then we run our logic.

Similarly, the breadth first will take us to always accumulate the children of the current list of nodes being evaluated and submit the to the next iteration. Let's see.

```java
    private static Consumer<Node> enqueue(final List<Node> list) {
        return n -> list.add(n);
    }

    private Optional<Node> doSearch(List<Node> nodes) {
        if (nodes.isEmpty()) {
            return Optional.empty();
        }

        List<Node> nextSearchNodes = new ArrayList<>();

        for (final Node node : nodes) {
            
            if (node.getValue() == this.searchFor) {
                return Optional.of(node);
            }
            
            node.getLeft().ifPresent(enqueue(nextSearchNodes));
            node.getRight().ifPresent(enqueue(nextSearchNodes));

        }

        return this.doSearch(nextSearchNodes);
    }
```

In this case `nodes` is supposed to have its first value set to the root node wrapped in a list. And from this point all we do is accumulate the children of nodes(if none is the node we are looking for), and just do the iteration again.

Look, both algorithms could be implemented without Optional, and both could be implemented in a different way even using Optional. But I found this way enough for the purpose.

# Things I didn't like in any of the algorithms

In the depth first algo we saw a `null` there. Although it is there, it is contained and will not leak to cause a NPE elsewhere. This is required because `Optional#orElse` can only take a value of Node out of `Optional` context, this means that if you couldn't find the searched node on any side (left, right) you must to provide the empty version of your node, which is null (see the `Optional.ofNullable` there).

In the breadth first algo there is something similar going one, we don't have a explicit `null` but we have the ugly `ifPresent`, a mutable `List<Node>` and a `for` loop. There is nothing precisely wrong with neither, but if we can improve, let's improve.

# Vavr.io Option to the rescue

The [Vavr.io](http://www.vavr.io/) promises to turn Java upside down. And I'm pretty convinced they are doing great. Their [Option](https://static.javadoc.io/io.vavr/vavr/0.9.2/io/vavr/control/Option.html) just works and is awesome. Now imagine we have replaced `Optional` with `Option` in our `Node` class and let's see how both algo looks like afther the change.

First, the depth first:

```java
    private Supplier<Option<Node>> checkChildren(Option<Node> node) {
        return () -> node.flatMap(n -> doSearch(n.getLeft()).orElse(doSearch(n.getRight())));
    }

    private Option<Node> doSearch(Option<Node> currentNode) {
        return currentNode.filter(isSerachFor()).orElse(checkChildren(currentNode));
    }
```

I was not in a competition to write the smaller code possible, but it actually became smaller then the first version. This is possible because `Option#orElse` can take another option as alternative value. So `checkChildren` can provide this value by checking both childs of the `currentNode` and returning the result.

The breath first is showed even more beauty:

```java
    private Supplier<Option<Node>> checkChildren(List<Node> nodes) {
        List<Node> children = nodes.flatMap(n -> List.of(n.getLeft(), n.getRight())).flatMap(n -> n);
        return () -> children.isEmpty() ? Option.none() : doSearch(children);
    }
    
    private Option<Node> doSearch(List<Node> nodes) {

        System.out.println("Looking at the following nodes: " + nodes);
        return nodes.filter(isSerachFor()).toOption().orElse(checkChildren(nodes));
      
    }
```

All we have to do is filter the list of nodes (imagine a `isSearchFor` predicate available somewhere) and then make it a `Option`. If it wasn't found the option will be empty, triggering our `checkChildren`. All `checkChildren` do is just create a list of nodes for the next iteration. And bear that only nodes that are not empty will be added to this list (bear the use of `flatMap`);

Inside `checkChildren`, `children`  will be empty as soon as we reach the last leaf of the tree, so we can just return.

# Where is the vavr.io List?

This is funny how one can make things in Java more practical like [vavr's List](https://static.javadoc.io/io.vavr/vavr/0.9.2/io/vavr/collection/List.html). Why don't they do it in the sdk? Whatever.

The code above uses at least three interesting methods provided by this List. One is `filter` that is able to return a list of elements that matches your provided `Predicate`. The other one is `toOption`, where it gets the head of the list and return as a `Option` and finally, the `of` method that is able to produce a list for your with the variable arguments you pass to it.

This list is also immutable, this means adding items to it actually returns a new list. You can read more on performance of List and other provided structures [right here](http://www.vavr.io/vavr-docs/#_performance_characteristics).


# Conclusion

I'm not in the business of type theory, I actually suck at it when it comes to explaining these things formally. But I can say optional feels very good in Java too, even though using Vavr.io was a better option. Vavr actually looks more like Category Theory library for Java, or at least a subset what is generally found for [Scala](https://www.scala-lang.org/).

Of course some credit here goes to Java8 lambdas that made it much much more smooth to work with this kind of construct that otherwise would be just bizarre to implement.

Hope you have liked the post. Happy Optional Types!

