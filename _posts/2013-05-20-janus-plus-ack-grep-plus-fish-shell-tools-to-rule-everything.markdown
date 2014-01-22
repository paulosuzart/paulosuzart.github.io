---
layout: post
title: "Janus + ack-grep + fish shell: Tools to rule everything"
date: 2013-05-20 19:44
comments: true
categories: [tools, linux]
---

Hello, I'm posting as often as the men go to the moon! Sad. For a good
reason, though. We are having great times at
[Guiato](http://www.guiato.com.br).

What I bring today is the set of tools I'm using nowadays for developing
Grails and Clojure at work. 

Editor (gVim with Janus)
======
I used [Sublimetext](http://www.sublimetext.com/) for almost two years at home and at work. I really like it, but if I understood well, the version 3 is available for purchasing only. And, you know, you have a `vim` editor. Why not?

Ok, pure `vi` is too much for most people, so put some sauce and you have
a Sublimetext like `vim` editor, or even more powerful. Just use [Janus](https://github.com/carlhuda/janus) for it and combine with gVim.

It comes with nice color scheemes and lots of plugins. The plugins I use
more often are:

   1. [CtrlP](https://github.com/kien/ctrlp.vim). This is exactly like
       Control P at Sublime and allows you search your entire project.
   1. [NERDTree](https://github.com/scrooloose/nerdtree). Simply can't
       live without it. It is your project browser.
   1. [BufferGator](https://github.com/jeetsukumaran/vim-buffergator).
      To browse between all your open buffers
   1. [Tagbar](https://github.com/majutsushi/tagbar). The campion! This
      is your code outlook similar to what popular IDEs offer.

There is a nice support for [Git](http://git-scm.com/), but I stay at pure command line.

Get it up and running is fairly easy. Don't waste time, go set up yours.

Just a note: Tagbar works perfect for clojure, but I work mainly with
groovy and Grails, so you can set ctags to recognize `.groovy` content:

``` bash ctags for groovy
--langdef=groovy
--langmap=groovy:.groovy
--regex-groovy=/^[ \t]*[(private|public|protected) ( \t)]*[A-Za-z0-9_<>]+[ \t]+([A-Za-z0-9_]+)[ \t]*\(.*\)[ \t]*{/\1/f,function,functions/
--regex-groovy=/^[ \t]*def[ \t]+([A-Za-z0-9_]+)[ \t]*\=[ \t]*\{/\1/f,function,functions/
--regex-groovy=/^[ \t]*private def[ \t]+([A-Za-z0-9_]+)[ \t]*/\1/v,private,private variables/
--regex-groovy=/^[ \t]*def[ \t]+([A-Za-z0-9_]+)[ \t]*/\1/u,public,public variables/
--regex-groovy=/^[ \t]*[abstract ( \t)]*[(private|public) ( \t)]*class[ \t]+([A-Za-z0-9_]+)[ \t]*/\1/c,class,classes/
--regex-groovy=/^[ \t]*[abstract ( \t)]*[(private|public) ( \t)]*enum[ \t]+([A-Za-z0-9_]+)[ \t]*/\1/c,class,classes/
```

Search
======

CtrlP is great, but you are not always with your vim open or with
your project open. For this, linux offers grep and find. But waht is
[beyond grep](http://beyondgrep.com/)? There is `ack-grep`! 

Believe me you'll love it. It is extremely practical, fast and developer
focused. So you don't even need to open gVim. Just seach, find edit and
commit!

The extra config for `ack-grep` is a new extension for groovy type and
also support for [Puppet](https://puppetlabs.com/) manifests and
templates.

``` bash puppet types 
--type-add=groovy=.gsp
--type-set=puppet=.pp,.erb
```

Fishing the Shell
================

Lots of friends call me crazy because I invest time in
[Clojure](http://clojure.org) and use it as much as I can. Also because
I left behind "rich" IDEs like Eclipse or IntelliJ IDEA. But come on, you
are a senior developer and you should be able to laugh on any IDE's
face. Even if you were coding Java.

But ok, I'm here to talk about [Fish Shell](http://fishshell.com/). This
is my most recent acquisition. Scripting it is
easy like candy. Check the
[tutorial](http://fishshell.com/tutorial.html).

I've added [few scripts to](https://gist.github.com/paulosuzart/5614350) easy connect to a bunch of machines I have to
everyday. And adding some color for git is also easy, check [this
post](http://zogovic.com/post/37906589287/showing-git-branch-in-fish-shell-prompt).


Well, hope you enjoy the tool set. Any news I'll let you know. Thanks
for reading.

