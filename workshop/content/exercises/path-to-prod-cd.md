##### Image Provider

To be able to get all the benefits our application Kubernetes provides, we have to containerize it.

The most obvious way to do this is to write a Dockerfile, run `docker build`, and push it to the container registry of our choice via `docker push`.

![](../images/dockerfile.png)

As you can see, in general, it is relatively easy and requires little effort to containerize an application, but whether you should go into production with it is another question because it is hard to create an optimized and secure container image (or Dockerfile).

To improve container image creation, **Buildpacks** were conceived by Heroku in 2011. Since then, they have been adopted by Cloud Foundry and other PaaS.
The new generation of buildpacks, the [Cloud Native Buildpacks](https://buildpacks.io), is an incubating project in the CNCF which was initiated by Pivotal (now part of VMware) and Heroku in 2018.

Cloud Native Buildpacks (CNBs) detect what is needed to compile and run an application based on the application's source code. 
The application is then compiled and packaged in a container image with best practices in mind by the appropriate buildpack.

The biggest benefits of CNBs are increased security, minimized risk, and increased developer productivity because they don't need to care much about the details of how to build a container.

**TODO: Paketo buildpacks and see it live via pack CLI**

With all the benefits of Cloud Native Buildpacks, one of the **biggest challenges with container images still is to keep the operating system, used libraries, etc. up-to-date** in order to minimize attack vectors by CVEs.

With **VMware Tanzu Build Service (TBS)**, which is part of TAP and based on the open source [kpack](https://github.com/pivotal/kpack), it's possible **automatically recreate and push an updated container image to the target registry if there is a new version of the buildpack or the base operating system available** (e.g. due to a CVE).
With our Supply Chain, it's then possible to deploy security patches automatically.

In the details of the Image Provider step in **TAP-GUI**, you're able to see the **logs of the container build and the tag of the produced image**.
It also shows the reason for an image build. In this case, it's due to our configuration change. As mentioned, image builds can also be triggered if new operating system or buildpack versions are available.
This shows another time the benefit of Cartographer's asynchronous behavior.

###### Dockerfile-based builds

For those few use-cases, no buildpack is yet available, and the effort to build a custom one is too high, it's also possible to build a container based on a Dockerfile with TAP. Developers have to specify the following parameter in their Workload configuration where the value references the path of the Dockerfile.
```
apiVersion: carto.run/v1alpha1
kind: Workload
...
spec:
  params:
  - name: dockerfile
    value: ./Dockerfile
...
```
For the building of container images from a Dockerfile without the need for running Docker inside a container, TAP uses the open-source tool [kaniko](https://github.com/GoogleContainerTools/kaniko).

##### Image Scanner

If you **have a closer look at the Image Scanner step in TAP-GUI** you can see that **different CVEs were found than with the source scanning**. 
There are several reasons for that:
- The **container image includes the full stack** required to run the application. In this case, the application, Tomcat application server, Java runtime environment, operating system, and additional tools. 
- The container image also **includes all the dependencies** required to run the application. To reduce disc space and network traffic, those will usually not be committed to the version control system together with the source code and instead defined in dependency management tools like Maven or npm and downloaded during the build process. Most of the **CVE scanners don't download the dependencies** for source code scans, **which leads often to false positives or missed CVEs**, as they only compare what's defined in the definition file of the used dependency management tools (e.g. pom.xml or package.json) with CVE databases. Therefore, they are, for example, not aware of nested dependencies.

You may ask yourself whether there is still a value in source scans. The answer is yes, as **shifting security left in the path to production improves the productivity of developers**.

Due to the false positives, it makes sense to have **different scan policies for source scanning and image scanning**, which is supported by VMware Tanzu Application Platform but not implemented for this workshop.

**TODO: Different ScanPolicies for Source and Image Scan, Image Scan allows everything because developers shouldn't have control over the Image scan**

##### Config Provider, App Config, Service Bindings, Api Descriptors 

The steps between "Image Scanner" and "Config Writer" in the supply chain generate the YAML of all the Kubernetes resources required to run the application.

###### Config Provider

The Config Provider step uses the **Cartographer Conventions** component to provide a means for operators to express their knowledge about how applications can run on Kubernetes as a convention. It supports defining and applying conventions to pods. 

Operators can **define conventions** to target workloads by **using container image metadata**.
Conventions can use this information to only apply changes to the configuration of workloads when they match specific criteria (for example, Spring Boot or .Net apps, or Spring Boot v2.3+). Targeted conventions can ensure uniformity across specific workload types deployed on the cluster.

Conventions **can also be defined** to apply to workloads **without targeting container image metadata**. Examples of possible uses of this type of convention include appending a logging/metrics sidecar, adding environment variables, or adding cached volumes. 

TAP for example applies **Spring Boot conventions** to any Spring Boot application submitted to the supply chain. They modify or add properties to the environment variable `JAVA_TOOL_OPTIONS`, like for example, to configure graceful shutdown and the default port to 8080, and more. 

###### App Config

The App Config step **uses the Pod spec** generated by Cartographer Conventions **for the generation of  YAML for deployment resources**. In the case of a **Workload of type web**, this will be a **Knative Service** which you can see in TAP-GUI in the rectangle for the output of the step. More information on Knative will be provided in the next section.
For **other types of workloads** that don't provide an HTTP endpoint, the generated resources are, for example, a **Kubernetes Deployment and a Service**.

We can have a look at the fully generated YAML in a ConfigMap where it will be stored to be transferred to the next step.
```terminal:execute
command: kubectl get configmap product-service -o yaml | less
clear: true
```

###### Service Bindings, Api Descriptors 
Both steps generate additional resources in YAML format for Service Bindings, which we will cover in the next section, and auto registration of API documentation in TAP-GUI.

##### Config Writer 
After generating the YAML of all the Kubernetes resources required to run the application, it's time to apply them to a cluster. Usually, there is more than one cluster the application should run on, for example, on a test cluster before production.

The Config Writer is responsible for writing the YAML files either to a Git repository for **GitOps** or, as an alternative, packaging them in a container image and pushing it to a container registry for **RegistryOps**.

**The workshop environment is configured for GitOps.**
In the **details view of the Config Writer step in TAP-GUI**, click on the **approve pull request button** that was auto-created by TAP to merge the changes to an in the configuration specified branch of the GitOps repository. 
![Detail view of the Config Writer step](../images/pull-request-button.png)

In this case, the **Git branches are used for staging**, and we are directly merging in the prod branch.
For demo purposes, this pull request was auto-approved and merged.

##### Delivery
With the deployment configuration of our application available in a Git repository, we are now able to deploy it automatically to a fleet of clusters on every change. There are several tools for this job available, like ArgoCD or Carvel's kapp-controller.

**Cartographer** also **provides a way to define a continuous delivery workflow** resource on the target cluster, which e.g. picks up that configuration from the Git repository, deploys it, and runs some automated integration tests, which is called **ClusterDelivery**.

For the sake of simplicity, our application is deployed to the same cluster we used for building it. 

In the next section, you'll get some information about components that are relevant for the running application.