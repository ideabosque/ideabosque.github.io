---
layout: page
title: Dynamic GraphQL Engine (SilvaEngine) with Routing Dispatch Layer
date: 2020-04-22 12:23
summary: Dynamic GraphQL Engine (SilvaEngine) with Routing Dispatch Layer.
categories: AWS-SAM GraphQL
---

## Synopsis
The GraphQL engine (SilvaEngine) provides the capability to delivery multiple versions of functions by the routing dispatch layer with the GraphQL as the API.

## Architecture
![Architecture](/images/2020-04-22_12-26-42.png)

### The Routing Layer:
It is built with an [AWS Lambda](https://aws.amazon.com/lambda/) function **resources** and [AWS DynamoDB](https://aws.amazon.com/dynamodb/) tables to determine which python module and function will be invoked and apply the setting during an engagement.

### The Business Dispatch Layer:
An [AWS Lambda](https://aws.amazon.com/lambda/) function **workers** will dispatch the requests to the python module and function and return the response generated by GraphQL built by [**graphene-python**](https://graphene-python.org/) with the data layer ([AWS DynamoDB](https://aws.amazon.com/dynamodb/)) managed by [**pynamodb**](https://pynamodb.readthedocs.io).

### Github Repository:
[SilvaEngine AWS](https://github.com/ideabosque/silvaengine_aws)