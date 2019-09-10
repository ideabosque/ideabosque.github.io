---
layout: post
title: Tasks Management for Asynchronous Processes 
date: 2019-08-21 12:30
summary: Tasks Management for Asynchronous Processes.
categories: BigCommerce Shopify serverless
---
This component is built to manage and process asynchronous processes such as data adding/refreshing.
![Architecture](/images/2019-09-10_12-35-28.png)
1.	Insert a record in task control table when the customer submits a task request.
2.	Invoke the worker to process the task.
3.	The data will be partitioned and processed by invoking the worker itself.
4.	Update the record in task control to see if the task is completed without issues.
