---
layout: post
title: "Morse Code and Trees"
date: 2020-04-30 10:22
comments: true
categories: [ java ]
---

Hello again! After more than a year without posting, here I am. This time I talk about a recent code challenge that I failed and for the sake for my peace of mind I'm sharing a working solution for the problem of finding a english character out of a [Morse Code](https://en.wikipedia.org/wiki/Morse_code) signal. The solution should also consider possible noises in the morse code, thus identifying all possibilities that would match. Let's take a look.

<!--more-->
# Table of Contents
   * [The code challenge](#the-code-challenge)
   * [Morse code](#morse-code)
   * [The tree](#the-tree)
   * [Searching](#searching)
   * [The Optimized Search](#the-optimized-search)
   * [Conclusion](#conclusion)

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

So we have a tree where each node shares a prefix with the parent node. Not always though, if you check the three you'll notice a empty node after `R`, but it still point to `+` node. So empty nodes are fine and actually needed.

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

You can store the full `morse` sequence that represents a char, the english `symbol` and the two pointers to the next morse nodes.

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

The code challenge provided a set of morse codes and their respective english symbols in alphabet order. What this insert will do is go character by character of a morse being inserted and create, if needed, a node `Signal` for each character. This way, the first element inserted `.-` (`A`) would create two nodes. one for `.` and one for `.-`, the later being filled with `A` information. 

Then when the letter `E` is inserted, it's empty node already exist and is assigned to `currentNode` and then filled in. We then end up with a nice tree precisely like the one above.

# Searching

This makes our insert a prefix search by itself. We continue to follow the tree character by character to the left (`.`) or to the right (`-`) depending on what we ant to insert. But our friends of the challenge made things a bit worse. A noise, namely a `?` in the midst of a signal`, pushes us to different waters.

If a `?` are found, `?` need to be replaced by all possible combinations of `.` and `-`. Instead of generating all the combinations let's use regex for that in our search.

```java
    void addToSearch(LinkedList<Signal> signals, Signal node) {
      if (isNull(node)) {
        return;
      }
      signals.addFirst(node);
    }

    List<Signal> fuzzyMatch(String signal) {
      List<Signal> result = new ArrayList<>();
      LinkedList<Signal> toSearch = new LinkedList<>();

      toSearch.addFirst(root.dot);
      toSearch.addLast(root.dash);

      var isFuzzy = signal.contains(FUZZY_SIGNAL);
      var pattern = Pattern.compile(signal.replace(".", "\\.") 
        .replace(FUZZY_SIGNAL, "[-|\\.]"));

      while (!toSearch.isEmpty()) {
        Signal curr = toSearch.remove(0);
        if (Objects.nonNull(curr.morse) && 
		    pattern.matcher(curr.morse).matches()) {
          result.add(curr);
          if (!isFuzzy) {
            break;
          }
        }
        addToSearch(toSearch, curr.dash);
        addToSearch(toSearch, curr.dot);
      }

      return result;
    }
```

A depth first search is no more than a stack of nodes waiting to be visited (here represented by an `ArrayList`). You stack on top (in this case `addFirst`) the nodes that you wanna visit. As usual we start with the two immediate possible nodes to visit, the children of `root`.

But what to check? The noise requires a regex match, thus we replace any `?` by `[-|\.]`. This way we cover all combinations. Also remember to escape the `.` and make it a `\.`.

If there is more than one match, the result order is preserved by the walk in depth search order. After you search you can find the expected results:

But this solution is not optimal. If you think for a moment, running a regex match will cause a increase in time complexity, plus adding to `toSearch` stack nodes you actually don't need to visit will also waste time. How to optimize this?

# The Optimized Search

Many optimizations can imply shaving array positions instead of relying on higher level methods. Sounds terrifying but the improvement is quite straightforward.

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

        if (signal.charAt(curr.morse.length()) == '.') {
          addToSearch(toSearch, curr.dot, signal);
        } else if (signal.charAt(curr.morse.length()) == '-') {
          addToSearch(toSearch, curr.dash, signal);
        } else {
          addToSearch(toSearch, curr.dash, signal);
          addToSearch(toSearch, curr.dot, signal);
        }
      }
      return result;
    }
```
We again start using the `root` node as the first node in our. The first comparison sounds strange but it only blindly compares if the size of the morse is the same size of the searched morse. But if the remaining of the method is correct we can rest assured only nodes that make sense are visited, thus only the size matters.	

Finally the fuzzy magic. If the signal at the position of the current `morse` length is a `.` then go for it. Same if `-` or go visit both if the it's a noise `?`.

In fact the optimized version is much simpler than the version that uses regex and sounds to be saving a lot of time.

By peeking the next value to be matched in a signal we make sure to do a prefix search instead of a Depth First Search. This it's much more optimized.

Let's try some  examples:
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

The full implementation you find on [this gist](https://gist.github.com/paulosuzart/9bb8b4944fb01cdbdaaf72358c52ff1c). The gist includes an optimized version not using regex. This version is slightly more complex to explain but the optimization lies in the fact that only nodes sharing a prefix are visited, plus no regex is used and only the length of the prefix is used to match the signals.

# Conclusion

Code challenge is something I'm not a big fan of. I myself avoid applying these metal-cold code challenges and prefer code questions where a detailed discussion is enough to find a solution then you iterate with the candidate. It's more humane, more respectful and you better understand the candidate. But given the feedback I got, it turned into a matter of honour to implement this, and if some day they see it, nice, if not, it's my peace of mind that counts.

A good understanding of a problem, an equally important, the understanding of the solution can take time. If you check the [gist history](https://gist.github.com/paulosuzart/9bb8b4944fb01cdbdaaf72358c52ff1c/revisions) you'll see dozens of revisions over couple days. As you understand you are able to optimize and fore see conditions that can compromise performance, space or 


[morse]: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/International_Morse_Code.svg/186px-International_Morse_Code.svg.png
[morse-tree]: https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Morse-code-tree.svg/320px-Morse-code-tree.svg.png