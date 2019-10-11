---
layout: post
title: DropShip Integration between Seller and Vendor
date: 2019-07-02 16:17
summary: DropShip integration built to bridge NetSuite(vendor) and Magento 2(seller).
categories: NetSuite SuiteTalk Magento2
---

The dropship integration system addresses the requirements and workflows between the seller and the dropship vendor.
* Order synchronization: Push the orders from the seller's E-Commerce website(Magento 2) to the dropship vendor's ERP system(NetSuite).
* Product data/Inventory synchronization: Synchronize product data and inventory from the dropship vendor's ERP system(NetSuite) to the seller's E-Commerce website(Magento 2).
* Image synchronization: Synchronize images into the seller's E-Commerce website(Magento 2) from the data feed.

![Overview](/images/2019-10-10_22-55-15.png)

### Roles
* Customer: Who places orders on the seller's E-Commerce website(Magento 2).
* Seller: Who manages the E-Commerce website(Magento 2).
* Dropship Vendor: who provides the dropship service for the seller.

### System
* Seller E-Commerce(Frontend): Magento 2
* Dropship Vendor(Backdffice): NetSuite
* Middle Tier: DataWald Integration platform
    - Middle Tier API (DataWald API)
        1. Core: Manage the configuration of each connection path and matedata of product data.
        2. Control: Control the cut date for the tasks, dispatch tasks and manage the processing status of the tasks.
        3. Frontend: Stage the data for the frontend data of each connection.
        4. Backend: Stage the data for the backend data of each connection.
    - Queue Tasks
        1. Core Task: The core dispatch engine to manage micro core tasks.
        2. Micro Core B1 Task: A micro service to communicate with B1 with RESTfull API calls.
        3. Micro Core BC/BundleB2B Task: A micro service to interact with BC with RESTfull API calls.

### User Case: Order synchronization(from the seller to the dropship vendor) 
![User Case: Order Sync](/images/2019-07-05_16-18-32.png)
New placed orders will be scaned by a scheduled job in E-Commerce(Magento 2).  If an order contains line items associated with the dropship vendor, the rest of line items not related to the dropship vendor will be removed and the order will be sent out to the dropship vendor through the integration layer.

![Orders Sync Workflow Step 1](/images/2019-10-10_23-01-00.png)

![Orders Sync Workflow Step 2](/images/2019-10-10_23-01-28.png)

### User Case: Product data/inventory synchronization
Scheduled **BackOffice Task** will retrieve product data and inventory by the cut time managed by sync control layer and push to the tables "universal_products" and "universal_products-inventory"(AWS DynamoDB) through the middle tier(DataWald).  Then, a scheduled job in E-Commerce(Magento 2) will fetch the data from the universal product data/inventory feed(RESTful API) with the interval timeslot.

![Product Data/Inventory Sync Workflow Step 1](/images/2019-10-10_23-19-39.png)

![Product Data/Inventory Sync Workflow Step 2](/images/2019-10-10_23-20-41.png)

### User Case: Image synchronization
There are two types of image sources.

* External image feeds: Scheduled **SyncProductsData Task** will fetch the external image feeds periodically and push to the table **universal_products-imagegallery**.

![External image feeds](/images/2019-10-10_23-24-07.png)

* Internal E-Commerce(Magento 2): Scheduled **SyncProductsData Task** will retrieve the image data by the cut time managed by the sync control layer and push to the table **universal_products-imagegallery**.

![Product Images Sync Workflow](/images/2019-10-10_23-24-25.png)

Eventially, a scheduled job at the seller's E-Commerce(Magento 2) will fetch the image data from the universal image gallery feed(RESTful) with a interval timeslot.

![Product Images Sync Workflow Final](/images/2019-10-10_23-24-37.png)

