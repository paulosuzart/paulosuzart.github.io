---
layout: post
title: "Geocoding CSVs with Clojure"
date: 2013-08-26 11:48
comments: true
categories: clojure
---

Hi! Nothing like delivering some value to your company using your preferred tool, hun?

Well, I had this feeling after freeing up my team of writing and writing the same thing again and again. As you can seen at [ultimate-geo project page](https://github.com/paulosuzart/ultimate-geo):



> Ultimate Geo is the final definitive geocoding app. The motivation behind it was: We have different CSVs full of address in the most crazy combinations. Some of them has the street, number, site, phone. while others have same columns in a different order, etc. This led us to keep creating (actually adjusting) our geocode scripts. Now it is over.

Of course it may not fit everyone's needs. But helped my scenario a lot.
<!--more-->
After atending the [(sp (first meetup))](http://www.meetup.com/clj-sp/events/132201232/) I polished this small project called [`ultimate-geo`](https://github.com/paulosuzart/ultimate-geo), given I mentioned it while talking to people.

A general explannation of how `ultimate-geo` works can be found on its project page, but by didactic reasons, here a more detailed explanation:

   1. after parsing each line of a file
   1. it binding each colum to named variables, so they can be latter referenced fo querying google and also for output. Works like in a prepared statement
   1. then replaces `-query` parameter replacing named variables like `:country` or `:city` by their values mapped on step 2.
   1. finally request google address information
   1. and start generating results. Here few tricks are needed because goole can send back more than one results. So it filters the relevat result and pick the first one. From the same result it grabs the zip, if available.

The image bellow depicts the flow of columns through this process:

![ultimate-geo](http://github.com/paulosuzart/ultimate-geo/raw/master/ultimate.png)

All happens lazily. So the code will not parse every single line, and then map all lines, and replace all values, etc. It happens as it goes. The main point to pay attention to is the write phase. This can pop up any exception during the process because it is the point that actually call all the chained lazy values.

Another important piece is [`pmap`](http://clojuredocs.org/clojure_core/clojure.core/pmap) for steps 2, 3 and 4. It means the all he lines are processed in parallel for eatch step increasing the overall performance.

Coding variable replacement was by far the funniest part. Check the [project tests](https://github.com/paulosuzart/ultimate-geo/blob/master/test/geocoder/t_core.clj) and see how useful for other scenarios it can be:

{% gist 6342437 %}

This works fine and is able to ignore `_` mapped columns, meaning they are not relevant and will not be used later.

The tests were written using [Midje](https://github.com/marick/Midje). I like Midje and it helped a lot to refactor the code while writing it specially using `:autotest`. I do recommend a try even if you want to use the basics, like I did.

This project uses other nice libs like [clojure-csv](https://github.com/davidsantiago/clojure-csv) and [clojure/toosl.cli](https://github.com/clojure/tools.cli) that can be presented later.

Hope you liked the post. After the meetup I intend to post more often and focus on what were discussed during the meetings.


