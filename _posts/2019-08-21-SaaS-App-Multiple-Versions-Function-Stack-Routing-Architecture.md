---
layout: post
title: SaaS App Multiple Versions Function Stack Routing Architecture
date: 2019-08-21 11:06
summary: SaaS App Multiple Versions Function Stack Routing Architecture.
categories: BigCommerce Shopify
---
The architecture is built to allow multiple versions of the function stack.  Within the design, multiple versions of the stack could be routed by the configuration of each store.
![Architecture](/images/2019-09-09_12-18-01.png)
1.	Version release will be managed by the three parts.
    - AWS API Gateway (RESTful)/AWS AppSync API version (GraphGL).
    - Dynamic load modules by parameter.
    - Deploy the new version of stack under a new AWS account if there is any data schema changed.
2.	Core Stack will store the data related to configuration, access (BC access token), module names and stack routing.
3.	Each store will be routed to the version stack which is registered in the Core Stack for the store.
4.	If a new version with data schema is released, a new version of the function stack will be deployed within a separated AWS account by AWS Cloudformation.  The data of each store will be migrated one store by one store into the new stack.  After the data migration, the updated routing path will redirect the traffic to the new stack for the store.  AWS Data Pipeline could be utilized for the data migration (https://docs.aws.amazon.com/datapipeline/latest/DeveloperGuide/dp-importexport-ddb.html).
5.	Simply the architect for backend and frontend with REACT JS and AWS API Gateway only.
6.	JWT token support to replace session management for backend app.
7.	We can add more functions for specific extended modules to support more advanced functions with higher price.
8.	Also, we can also add special version stack for the project driven stack for special account under a single tenant AWS account.

