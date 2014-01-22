---
layout: post
title: "My Contribution to Puppet Forge"
date: 2014-01-21 20:25
comments: true
categories: puppet devops
---

Happy new year! This time I would like to share with you that I've just shared a [Puppet](http://puppetlabs.com/puppet/puppet-open-source) module at [Puppet Forge](http://forge.puppetlabs.com/). That is awesome!

As you may know, I'm using puppet to manage my own manage resources. You can find all these manifestes my git hub at [https://github.com/paulosuzart/puppet](https://github.com/paulosuzart/puppet). There you'll basically see some resources to setup, update and keep a bunch of packages and and configurations. That sort of thing you don't wanna miss next time you format your laptop, or when you evolve the current one.

Examples are installation of postgresql, postgis, git, change your prompt, configure your git, install clojure lein, create python virtual env and its packages, install and update [GVM](http://gvmtool.net/) packages.

Well, as many other communities, puppet users can share their code with anyone interested on it. For example, my manifests uses really nice community modules such as [apt](http://forge.puppetlabs.com/puppetlabs/apt), [wget](http://forge.puppetlabs.com/maestrodev/wget) and many others.

After looking for a module to install GVM and its packages, I've found nothing. At this point I had created my own module that I than decided to share.

The process of [creating and publishing a module](http://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html) is quite straightforward. So anyone can share modules, but good to be responsible and take care of compatibility, etc. Any way, this is up to you either user or not a community module.

What was used
-------------

The module itself relies on `wget` to grab the GVM setup file from the internet, and then install it and download packages needed by the user. So it is mostly [`exec`](http://docs.puppetlabs.com/references/latest/type.html#exec) commands.

The most interesting part is how to prevent some `exec` block to run. Below you see a piece of `package.pp` that is responsible for setting a given package as default. But this step is not needed if a the package is already the default.

To prevent it to run, one can use `unless` attribute from `exec` command. It basically runs some piece of code that should return 0 to allow this `exec` to be ran.

{% highlight puppet %}
exec {"gvm default $name" :
  environment => "HOME=$user_home",
  command     => "bash -c '$gvm_init && gvm default $name $version'",
  user        => $owner,
  path        => '/usr/bin:/usr/sbin:/bin',
  logoutput   => true,
  unless      => "test \"$version\" = \$(find $user_home/.gvm/$name -type l -printf '%p -> %l\\n'| awk '{print \$3}' | awk -F'/' '{print \$NF}')"
}

{% endhighlight %}

Sometimes you have to find the most crazy commands to prevent something to run. But good that you go deep into linux. In this case, GVM creates a `symlink` from the package version to a folder named `current` under the installed package folder. So, if such link exists for the given `$verion`, it is already the default verion and not needed to run this resource.

This project you can find on this Github repo: [https://github.com/paulosuzart/gvm](https://github.com/paulosuzart/gvm). Hope people in the community can use and contribute.