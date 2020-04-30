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

Everything starts from `E`, that is encoded as `.` and go on by adding left node if the next signal is a `.` (see `I`, `..`), or to the right if the next signal is a `-` (see `A`, `.-`). The images make it very clear.

So we have a tree where each node shares a prefix with the parent node. Not always though, if you check the three you'll notice a empty node after `R`, but it still point to `+` node. So empty nodes are fine and actually needed.

# The tree

The visualization of the tree you find above. A possible way to encode a node of this tree is as follows:

```java
  class Signal {
    String morse;
    String symbol;
    Signal dash;
    Signal dot;
  }
```

You can store the full `morse` sequence that represents a char, the english `symbol` and the two pointers to the next morse nodes.

But remember that the order of morse code is not the same as the english alphabet and it's defined by it's prefixes. An ultimately is how the tree must be structured. A good possible way to insert node in this tree can be:

```java
 private Signal insert(String signal, char alpha) {
      Signal currentNode = root; // root of the tree
      for (int i = 0; i < signal.length(); i++) {
        var step = signal.charAt(i);

        if (step == '.') {
          if (isNull(currentNode.dot)) {
            currentNode.dot = new Signal();
          }
          currentNode = currentNode.dot;
        } else {
          if (isNull(currentNode.dash)) {
            currentNode.dash = new Signal();
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
private void addToSearch(LinkedList<Signal> signals, Signal node) {
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

Then we go node by node checking if the pattern apply to it. We can optimize a bit by doing two things: one is match only if the size is the same of the `signal` because there's no point in matching `.` against `...` for example. Another optimization is stacking for visit only nodes that make sense, that is nodes that can be slipt by the pattern. But for the challenge this is more then enough.

If there is more than one match, the result order is preserved by the walk in depth search order. After you search you can find the expected results:

```
. ==> Expect E = [E]
? ==> Expect E or T = [E, T]
..- ==> Expect U = [U]
.?? ==> Expect S, U, R, W = [S, U, R, W]
.-- ==> Expect W = [W]
?. ==> Expect I or N = [I, N]
.? ==> Expect I or A = [I, A]
..--.. ==> Expect ? = [?]
..-. ==> Expect F = [F]
```

The full implementation you find on [this gist](https://gist.github.com/paulosuzart/9bb8b4944fb01cdbdaaf72358c52ff1c).

# Conclusion

Code challenges is something I'm not a big fan of. I myself avoid applying these metal-cold code challenges and prefer code questions where a detailed discussion is enough to find a solution then you iterate with the candidate. It's more humane, more respectful and you better understand the candidate. But given the feedback I got, it turned into a matter of honour to implement this, and if some day they see it, nice, if not, it's my peace of mind that counts.


[morse]: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/International_Morse_Code.svg/186px-International_Morse_Code.svg.png
[morse-tree]: https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Morse-code-tree.svg/320px-Morse-code-tree.svg.png