---
layout: post
title: "Watching Bitcoing price with Typescript and Typedi"
date: 2017-11-25 13:58
comments: true
categories: [ node.js, typescript, bitcoin ]
---

In my [last post](http://paulosuzart.github.io/blog/2017/10/04/type-safety-orm-and-dependency-injection-node/) I presented a summary of Typescript ecosystem and some important players in the field like [`typedi`](https://www.npmjs.com/package/typedi). In this post we'll check `typedi` features and to make things more interesting, let's create a simple [Cex.io](https://cex.io) client to watch for price changes in a given market.

<!--more-->

# Intro

Dependency Inject is pretty old and stable concept in Object Oriented systems. Frameworks like [Spring](https://spring.io/), [.NET MVC](https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/dependency-injection), and others, offer DI (dependency injection) feature since long ago (I would bet 10+ years).

Although pretty common in ecosystems like Java, It is worth it a try in Node.JS for sure. Me myself faced many situations where I had to work with singleton objects or take care of instantiating objects inside a request, etc, etc.

`typedi` makes it easy to connect different objects with their own requirements. And for the impatient, the full code is available on [github repo](https://github.com/paulosuzart/btc_example).

# A Price Service

Lets create what will be the interface of our service. This is not required at all, but I'm using it to show a neat feature of `typedi`: Service Injection using service names.

Our service offers a `current()` method that is supposed to return the latest price of a `market`, a property that can be set in the service.

``` typescript
interface PriceService {
    current(): Promise<number>;
    market: string;
}
```

Here the thing start to get interesting. We can have a collection of `PriceService` and pick up the right implementation at runtime. So, remember - *according to the title of this blog post* - that we want to watch price changes at Cex.io Exchange. But frist lets implement a fake Bittrex service according to the interface?

``` typescript
@Service("bittrex")
class BittrexPrice implements PriceService {
    constructor() {
        console.log(colors.rainbow("Creating Bittrex client"));
    }

    set market(mkt: string) {
        console.log("setting market");
    }
    current(): Promise<number> {
        return Promise.resolve(23.99);
    }
}
```

This does nothing and return a fixed price `23.99`. A real implementation can be left as a exercise for the reader. The think I want you to pay attention here is the `set` keyword. It marks a function as a proprety setter this way a code like: `somePriceServiceInstance.market = "BTC-USD";` will work as expected. Also pay attention to the decorator `@Service("bittrex")`.

# Our Application

Great, now we have a service that can be injected in our `App` class just like this:

{% highlight typescript linenos %}
const appFactory = () => {
  if (process.argv.length < 3) {
      return new App("BTC-USD");
  }
  return new App(process.argv[2]);
};

@Service({factory: appFactory})
class App {

    @Inject(process.env.EXCHANGE || "cex.io")
    priceService: PriceService;

    private market: string;

    private lastPrice: number;

    constructor(market: string) {
        this.market = market;
    }

    watch() {
        // This could be set via factory. But this example shows set/get
        this.priceService.market = this.market;
        this.query();
        setInterval(async () => {
            await this.query();
        }, 10000);
    }

    private async query() {
        const value = await this.priceService.current();
        if (value > this.lastPrice) {
            console.log(colors.green(`Current price for ${this.priceService.market} is: ${value}`));
        } else {
            console.log(colors.red(`Current price for ${this.priceService.market} is: ${value}`));
        }
    }
}
{% endhighlight %}

Wow, lots of code at once. Lets it breakdown starting by `appFactory` function. This function is known as *factory function* and is responsible to produce a new instance of `App` class when it gets registered inside our `typedi` container. We could have used a more elaborated arg parser here. But I'm assuming users of this application will call it like: `node index.js BTC-USD`. That's why we get the 3rd argument to use as marketing pair and if not, the default is `BTC-USD`.

This is a way to get a instance of the application via `typedi` and leave instantiation details to a factory function. In this case a factory that knows how to set up the target market.

Now lies 11-12 show the injection of a instance of a `PriceService`. This is not known at compile time, instead we query the `process.env` for a variable named `EXCHANGE` and if not set, the default is used: `cex.io`. *Of course in real use we need to handle non existent implementations if for example if the user sets `EXCHANGE` to anything different than the supported exchanges*.

The `App` class provides just single public function called `watch` that is used to poll the selected exchange every 10 seconds.

# Cex.io Client, finally

Now our Cex.io client! It resembles the `BittrexService` as both implement `PriceService` and uses their REST API: 

``` typescript

interface CEXLastPriceResponse {
    curr1: string;
    curr2: string;
    lprice: number;
}

@Service("cex.io")
class CexioPrice implements PriceService {
    private _lmarket: string;
    private _rmarket: string;
    private client: RestClient;

    constructor() {
        console.log(colors.green("Creating Cex.io client"));
        this.client = new RestClient("mozilla");
    }

    set market (market: string) {
        [this._rmarket, this._lmarket] = market.split("-");
    }

    get market() {
        return `${this._rmarket}-${this._lmarket}`;
    }
    
    async current(): Promise<number> {
        if (!this._lmarket || !this._rmarket) {
            throw "please set market first";
        }
        const response = await this.client.get<CEXLastPriceResponse>(`https://cex.io/api/last_price/${this._rmarket}/${this._lmarket}`);
        if (response.statusCode != 200) {
            console.log(response.result);
            console.log(`/last_price/${this._rmarket}/${this._lmarket}`);
            return 0;
        }
        return response.result.lprice;
    }
}
```

Here we have the addition of a property getter called `market()` as you can see the `get` modifier. The `set` function of the `market` property splits it into two strings and associate them to two different attributes using destructuring. *A warning here as we don't handle invalid market formats*.

And of course this services has a http client, in this case a client provided by Microsoft it self called `typed-rest-client`. This client uses interfaces to "cast" rest calls back to objects that matches the provided interface using generics. In this case `CEXLastPriceResponse`.

Now can finally call our `App` by running:

``` typescript
const app = Container.get(App);
app.watch();
```
What should produce a output like this:
```
➜  ts_di git:(master) node dist
Creating Cex.io client
Current price for BTC-USD is: 8731
Current price for BTC-USD is: 8731
```

# Conclusion

There are thousands of exchange clients out there and this is intended to be a learning resource, not a real tool at all. With this example we covered typedi's injection by name and factory functions, constructs that brings flexibility and power to your applications in a very elegant way. We also reviewed interesting features of [TypeScript](https://www.typescriptlang.org/) like property `set` and `get`, destructuring values into multiple variables and smart handling of `this` reference.

Hope you have enjoyed. Happy Typescript!