---
layout: post
title: DropShip Integration Architecture
date: 2019-07-02 16:17
summary: DropShip integration built with NetSuite and Magento 2.
categories: NetSuite SuiteTalk, Magento 2
---

The dropship integration system addresses the requirements and workflows between the seller and the dropship vendor.
* Order Sync: Push the orders from the seller's e-commerce website(Magento 2) to the dropship vendor's ERP system(NetSuite).
* Product Data Sync: Sync product data from the dropship vendor's ERP system(NetSuite) to the seller's e-commerce website(Magento 2).
* Product Inventory Sync: Catch up inventory level from the dropship vendor's ERP system(NetSuite) to the seller's e-commerce website(Magento 2).
* Product Image Sync: Sync images into the seller's e-commerce website(Magento 2) from the data feed.

### User Case: Order Sync
![User Case: Order Sync](/images/2019-07-05_16-18-32.png)
Customers place orders on the seller's e-commerce(Magento 2) website, orders with the dropship vendor's items only will be pushed periodically to the middle tier with queues.  Then, the orders will be sent to the dropship vendor's ERP(NetSuite) system to be processed.

### User Case: Product Data Sync
Product data will be pulled out periodically from the dropship vendor's ERP(NetSuite) system and stored in the middle tier with the basic validation.  Then, the product data will be pushed into the seller's e-commerce(Magento 2) website for new products or exist products.

### User Case: Product Inventory Sync
Product inventory data will be pulled from the dropship vendor's ERP(NetSuite) systen to the seller's e-commerce(Magento 2) website for catching up the inventory stock level.

### User Case: Product Image Sync
Product image data is aggregated into the middle tier from the source image data feed periodically and pushed into the seller's e-commerce(Magento 2) website to insert images for products.

### Roles
* Customer: Who places orders on the seller's e-commerce website(Magento 2).
* Seller: Who manages the e-commerce website(Magento 2).
* Dropship Vendor: who provides the dropship service for the seller.

### System
* Seller e-commerce(Frontend): Magento 2
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

### Orders Sync Workflow
![Orders Sync Workflow](/images/2019-07-02_19-01-17.png)

#### Step 1,2: Send orders periodically from Magento 2.
1. Gain a queue.
2. Place orders into the queue.
3. Invoke the **Core Task** to process the queue.

#### Step 3: Process orders in the queue.
1. Invoke the **Core Task** -> **Micro Core SQS Task**.
2. Call **DataWald API(Control)** to get the last cut date.
3. Retrieve orders from the queue.
4. Call **DataWald API(Backoffice)** to store orders into the staging table.
5. Call **DataWald API(Control)** to insert a **syncTask** entry to track the progress.

#### Step 4: Dispatch the syncTask to the **Backoffice Task**.
1. Create a queue.
2. Places orders with limited information from the staging table into the queue.
3. Dispatch the **syncTask** with the queue to the **Backoffice Task**. 

#### Step 5: The **Backoffice Task** will retrieve orders from the queue.
1. Retrieve orders from the queue.
2. Dispatch a call **updateSyncTask** to track the progress and destroy the queue if the queue is empty. 

#### Step 6: Process the orders with SuiteTalk API call.
1. Invoke the **Core Task** -> **Micro Core NS Task**.
2. Call SuiteTalk API to insert orders.

#### Step 7: Update the status of the **syncTask** by the call **updateSyncTask**.
1. Invoke the **Core Task** -> **Micro Core NS Task**.
2. Call **DataWald API(Control)** to update the status of the **syncTask**.

### Product Data/Inventory Sync Workflow
![Product Data/Inventory Sync Workflow](/images/2019-07-02_21-33-31.png)

#### Step 1: A scheduled CloudWatch rule with trigger the **Backoffice Task** periodically with the required variables.

#### Step 2: Retireve product data/inventory from NetSuite by SuiteTalk API calls.
1. Invoke the **Core Task** -> **Micro Core NS Task**.
2. Call **DataWald API(Control)** to get the last cut date.
3. Retrieve product data/inventory by SuiteTalk API calls.
4. Call **DataWald API(Frontend)** to store product data/inventory into the staging table.
5. Call **DataWald API(Control)** to insert a **syncTask** entry to track the progress.

#### Step 3: Dispatch the syncTask to the **Frontend Task**.
1. Create a queue.
2. Places product data/inventory with limited information from the staging table into the queue.
3. Dispatch the **syncTask** with the queue to the **Frontend Task**. 

#### Step 4: The **Frontend Task** will retrieve product data/inventory from the queue.
1. Retrieve product data/inventory from the queue.
2. Dispatch a call **updateSyncTask** to track the progress and destroy the queue if the queue is empty. 

#### Step 5: Push product data/inventory into DynamoDB tables.
1. Invoke the **Core Task** -> **Micro Core DynamoDB Task**.
2. Insert product data/inventory into DynamoDB tables for external API access.

#### Step 6: Update the status of the **syncTask** by the call **updateSyncTask**.
1. Invoke the **Core Task** -> **Micro Core DynamoDB Task**.
2. Call **DataWald API(Control)** to update the status of the **syncTask**.

#### A scheduled job in Magento 2 pulls the product data/inventory periodically by the exteral API with the DynamoDB tables.

### Product Images Sync Workflow
![Product Images Sync Workflow](/images/2019-07-03_19-20-53.png)

#### Step 1: Trigger by CloudWatch.
A scheduled CloudWatch rule will trigger the **syncProductsData Task**.

#### Step 2: Retireve data from image data feed.
The **syncProductsData Task** will retrieve image data from the image data feed and store into a DynamoDB table.

#### Step 3: Download images by image data.
A scheduled job in Magento 2 will pull the image data by the external API call with the DynamoDB table and download the images by the image data.

