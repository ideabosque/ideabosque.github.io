---
layout: post
title: Orders Sync from Magento 2 to SAP B1 by DataWald
date: 2016-11-12 18:45
summary: Orders Sync from Magento 2 to SAP B1 by DataWald.
categories: SAPB1 Magento2
---
The flow demonstrates how orders are synchronized from Magento 2 to SAP B1 by DataWald integration platform. Here are couple elements which play the basic roles to make the flow be rolling.

1. Python Celery Beat is used to schedule the asynchronous tasks.
2. Asynchronous tasks are implemented by Python Celery worker with RabbitMQ.
3. RESTful is the protocol within components of DataWald.

Regarding the system architecture of DataWald, please refer to [DataWald Overview (Magento 2 <--> SAP B1)](/sapb1/magento2/2016/11/08/DataWald-Overview-Magento-2-SAP-B1/).

### Here is the step by step to synchronize orders from Magento 2 to SAP B1.
![Structure](/images/2016-11-12_16-18-32.png)
![Architecture](/images/2016-11-12_16-18-33.png)

#### Step A
Python Celery Beat launches the celery task "syncOrdersChain" that contains two celery tasks "syncOrders" and "updateSyncTask" executed in sequence.

#### Step B
Celery task "syncOrders" is invoked to process the following functions.

**1.** Invoke "/control/cutdt/{app}/{task}" GET method of DataWald RESTful api to get the last cut date for the orders query from Magento2 (flask_dwconnector.getLastCut).

**2.** Get orders from Magento 2 (flask_mage2connector, datawald_mage2agency.feOrdersFtMage2, datawald_frontend.getOrders).

**3.** Invoke "/backoffice/order/{feOrderId}" PUT method of DataWald RESTful api to synchronize the order (flask_dwconnector.syncOrder). Orders will be inserted into MongoDB when orders are sent into DataWald.

**4.** Invoke "/control/synccontrol/{app}/{task}" PUT method of DataWald RESTful api (flask_dwconnector.insertSyncControl). Then, a syncTask is created by DataWald for tracing the task.

**5.** DataWald invokes the Celery task "insertOrder" to process the order with SAP B1.

#### Step C:
Celery task "insertOrder" synchronizes the order into SAP B1.

**6a.** Invoke "/backoffice/orders" POST method of SAP B1 RESTful to check if the order is in SAP B1 or not (flask_b1connector.getBoOrderId).

**6b.** If the order is not in SAP B1, Invoke "/backoffice/order" POST method of SAP B1 RESTful to insert the order into SAP B1 (flask_b1connector.insertOrder).

**7.** Invoke "/backoffice/orderstatus" PUT method of SAP B1 RESTful to update the order sync status back into the MongoDB order entity (flask_dwconnector.updateOrderStatus).

**8.** The return result of the task "insertOrder" will be stored in RabbitMQ and would be able to retrieve asynchronously.

#### Step D:
Celery task "updateSyncTask" will be invoked after celery task "syncOrders" in sequence. The data that is utilized to retrieve the result and check the status will be passed from "syncOrders" to "updateSyncTask". Then, "updateSyncTask" will fetch the result, and status and send the data to update the corresponded syncTask entity in the MongoDB.

**9a.** Invoke "/control/taskstatus" GET method of DataWald RESTful api to check the status of orders (flask_dwconnector.getTaskStatus).

**9b.** Invoke "/control/task" GET method of DataWald RESTful api to retrieve the task result if the task is ready (flask_dwconnector.getTask).

**10.** Invoke "/control/synctask" PUT method of DataWald RESTful api to update the corresponded entity stored in MongoDB (flask_dwconnector.getSyncTask).


