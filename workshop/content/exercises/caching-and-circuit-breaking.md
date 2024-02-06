```dashboard:open-dashboard
name: The Twelve Factors
```

The **fourth and sixth factor** implies that any **data** that needs to be persisted must be **stored in a stateful backing service**, such as a database because the processes are stateless and share-nothing.
A backing service is any service that your application needs for its functionality. Examples of the different types of backing services are data stores, messaging systems, and also services that provide business functionality.

Those backing services are handled as attached resources in a 12-factor app which can be swapped without changing the application code in case of failures.

Let's see how we can make our application even more **resilient to backing service failures**.

##### Caching

Traditional databases, for example, are often too brittle or unreliable for use with microservices. That's why every modern distributed architecture needs a cache!
The [Spring Framework provides support for transparently adding caching](https://docs.spring.io/spring-framework/reference/integration/cache.html#page-title) to an application. 
The cache abstraction **does not provide an actual store**. Examples of Cache providers that are supported out of the box are **EhCache, Hazelcast, Couchbase, Redis and Caffeine**. Part of the VMware Tanzu portfolio is also an in-memory data grid called **VMware Tanzu Gemfire** that is powered by Apache Geode and can be used with minimal configuration.

To **improve the reliability and performance of our calls from the order service to its relational database via JDBC and the product service via REST**, let's add a distributed caching solution, in this case, **Redis**.
With Spring Boot's autoconfiguration, Caching abstraction, and in this case Spring Data Redis, it's very easy to add Caching to the **order-service**.
```editor:insert-lines-before-line
file: ~/order-service/pom.xml
line: 70
text: |2
          <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-cache</artifactId>
          </dependency>
          <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
          </dependency>
```

After adding required libraries to our `pom.xml`, caching, and related annotations have to be declaratively enabled via the `@EnableCaching` annotation on a @Configuration class or alternatively via XML configuration.
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/OrderServiceApplication.java
line: 10
text: |
    import org.springframework.cache.annotation.EnableCaching;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/OrderServiceApplication.java
line: 12
text: |
    @EnableCaching
```

For the REST call to the product service, caching can be added to the related method with the `@Cacheable` annotation and a name for the associated cache.
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
line: 13
text: |
    import org.springframework.cache.annotation.Cacheable;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
line: 30
text: |2
      @Cacheable("Products")
```

For caching of the calls to its relational database, we first have to override all the used methods of the JpaRepository to be able to add related annotations. 
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 8
text: |2
      @Cacheable("Orders")
      @Override
      List<Order> findAll();

      @Cacheable("Order")
      @Override
      Optional<Order> findById(Long id);

      @Override
      <S extends Order> S save(S order);
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 5
text: |
     import org.springframework.cache.annotation.Cacheable;
     
     import java.util.List;
     import java.util.Optional;
```

The cache abstraction not only allows populating caches but also allows removing the cached data with the `@CacheEvict`, which makes for example sense for the save method, that adds a new order to the database.
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 6
text: |
     import org.springframework.cache.annotation.CacheEvict;
```
```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/OrderRepository.java
line: 21
text: |2
      @CacheEvict(cacheNames = {"Order", "Orders"}, allEntries = true)
```

To apply the changes, we have to commit the updated source code and wait until the container is built to update our deployment.
```terminal:execute
command: |
  cd order-service && git add . && git commit -m "Add caching" && git push
  cd ..
clear: true
```

Let's check whether the caching works via the application logs and sending two requests to the API.
```terminal:execute
command: curl https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```
```execute-2
kubectl logs -l serving.knative.dev/service=order-service -f
```
```terminal:execute
command: curl https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```

```terminal:interrupt
session: 2
```

![Updated architecture with Caching](../images/microservice-architecture-cache.png)

##### Circuit Breaker

In distributed systems like microservices, requests might time out or fail completely.
If for example the cache of the product list for our order service has expired and a request to the product service to fetch the product list fails, with a so-called Circuit Breaker, we are able to define a fallback that will be called for all further calls to the product service until a variable amount of time, to allow the product service to recover and prevent a network or service failure from cascading to other services.

[Spring Cloud Circuit Breaker](https://spring.io/projects/spring-cloud-circuitbreaker) supports the two open-source options Resilience4J, and Spring Retry. We'll now integrate Resilience4J in the order service.

First, we have to add the required library to our `pom.xml`.
```editor:insert-lines-before-line
file: ~/order-service/pom.xml
line: 78
text: |2
          <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
          </dependency>
```

To create a circuit breaker in your code, you can use the CircuitBreakerFactory.
```editor:select-matching-text
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: "ProductService(RestTemplate restTemplate) {"
```
```editor:replace-text-selection
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: |2
  private final CircuitBreakerFactory circuitBreakerFactory;
      ProductService(RestTemplate restTemplate, CircuitBreakerFactory circuitBreakerFactory) {
          this.circuitBreakerFactory = circuitBreakerFactory;
```

`CircuitBreakerFactory.create` will create a `CircuitBreaker` instance that provides a run method that accepts a `Supplier` and a `Function` as an argument. 
```editor:select-matching-text
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: "return Arrays.asList(Objects.requireNonNull(restTemplate.getForObject(productsApiUrl, Product[].class)));"
```
```editor:replace-text-selection
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
text: |2
  return circuitBreakerFactory.create("products").run(() ->
              Arrays.asList(Objects.requireNonNull(restTemplate.getForObject(productsApiUrl, Product[].class))),
          throwable -> {
              log.error("Call to product service failed, using empty product list as fallback", throwable);
              return Collections.emptyList();
          });
```
The `Supplier` is the code that you are going to wrap in a circuit breaker. The `Function` is the fallback that will be executed if the circuit breaker is tripped. In our case, the fallback just returns an empty product list. The function will be passed the Throwable that caused the fallback to be triggered. You can optionally exclude the fallback if you do not want to provide one.

```editor:insert-lines-before-line
file: ~/order-service/src/main/java/com/example/orderservice/order/ProductService.java
line: 14
text: |
    import java.util.Collections;
    import org.springframework.cloud.client.circuitbreaker.CircuitBreakerFactory;
```

After pushing our changes to Git, the updated source code will be automatically deployed to production. 
```examiner:execute-test
name: test-that-pod-for-app-exists
title: Verify that deployment happend.
args:
- order-service-00003
```

```terminal:execute
command: |
  cd order-service && git add . && git commit -m "Add circuit-breaker" && git push
  cd ..
clear: true
```

As soon as the updated application is running, we can test the functionality by terminating the product service, and sending a request to the order service. 
```execute-2
kubectl logs -l serving.knative.dev/service=order-service -f
```

```terminal:execute
command: kubectl delete app product-service
clear: true
```

```terminal:execute
command: |
  curl -X POST -H "Content-Type: application/json" -d '{"productId":"1", "shippingAddress": "Stuttgart"}' https://order-service-{{ session_namespace }}.{{ ENV_TAP_INGRESS }}/api/v1/orders
clear: true
```
If everything works as expected the order service should fall back to an empty product list instead, and you should see the log entry `Call to product service failed, using empty product list as fallback`.

```terminal:interrupt
session: 2
```

![Updated architecture with Circuit Breaker](../images/microservice-architecture-cb.png)