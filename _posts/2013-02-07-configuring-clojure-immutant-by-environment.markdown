---
layout: post
title: "Configuring Clojure Immutant by environment"
date: 2013-02-07 08:39
comments: true
categories: [clojure, advanced]
---

Hi again! Not posting for too much long.

Well, this time we will explore the [clojure's](http://clojure.org) ability to [load arbitrary files as code](http://clojuredocs.org/clojure_core/clojure.core/load-file).

This is such an amazing feature, but you should be careful. Don't start reading anyones files and evaluating them into your app. Be wise and use it for specific situation like this: I wanted to load a bunch of configurations (and even funtion calls) depending on the environment my app is running.

To do the conditional evaluation, I decided to add an extra key to `:immutant` entry in my project definition. The entry `:env` is an [arbitrary configuration value](http://immutant.org/documentation/current/initialization.html#sec-3-1). Lets take a look:
<!--more-->
{% highlight clojure %}
(defproject tserver "0.1.0-SNAPSHOT"
  :description "A foo project"
  :url "http://foo.com/"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.4.0"]
                 [compojure "1.0.2"]
                 ;... and many other dependecies
  :jvm-opts ["-Xmx2g" "-server"]
  :immutant {:init "tserver.init/init"} ;; our custo immutant init function
  :profiles {:dev {:immutant {:context-path "/"
                              :nrepl-port 4242
                              :lein-profiles [:dev]
                              :env :dev}}}) ;:dev will identify which config file to load
{% endhighlight %}

In this sample `project.clj` you find `:immutant` directly under the project definition. This key is used to, regardless of the environment, inform immutant which funtion to call when your app starts up. In this case `tserver.init/init`, that we will further analyze.

Pay attention to the `:env` entry. It is located under `:immutant` that is under `[:profiles :dev]`. Here enters a [leiningen's](http://leiningen.org/) [profiles feature](https://github.com/technomancy/leiningen/blob/stable/doc/PROFILES.md). Where you can even specify dependencies or anything you want by profile. In this case, the immutant config is being configured by profile.

**Why not simply load a config per profile?**

Because you can combine *n* profiles at the sime time. So, which one to use as the enviroment reference? That is why I decided to use an specific entry for that.

Below the initial function being called by immutant. Here goes intereting stuff.
One of them is the use of [`in-ns`](http://clojuredocs.org/clojure_core/clojure.core/in-ns), [`use`](http://clojuredocs.org/clojure_core/clojure.core/use) and [`require`](http://clojuredocs.org/clojure_core/clojure.core/require). This is awesome because I'm calling what could be "equivalent to a java import" in the middle of a clojure file, and even better: I'm doing this to another namespace that differs from the code that is actually calling the "imports".

So, `in-ns` will create the namespace `tserver.config` and "import" the appropriate functions and namespaces.

The `init` funtion here will simply call the `load-config`, that is in charge of loading the config file. Look:


{% highlight clojure %}
(ns tserver.init
  (:use [clojure.tools.logging :only (info error debug)]))

(defn setup-config-ns [e]
	(binding [*ns* *ns*]
      (in-ns 'tserver.config)
      (refer-clojure)
      (use '[clojure.main :only (load-script)])
      (require '[immutant.messaging :as msg]
               '[immutant.web :as web]
               '[immutant.util :as util])))

(defn load-config
  "Attempts to evaluate the specified env file defined by `:env`
  in the `project.clj`. `:env` is a immutant custom config.
  `:env` MUST be a keyword: Ex.: :dev, :prod :office
  Uses :dev by default.
  Note: The absence of the requrested file will prevent the server to start.
  These siles MUST be located at `src/tserver/config/%s.clj"
  []
  (binding [*ns* *ns*]
    (in-ns 'tserver.config)
    (let [ev (get-in (immutant.registry/get :config) [:env] :dev)
    	    config-file (format "src/tserver/config/%s.clj" (name ev))]
  	  (setup-config-ns ev)
      (info "Using config file " config-file)
  	  (load-file config-file)
  	  (immutant.registry/put :env ev))))

(defn init []
  ;;may do some stuff before
  (load-config)) ;;may do some stuff after
{% endhighlight %}

And finally, our config file containing the required configurations. It can be anything you need.

{% highlight clojure %}
(defn handler
    [r] ((build-routes) r))

(web/start handler
  :reload true)

(msg/start "/queue/delivery.status")

(msg/respond "/queue/delivery.status" handle-delivery-status)

(register-job #'import-job)
(register-job #'check-import)
;register-job is function not provided here
;since the intention is tho show the configuration solution
{% endhighlight %}

Now, to deploy and start the app with the given profile we simply do:

{% highlight bash %}
lein with-profile dev immutant deploy
lein immutant run
{% endhighlight %}

Voila! This will load your `dev.clj` file and set up your queues, jobs, web-context, whatever you want. This is useful, and I would risk to say mandatory today. You probably have sereval environments where your app resides before going to prodution, and each of them with different names, addresses, pool sizes, queue names, database to connect, etc. And you can easily give to your app the intelligence to load what is more appropriate.
