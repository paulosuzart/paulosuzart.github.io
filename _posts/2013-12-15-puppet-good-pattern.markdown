---
layout: post
title: "Puppet good pattern?"
date: 2013-12-15 21:43
comments: true
tags: [devops]
---

Hi all! First note:
[Puppet](http://puppetlabs.com/) definitely goes beyond what is written here. Also, I'm far from being a puppet specialist, and after posting about [Ansible](http://www.ansibleworks.com/), I'm writing about puppet because it is my main tool.

While translating a Ansible playbook once used to setup a developer machine - if I can call it rewrite - I found myself often using the same patter: Using `create_resources` [function](http://docs.puppetlabs.com/references/latest/function.html#createresources) + pure hashmaps. 
<!--more-->
What a hell?

Well, while defining nodes you use puppet resources to install lots os packages and configure them. Eg.: Create [postgres](http://www.postgresql.org/) databases, install [GVM](http://gvmtool.net/) packages, etc. Then the need "iterate every new package/database and install/create it".

To be fair, puppet doesn't seem to be iteration friend. After a couple of research I found `create_resources` as a good solution for situations you need to repeate the creation of resources. Below an example will help to clarify:

{% gist 7980105 %}

Ok. What is happening? My real intention is to create as many databases as needed in my host. Notice the `pg_databases` parameter passed to `developer_role` class. This contains a map of `database name => $definition` pairs. Where `definition` is actually a map containing the database owner and password.

Then, the `create_resources` will execute a `developer_role::postgres::create_db` resource for every key defined at `$pg_databases`, matching every inner map key to resource variable.

So, instead of iterating every database yourself, or hard coding every call to `postgresql::server::db` defined by [puppetlabs/postgresql](https://forge.puppetlabs.com/puppetlabs/postgresql) you wrap everything in a second resource defined by yourself.

Another good example is the creation of python virtual envs, plus the packages to install in it. These two definitions wraps [puppet-python](https://github.com/stankevich/puppet-python):

{% gist 7980317 %}

Yes, it sounded for me. I'm using it a lot for mostly everything that should be repeatedly defined at node level. If you are a puppet specialist, let me know your opinion.

Hope you can take advantage of this as it seems to be helping me a lot. Merry Christmas!

