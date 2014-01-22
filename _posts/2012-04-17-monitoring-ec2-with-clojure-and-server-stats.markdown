---
layout: post
title: "Monitoring ec2 with clojure and Server-Stats"
date: 2012-04-17 17:25
comments: true
categories: clojure cloud aws
---

Intro
------
Before going further, please take a look at [Parallel SSH and system monitoring in Clojure](http://info.rjmetrics.com/blog/bid/54114/Parallel-SSH-and-system-monitoring-in-Clojure). 

Combining my need for monitoring an EC2 instance running [nginx](http://nginx.org), [bamboo](http://www.atlassian.com/software/bamboo/overview) and [artifactory](http://www.jfrog.com/products.php), with my will to code in clojure, I have decided to use [server-stats](https://github.com/paulosuzart/Server-Stats) to basic monitor my server via ssh.

EC2 supports interactions using SSH without need its `.pem` file if you add your public key to it. Take a look [here](http://craiccomputing.blogspot.com.br/2009/07/rails-git-capistrano-ec2-and-ssh.html) to see how.

These are dead simple commands and of course you should use more serious ones for critical services.

The `server-stats` config file is actually a clojure file named `server-stats.cfg` where you put some definitions for monitoring. The strength of server-stats is the running it against several server. But in this case, I have just one.

The config file
---------------

``` clojure server-stats.cfg

(import org.apache.commons.mail.SimpleEmail)


(defn send-mail [alert-msg server-name cmd-output]
    (doto (SimpleEmail.)
     ;; ... my email configs
      (.send)))

(add-alert-handler email [alert-msg server-name cmd-output]
  (send-mail alert-msg server-name cmd-output))

(set-ssh-username "ec2-user")

(add-server-group web-servers
  ["myserver.mydomain.com"])
   
(add-cmd disk 
  {:doc "Get the disk usage using df"
   :cmd "df -h"
   :servers [web-servers]
   :alerts [{:column "Use%"
             :value-type percent
             :handlers [email]
             :msg "Disk space over 55% full"
             :trigger (> 55)}]})

(add-cmd is-nginx 
  {:doc "Is nginx Running?"
   :servers [web-servers]
   :cmd "[[ -z `ps aux | grep nginx` ]] && echo 'false' || echo 'true'"
   :alerts [{:value-type bool
             :msg "Nginx is not running"
             :handlers [email]
             :trigger (= false)}]})

(add-cmd app-log
  {:doc "Get last 20 entries in todays app-servers log"
   :servers [web-servers]
   :cmd "tail -20 /home/ec2-user/artifactory-2.5.1.1/logs/access.log"})

(add-cmd http-errors
  {:doc "Show recent non-200s requests"
   :servers [web-servers]
   :cmd "tail -200 /var/log/nginx/error.log"})

(add-cmd is-artifactory
  {:doc "Is Artifactory Running?"
   :servers [web-servers]
   :cmd "[[ -z `ps aux | grep org.artifactory.standalone.main.Main` ]] && echo 'false' || echo 'true'"
   :alerts [{:value-type bool
             :msg "Artifactory is not running"
             :handlers [email]
             :trigger (= false)
             :mute-for 1860000}]})
 
(add-cmd is-bamboo
  {:doc "Is bamboo Running?"
   :servers [web-servers]
   :cmd "[[ -z `ps aux | grep com.attlassian.bamboo.server.Server` ]] && echo 'false' || echo 'true'"
   :alerts [{:value-type bool
             :msg "Bamboo is not running"
             :handlers [email]
             :trigger (= false)
             :mute-for 1860000}]})

```

Almost all the commands were borrowed from the sample `cfg` file. A small but important detail is the key `:mute-for` in alerts. As you can see, the above link to server-stats points to my fork of it.

The [`mute-for`](https://github.com/RJMetrics/Server-Stats/pull/2) key adds the capability to prevent any scheduled `ssh` commands with short intervals to flood your alert communication channel (e-mail in this `cfg`). The alerts are sent only if the `mute-for` time has been elapsed.

This is done via empty files for controlling the alerts. `server-stats` checks the `lastModified` property of the file of a given alert, and activates the it only if the `mute-for` interval is over. 

To make server-stats send alerts before the `:mute-for` time, you can just delete the file named `.{Sanitized_alert_message}`. The sanitized message is just the message alert message with no characters as underlines. I should consider a hash version of it to avoid big names for big messages, but it is ok for now.

**Note that `mute-for` controls the alert activation per `cmd` message.**

Use cron
--------

Of course you can't spend your time issuing ssh commands by hand. So, there are four `cron` entries for scheduled ssh interactions:

``` bash crontab

0 7 * * * SSH_AUTH_SOCK="$(find /tmp/keyring*/ -type s -user paulosuzart -group paulosuzart  -name 'ssh*' | head -n 1)" ~/workspace/p/Server-Stats/run.sh disk -log
*/10 * * * * SSH_AUTH_SOCK="$(find /tmp/keyring*/ -type s -user paulosuzart -group paulosuzart  -name 'ssh*' | head -n 1)" ~/workspace/p/Server-Stats/run.sh is-nginx -log
*/30 * * * * SSH_AUTH_SOCK="$(find /tmp/keyring*/ -type s -user paulosuzart -group paulosuzart  -name 'ssh*' | head -n 1)" ~/workspace/p/Server-Stats/run.sh is-artifactory -log
*/30 * * * * SSH_AUTH_SOCK="$(find /tmp/keyring*/ -type s -user paulosuzart -group paulosuzart  -name 'ssh*' | head -n 1)" ~/workspace/p/Server-Stats/run.sh is-bamboo -log
 
```

The `run.sh` is pretty simple. Just wraps `java -jar` to server-stats. Some times I want to log the ssh output, so I can pass the `-log` option and the output goes to `log/cmd`.

``` bash run.sh
#!/bin/bash
# Wraps the start of server-stats. If -log is passed, will save
# the resulting execution to log/cmd
# paulosuzart@gmail.com

# java -jar should run from inside the server-stats dir
cd ~/workspace/p/Server-Stats 

if [ -z $1 ]; then
  echo "usage: run cmd [-log]"
  exit 2
fi

COMM="java -jar server-stats-0.1-standalone.jar -a $1"
if [[ ! -z $2 && "-log"=$2 ]]; then
  echo "logging to log/$1.out"
  $COMM=$COMM:" > log/$1.out"
fi

echo $COMM
$COMM

```

Don't ask me why, but `ssh` does not behave the way you except when called from a `cron` command. But I managed to find [this article](http://webcache.googleusercontent.com/search?q=cache:7h4hOIGZG-wJ:www.codealpha.net/163/cron-ssh-and-rsync-and-key-with-passphrase-ubuntu/+&cd=1&hl=en&ct=clnk&client=ubuntu
) that helped a lot.

This `crontable` is configured on my laptop and any strange behavior is sent to my e-mail immediately. The other `cmds` (`app-log`, `http-errors`) are used directly with `./run.sh cmd` to see the output.

Conclusion
----------

Of course the `mute-for` feature [might be merged](https://github.com/RJMetrics/Server-Stats/pull/2) to the original repo. So, I would recommend you to use the original version of server-stats.

If you need simple monitoring features or more elaborated ones, it is up to you. Just use server-stats as the  base for it.


Update
------

This post was republished [Dzone](http://www.dzone.com). See [here](http://architects.dzone.com/articles/how-monitoring-ec2-clojure-and).

