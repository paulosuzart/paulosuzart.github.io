---
layout: post
title: "Docker + Ansible"
date: 2013-08-21 23:21
comments: true
categories: [virtualization, automation]
---
Hi! This form for blog posts title is working! Liked it.

Again some time without writting. And this time I'm writting about
something brand new: [Docker](http://www.docker.io/).

It lies in the virtualization context. You can read more at [docker
documentation](http://docs.docker.io/en/latest/). And from my point of
view, it comes to kill some important challenges me and you have been
facing over years when talking about delivering software.


PaaS
====

As [stated around](http://blog.docker.io/2013/07/excited-to-be-joining-the-great-teams-at-dotcloud-docker-as-ceo/)
PaaS often fail to cover every necessity you might have. Because they are closed black boxes where you "commit your code in", or something like that. I really like [heroku](http://heroku.com) and [dotCloud](https://www.dotcloud.com/), but yes, I have apps that can't run there.

Ordinary virtualization, another fit for Docker
===============================================

I've been using [XenServer](http://www.citrix.com.br/products/xenserver/overview.html) to handle massive amount of requests distributed over dozens of machines and it works pretty well. But after using it for a while I have detected some extra "disadvantages" (I'm puting quotes because it is really specific) of this type of virtualization to add to [this list](https://github.com/dotcloud/docker). Here they are:

   - The sysadmin should be involved since he needs to access the Xen Center in order to create machines
   - The developer needs to inform beforehand the amount of CPU cores, disk size and memory
   - This involves an all-new machine created with a full operating system, configurations, etc. No time for that!
   - Sysadmins are busy and don't like to give you attention

Not only that, but many cases crating a full virtualized machine to setup a simple wordpress, or few simple stuff doesn't pay off. For this sort of situation I'm addopting Docker.

The main advantages of container virtualization (like Docker) are:

   - Platform-as-a-Service like environment. You don't need to think about anything else but run the process in charge of your application. No worries with an entire machine
   - Make your app immediately available. No boot time needed. Just `docker run` and you are in
   - Run it over a virtualized Xen machine and you still hold all advantages of XEN in the host level (snapshot, live migration, volume management, etc)

Add to the recipe the idea behind [12 factor apps](http://12factor.net/) and
you are done! With Docker you can create the folowing workflow:

   1. Developers create a Docker container, commits it to a Docker index or even give you a `Dockerfile`
   2. Since it is a 12factor app, it is supposed detect resources configuration from the environment it runs
   3. Move your container around development, staging and live envs

Excellent, but still a missing piece.

Ansible
=======

Ok, call me crazy: *"You've been using [Puppet](http://puppetlabs.com/)
for more than 1 and a half year, why are you talking about
[Ansible?](http://www.ansibleworks.com/)"*. It is simple. Well, Ansible
is also simple, but I mean, it is simple to know why Ansible. Just look
to step 1 above. See?

Puppet is too much for you to set up your container. Ansible is fine.

You need to be repeatable while setting up containers. You cannot deliver a container with Tomcat 7 plus OpenJDK 1.7 today, and tomorrow deliver Tomcat 6 for the same app. You need consistency archieved through repeatability. Ansible can also give it to you.

Although Docker allows you for commiting images to a repository, you still need to set them up from scratch without
forgeting any detail. Otherwise your app wont't work properly.

Ansible is a direct competitor of Puppet. But with a simpler approach and good enough to run on every server you manage. I tried this combination and approved. Awesome!

The step one above now could be rewritten like: 

   1. Developers - with the help of sysadmins or not - create a container and set it up with Ansible. Then commit it to the repository and you can even forget  the `Dockerfiles` (or keep a very minimal one)

I'm absolutely sure Docker will solve many things but bring lots of discussions/patterns about how to solve the problems it is supposed to.

Future
======

Projects like [CoreOS](http://coreos.com/) and [Flynn](https://flynn.io/) literally give you the real notion about what I'm talking. I don't think PaaS or IaaS will die, absolutely not. But a new room is needed for sure.

I have both Docker and Ansible running production stuff and hope I can share some `Playbooks` and `Dockerfile`s in the near future.


