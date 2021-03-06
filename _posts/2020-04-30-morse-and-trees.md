---
layout: post
title: "Morse Code and Trees"
date: 2020-04-30 10:22
comments: true
tags: [java]
---

Hello again! After more than a year without posting, here I am. This time I talk about a recent code challenge that I failed and for the sake for my peace of mind I'm sharing a working solution for the problem of finding a english character out of a [Morse Code](https://en.wikipedia.org/wiki/Morse_code) signal. The solution should also consider possible noises in the morse code, thus identifying all possibilities that would match. Let's take a look.

<!--more-->

# The code challenge

You know those code challenges right? They are very often loaded with information that are there just to confuse you. I once saw a challenge in these platforms that had a whole story about zombies. It was so distracting and yet in the end they expect you to implement a Depth First Search.

This time the challenge was about finding the corresponding english character for a given morse code. Because I don't have the full question title nor could find on the internet, I had to try to remember form the top of my head.

But basically given a morse code like `.--` one should be able to return `W` as the corresponding english char. Or if the code contains a noise like in `.??`, all possible matches containing characters starting with `.` and ending in any combination of `..`, `.-`, `--`, `-.` should be returned, thus something like `[S, U, R, W]`. 

Another requirement was, the returned result should be ordered according to morse order, not english alphabet order. Interesting uhn?

# Morse code

If you check the alphabet in morse you'll notice a kinda of prefix structure. 

![Morse code][morse] 
![Morse tree][morse-tree] 

Everything starts from a root node that points to `E` that is encoded as `.`, and `T` that is encoded as `-`. The structure and goes on by adding a left node if the next signal is a `.` (see `I` for example, `..`), or to the right if the next signal is a `-` (see `A`, `.-`). The images make it very clear.

So we have a tree where each node shares a prefix with the parent node. Even when there's no english char representation for that node. For example notice an empty node after `R`, it still points to `+` node.

# The tree

The visualization of the tree you find above. A possible way to encode a node of this tree is as follows:

```java
  class Signal {
    String morse; // ex "..-"
    String symbol; // ex "U"
    Signal dash;
    Signal dot;
  }
```

You can store the full `morse` sequence that represents a char, the english `symbol` and the two pointers to the next predecessor and successor morse nodes.

But remember that the order of morse code is not the same as the english alphabet and it's defined by it's prefixes, and ultimately it is how the tree must be structured. A good way to insert nodes in this tree can be:

```java
    private Signal insert(String signal, char alpha) {
      Signal currentNode = root;
      for (int i = 0; i < signal.length(); i++) {
        var step = signal.charAt(i);

        if (step == '.') {
          if (isNull(currentNode.dot)) {
            currentNode.dot = new Signal();
            currentNode.dot.morse = signal.substring(0, i + 1);
          }
          currentNode = currentNode.dot;
        } else {
          if (isNull(currentNode.dash)) {
            currentNode.dash = new Signal();
            currentNode.dash.morse = signal.substring(0, i + 1);
          }
          currentNode = currentNode.dash;
        }
      }
      currentNode.symbol = valueOf(alpha).toUpperCase();
      currentNode.morse = signal;
      return currentNode;
    }
  }
```

The code challenge provided a set of morse codes and their respective english symbols in english alphabet order. What this insert will do is go character by character of a morse being inserted and create, if needed, a node `Signal` for each character prefix. This way, the first element inserted `.-` (`A`) would create two nodes. one for `.` and one for `.-`, the later being filled with `A` information. 

When the letter `E` is inserted, its empty node already exist and is assigned to `currentNode` and then filled in. We then end up with a nice tree precisely like the one above.

# Searching

This makes our insert a sort of binary search where the order of elements is determined by it's prefix. We continue to follow the tree character by character to the left `.` or to the right `-` depending on what we want to insert. But our friends of the challenge made things a bit challenging. A noise, namely a `?`, in the midst of a `signal`, pushes us to different waters when we want to search.

While traversing the tree, if a `?` is found, we need to consider both children of a node. In the end our search algorithm is a binary search with a fork possibility whenever it sees a `?`.

```java
  List<Signal> fuzzyMatch(String signal) {
      var result = new ArrayList<Signal>();
      var toSearch = new LinkedList<Signal>();

      toSearch.add(root);

      while (!toSearch.isEmpty()) {
        Signal curr = toSearch.remove(0);

        if (curr.morse.length() == signal.length()) {
          result.add(curr);
          continue;
        }

        switch (signal.charAt(curr.morse.length())) {
          case '.':
            addToSearch(toSearch, curr.dot);
            break;
          case '-':
            addToSearch(toSearch, curr.dash);
            break;
          default:
            addToSearch(toSearch, curr.dash);
            addToSearch(toSearch, curr.dot);
        }
      }
      return result;
    }
```
Like insert, We again start using the `root` node as the first node in our stack. The first comparison sounds strange but it only blindly compares if the size of the morse in the current node is the same size of the searched morse `signal`. And if the remaining of the algo is fine we can rest assured only nodes that make sense are visited, thus only the size matters.	

Finally the fuzzy magic. If the signal at the position of the current `morse` length is a `.` then go for it. Same for `-`. Or then go visit both children if the its a noise `?`. This is the only difference from a [binary search in a ordered binary tree](https://en.wikipedia.org/wiki/Binary_search_tree#Searching).

This hack is also a good way to not have to sort the result after a search because search walks the tree in order. Imagine if you replace any `?` by all combinations possible and do a search for each. You would have to implement a way to sort the results of the search. Although possible by using the idea of successors and predecessors, would result much more complex and inefficient.

Let's give it a try:
```
.      Expect E = [E]
?      Expect E or T = [E, T]
..-    Expect U = [U]
.??    Expect S, U, R, W = [S, U, R, W]
.--    Expect W = [W]
?.     Expect I or N = [I, N]
.?     Expect I or A = [I, A]
..--.. Expect ? = [?]
..-.   Expect F = [F]
..---  Expect 2 = [2]
---..  Expect 8 = [8]
----.  Expect 9 = [9]
-----  Expect 0 = [0]
----?  Expect 9 or 0 = [9, 0]

```

The full implementation you find on [this gist](https://gist.github.com/paulosuzart/9bb8b4944fb01cdbdaaf72358c52ff1c).

# Conclusion

Code challenge is something I'm not a big fan of. I myself avoid applying these metal-cold code challenges and prefer code questions where a detailed discussion is enough to find a solution then you iterate with the candidate. It's more humane, more respectful and you better understand the candidate. But given the feedback I got, it turned into a matter of honour to implement this, and if some day they see it, nice, if not, it's my peace of mind that counts.

A good understanding of a problem, an equally important, the understanding of the solution can take time. If you check the [gist history](https://gist.github.com/paulosuzart/9bb8b4944fb01cdbdaaf72358c52ff1c/revisions) you'll see dozens of revisions over couple days. As you understand both the problem and the solution, you are able to optimize and foresee conditions that can compromise performance, space or the readability of the solution. I confess the `?` noise got me. Was enough to blur my brain and not seeing a simpler solution. But now it's done!


[morse]: https://imgur.com/pfIbtvn.png
[morse-tree]: https://imgur.com/A4PsVaN.png