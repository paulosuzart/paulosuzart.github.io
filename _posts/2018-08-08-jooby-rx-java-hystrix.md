---
layout: post
title: "Jooby, RxJava and Hystrix"
date: 2018-08-08 10:00
comments: true
categories: [ java ]
---

RxJava is an implementation of [ReactiveX](http://reactivex.io/), the ubiquitus API for dealing with reactive streams. There are much more languages supporting the API, including .NET, Scala and Others.

Combine it with lightweight and modular web frameworks like [Jooby](https://jooby.org/), and we may be facing one of the best combos possible nowadays. Add to this recipe a good circuit breaker and you are good to go. Let's take a quick look.

<!--more-->

Recently, more and more teams are choosing the path of building microservices around streams, possibly unbounded, of data flowing through them. Take a look at this excellent article by Jonas Bonér to get more on this: [What is a reactive microservice?](https://www.oreilly.com/ideas/what-is-a-reactive-microservice).

It is not uncommon to have a sort of API Gateway that takes requests from a frontend or other clients and have to call other dozen of services to be able to assemble the required response. This requires parallel, non-blocking interactions with services upstream.

# A playground case scenario

Let's try to emulate something like this by combining Jooby, RxJava and Hystrix to create a service that will query in parallel the temperature of several cities at once and return the average of the successful queries.

Jooby works with Guice for Dependency Injection. So let's create a Jooby Module to handle the services, controllers and configurations for us:

***Note:** The code snippets shown here are modified versions of the source code available [here](https://github.com/paulosuzart/rx-jooby-weather).*

```java
public class WeatherModule implements Jooby.Module {

    @Override
    public void configure(Env env, Config conf, Binder binder) {
        binder.bind(AsyncHttpClient.class).toInstance(asyncHttpClient());
        env.router().use(WeatherAvgController.class);

        env.lifeCycle(WeatherAvgService.class);
        env.lifeCycle(WeatherClient.class);

        env.router().err(IllegalArgumentException.class, (req, res, err) -> {
            log.error("Unable to process request due to: {}", err.getCause().getMessage());
            res.send(Results.with(new UnableToProcessMessage(), Status.BAD_REQUEST));
        });

        env.onStop(registry -> {
            AsyncHttpClient client = registry.require(AsyncHttpClient.class);
            client.close();
        });
    }
}
```

We first bind a instance of `AsyncHttpClient` to a instance provided by the excelent [AsyncHttpClient](https://github.com/AsyncHttpClient/async-http-client) Dsl itself (see `asuncHttpClient`). Notice a jooby lifecycle listener closing the `AsyncHttpClient` on shutdown.

Then we register our single controller of our service using `eng.router()` and to sum up, we register our two services `WeatherAvgService` and `WeatherClient`, responsible for doing the calculation and for fetching the current weather information by city respectively.

Using `env.lifeCycle` to handle service instantiation/register allows use to use `@PostConstruct` and `@PreDestroy` in our services.

There is a custom error handling here. In case of failures (see below), the hystrix command will fallback to an empty `Observable` and if all requests to our weather data provide fails, there will be nothing to compute. In this case a `IllegalArgumentException` by the average double operator.

To bind everything together our jooby application is super simple. It registers the [Rx](https://jooby.org/doc/rxjava/) module, the [Jackson](https://jooby.org/doc/jackson/) module and finally our own module.

```java
public class App extends Jooby {

  {
    use(new Rx());
    use(new Jackson());
    use(new WeatherModule());
  }

  // ... 
```

With this configuration in place we can inject the `WeatherAvgService` in our controller. Not only that, we can make our controller return an RxJava `Observable` without having to subscribe to ir or map it to another deferrable type (*by the way also supported by jooby*).

```java
@Path("/weather/avg")
@Singleton
public class WeatherAvgController {

    @Inject
    private WeatherAvgService weatherAvgService;

    @GET
    @Consumes("json")
    @Produces("json")
    public Observable<AvgResult> avg(List<String> cities) {
        return weatherAvgService.getAvg(cities);
    }
}
```

Nice and clean controller with appropriate injection of our service. The service was implemented in a exagerated way. Lets recap: the intention was to grab temperature information in parallel and return a json body that describes the cities that successfully returned temperatures and the average temperature.

# The service

The trick here is that we need to hold the list of cities returning temperatures whilst let Rx compute the average. There are many ways to do this, but for learning purposes, let's use the didactic although not necessarily the best:

```java
// WeatherAvgService.java

    public Observable<AvgResult> getAvg(List<String> cities) {

        Observable<TemperatureResult> results = Observable.from(cities)
                .flatMap(weatherClient::getTemperatureByCityName);

        return results.toList().flatMap(temperatureResults -> {
            Observable<Double> temperatures = Observable
                .from(temperatureResults)
                .map(TemperatureResult::getTemperature);

            Observable<List<String>> validCities = Observable
                .from(temperatureResults)
                .map(TemperatureResult::getCity).toList();

            Observable<Double> avgObservable =
                    MathObservable
                            .averageDouble(temperatures);
            
            return avgObservable
                .zipWith(validCities, (avg, citiesList) -> new AvgResult(c, avg));
        });
    }
```

The first `result` holds the observer that will be emitting a `TemperatureResult` for each city that is valid according to our weather info provider. This means invalid city names will be silently ignored. Now pay attention how we use `toList` to accumulate all results in a list, and we continue to use `Observable`s to create a list of city names that were processed and finally combining the list of cities processed with the average calculated by the Rx provided `averageDouble` operator.

Again, we could have accumulated the cities and the average in a different way, but this is enough and shows us how we can combine `Observable`s to chain processing in a powerful way.

# The Hystrix Command

But how invalid requests to our service provider are being handled? The code looks plain with few or no handling of errors at all. The trick is in our `weatherClient` that uses a Hystrix Command to handle that. Take a look:

```java
// WeatherClient.java

    public Observable<TemperatureResult> getTemperatureByCityName(String city) {

        BoundRequestBuilder builder = asyncHttpClient.prepareGet(String.format(byNameTemplate, city, this.apiKey));
        return new WeatherCommand(builder, city).toObservable()
                .flatMap(body -> Observable.just(new TemperatureResult(city, body.get("main").get("temp").asDouble())));
    }
```

Please check the command implementation with fallback: [WeatherCommand](https://github.com/paulosuzart/rx-jooby-weather/blob/master/src/main/java/suzart/jooby/clients/openwheather/WeatherCommand.java).

In this case our Hystrix command returns a `JsonNode` in case of success call and all our service does is extract the temperature field from the returning json. Notice that the command could be returning the AssyncHttp `Response` for example. It is up to the scenario to choose the best option and decide where we want to rely on Hystrix features. In this case the command also has a fallback to return a empty `Observable`  for failed requests.

Now if you have cloned the repo and have started the app, just do a 

```
curl http://localhost:8080/weather/avg?cities=Berlin&cities=London
``` 

and you should see something like: 

```json
{
    "cities":["Berlin","London"],
    "avg":289.685
}
```

# Conclusion

The whole code is available in [this repository](https://github.com/paulosuzart/rx-jooby-weather).

Simple like that! Sometimes I see projects like Jooby or [Javalin](https://javalin.io/) as the new Spring. Remember 10 years ago when JEE was so bloated, heavy and confusing and everybody liked how Spring was tackling the Enterprise Software challenge? Today we have Spring still as a great option but new players are getting to the market what is great!

In today's software world something like Hystrix, [Istio](https://istio.io/) and others are becoming the common case. There is a Hystrix inspired lib for Node.js as well, it's called [hystrixjs](https://www.npmjs.com/package/hystrixjs).

We can be talking about millions in loss if we don't provide robust application that can handle upstream services failure.

Not only that, non-blocking async way of life is the de facto standard.

Happy Reactive!