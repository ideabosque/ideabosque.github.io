---
layout: page
title: SAP B1 RESTful integrate with eCommerce
date: 2016-10-28 19:45
summary: How to use SAP B1 RESTful to integrate with eCommerce Platforms.
categories: SAPB1
---
Based on [SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful), it will be possible that an eCommerce platform (such as Magento, WooCommerce, Shopify or BigCommerce…etc) would be able to automatic the business processes with SAP B1 ERP by RESTful protocol.

[SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful) is a Python flask RESTful API application that utilizes the native SAP B1 DI interface to perform any business logic process with SAP B1 ERP and retrieves the data directly from MS SQL Server by “mssql" Python module.

Here are couple integration points. We could embrace [SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful) to provide the data exchange and process automatization.

### Orders Sync
When orders are placed on an eCommerce platform, the integration process could send orders into SAP B1 by **OrderAPI** (POST /v1/order) of [SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful).
![Orders Sync](/images/2016-10-28_16-18-11.png)

1. Orders are placed on an eCommerce platform.
2. Orders are sent into SAP B1 RESTful by JSON requests.
3. Insert orders into SAP B1 by SAP B1 DI.
4. Response with SAP B1 order numbers by JSON responses.

### Shipments Sync
The eCommerce platform could periodically query the shipments (deliveries) processed in SAP B1 by **ShipmentsAPI** (POST /v1/shipments) of [SAP B1 RESTful](https://github.com/ideabosque/SAP-B1-RESTful). Then, it could generate the shipments automatically and notify the customers by emails.
![Shipments Sync](/images/2016-10-28_20-18-32.png)

1. Send query by JSON requests for shipments (deliveries) processed in SAP B1.
2. Retrieve the shipments (deliveries) directly with MS SQL server by Python mssql module.
3. Response the shipments by JSON responses.
4. Generate the shipments on the eCommerce platform and notify the customers by emails.
