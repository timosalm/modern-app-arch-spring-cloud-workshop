The picture shows a typical microservice application for a supply chain.

![A typical modern app architecture](images/microservice-architecture.png)

- The **product service** only has one REST endpoint to fetch the list of products.
- With the **order service** REST API, clients are able to fetch the current orders that are stored in a MySQL database, and they are also able to create new orders. The product id for a new order is validated with the list of products that will be fetched from the product service via a synchronous REST call.
- After the order is created and stored in the database, information like the shipping address will be sent to the **shipping service** via asynchronous messaging, and after a configurable amount of time (for example 10 seconds), a status update for the DELIVERY will be sent back via asynchronous messaging to be consumed by the order microservice.

All the microservices are implemented using Spring Boot and initially created on https://start.spring.io.

#### Spring by Broadcom 

![](images/spring-logo.svg)

With the acquisition of VMware, Broadcom is now the vendor of Spring, and Spring plays an important role in Broadcom's Tanzu portfolio.

The goal of **Spring** is to simplify and accelerate application development, and due to its autoconfiguration, **Spring Boot** is the foundation for fast development of production-ready applications. 

**Spring Cloud** supports the development of microservice architectures by implementing proven patterns for example for resilience, reliability, and coordination.

With the help of Spring Boot and Cloud, it's possible to mitigate a lot of challenges of our typical microservice application, but regarding the deployment, there is for example still a high effort to manage the cloud infrastructure for the microservice, and the application lifecycle is difficult to manage. 
So-called **application-aware platforms** take on the challenges by abstracting away all platform and infrastructure specifics and give development teams an interface where they only have to define the requirements of the applications they want to run on the platform. 

![Application-aware platforms remove the burden from the developers](images/app-aware.png)

**This interactive workshop aims to teach you how to mitigate the challenges of a typical microservice application with the Spring Cloud (and Boot)!**