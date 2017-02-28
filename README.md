# springboot-sample-app

[![Build Status](https://travis-ci.org/codecentric/springboot-sample-app.svg?branch=master)](https://travis-ci.org/codecentric/springboot-sample-app)
[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)


## Synopsis

This repository provides a sample [Spring Boot](http://projects.spring.io/spring-boot/) application with the necessary OCP templates and Jenkinsfile for building and promoting it through OpenShift.

#### Includes:
- **src/** folder includes the minimal [Spring Boot](http://projects.spring.io/spring-boot/) app
- **infra/ocp-templates** are the templates for creating the OCP objects
  - **build-config-template.json** is the template for the BuildConfig
  - **ups-maven-s2i-routed-template.json** is the template for the DeploymentConfig, ImageStream, Route, and Service
- **Jenkinsfile** is the pipeline script for building the application in OpenShift and promoting it through different projects
- **ocp-setup.sh** creates the required projects for the pipeline, creates a service account for Jenkins to use, and gives that service account the appropriate permissions across the OCP cluster


## Copyright

Released under the Apache License 2.0. See the [LICENSE](https://github.com/codecentric/springboot-sample-app/blob/master/LICENSE) file.
