---
layout: page
title: DataWald Overview (Magento 2 <--> SAP B1)
date: 2016-11-08 18:05
summary: DataWald Overview (Magento 2 <--> SAP B1).
categories: SAPB1 Magento2
---
### Synopsis
DataWald is an integration platform built top on Python Flask, Python Celery, MongoDB and RabbitMQ. Its RESTful web service is developed based on Python Flask framework with flask_restful extension to provide the protocol for the communication within components of DataWald. Its distribution of asynchronous tasks is based on Python Celery within RabbitMQ for the high-volume scalibility.
The architecture is divided the system into Frontend and Backoffice, two main parts. Frontend is much related to business engagement such as eCommerce. Backoffice is much more focused on operation process such as financial accounting, shipment process and inventory management etc.
The structure is designed to be scalable with high-volume data processing and extendable to support variety of applications. Within this article, we apply Magento 2 as Frontend and SAP B1 as Backoffice.

### Architecture
![Architecture](/images/2016-11-28_16-18-32.png)
### Docker Containers
* datawald_apache: A Python Flask application at Apache WSGI on CentOS 6.
* mongodb: MongoDB 3 on CentOS 6.
* rabbitmq: RabbitMQ 3 on CentOS 6 to support Python Celery asynchronous tasks.

### DataWald
The main control core engine which provides the RESTful interface for the communication between each component, stores data into MongoDB as staging data storage, and utilizes Python Celery with RabbitMQ to dispatch asynchronous tasks.

#### Frontend
![Frontend](/images/2016-11-28_16-18-33.png)
* datawald_frontend: An abstract class to do extract transform load for integration logic.
* datawald_mage2agency: A class inherited from datawald_frontend implements the integration logic for Magneto 2.
* datawald_mage2agent: A class inherited from datawald_mage2agency. For customization of projects, the modification will be applied in the class.
* flask_mage2connector: The module is used to communicate with Magento 2.
* flask_dwconnector: The module is a bridge to connect with the DataWald core engine.

#### Backoffice
![Backoffice](/images/2016-11-28_16-18-34.png)
* datawald_backoffice: An abstract class that is used to prepare and process data for the backoffice application.
* datawald_b1agency: A class inherited from datawald_backoffice implements the data process integration logic for SAP B1.
* datawald_b1agent: A class inherited from datawald_b1agency. For customization of projects, the modification will be applied in the class.

#### SAP B1 RESTful
A module attached top on SAP B1 provides the RESTful web service for integration. (Please refer the following links for the detail).
* [How to use SAP B1 RESTful to integrate with eCommerce Platforms](/sapb1/2016/10/28/SAP-B1-RESTful-integrate-with-eCommerce/)
* [SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful)
* [Flask SAPB1](https://github.com/ideabosque/Flask-SAPB1)

### Practice Examples
[Orders Sync from Magento 2 to SAP B1 by DataWald.](/sapb1/magento2/2016/11/12/Orders-Sync-from-Magento-2-to-SAP-B1-by-DataWald/)