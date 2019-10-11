---
layout: post
title: Vendors Product Data Feed Publishing Process
date: 2019-09-30 16:02
summary: Vendors Product Data Feed Publishing Process(Trading Product Data Service, Universal Product Data Feed).
categories: NetSuite Magento2
---

The scenario is related to the product data published or updated workflow from vendors to ERP(NetSuite), and from ERP(NetSuite) to E-Commerce(Magento 2).
* 1st Stage: Data Collection from Vendors' Data Feed.  
* 2nd Stage: Data Transformation to ERP(NetSuite) and Manipulated by CSR. 
* 3rd Stage: Data Transformation and Publishing to Universal Product Data Feed.
* Final Stage: E-Commerce(Magento 2) Pickup Data from Universal Product Data Feed.  
![Stages](/images/2019-10-02_13-51-03.png)

### 1st Stage: Data Collection from Vendors' Data Feed.
First, vendors either expose the data feed with public links or place the data with certain format such as CSV, JSON or XML to the dedicated AWS S3 buckets.  Next, a scheduled task will scan and pull the data into the staging table, "stg_products"(AWS DynamoDB). 
![1st Stage](/images/2019-10-02_13-51-24.png)

### 2nd Stage: Data Transformation to ERP(NetSuite) and Manipulated by CSR.
Periodically, the middle tier(DataWald) retrieves the data from the staging table, "stg_products"(AWS DynamoDB) by the cut time managed by the sync control layer.  Then, the product data will be validated and transformated by the metadata management layer.  If a row of the data is violated with any rule or proceced with any exception, it will be marked as "F"(Fail) and can be resync from the middle tier(DataWald) after the correction; otherwise, the data will be pushed to the destionation, ERP(NetSuite) and marked as "S"(success). 

![2nd Stage](/images/2019-10-02_13-52-03.png)

**Step 1** Schedule **Frontend Task** powered by AWS CloudWatch.

**Step 2** Data collection from the table **stg_products**.
1. Invoke **Core Task**.
2. Invoke **MicroCore DynamoDB Task**.
3. Collect data from the table **stg_products**.
4. Push data to **DataWald API**.  

**Step 3** Dispatch **BackOffice Task** with AWS SQS.
1. Place data to a AWS SQS queue.
2. Dispatch **BackOffice Task**.

**Step 4** Data synchronization to ERP(NetSuite) by **BackOffice Task**.
1. Retrieve data from the AWS SQS queue.
2. Invoke **Core Task**.
3. Invoke **MicroCore NS Task**.
4. Synchronize data to ERP(NetSuite).
5. Update the status for each entity of the data.
6. Update the status for a task in the sync control layer.

After the data is placed in ERP(NetSuite), a CSR can work on the data with the addtional information for the next stage.  Within this stage, certain fields of data will be published only once when the entity is inserted; otherwise, the rest of fields can be updated by the source of the data feeds from the vendors.

### 3rd Stage: 3rd Stage: Data Transformation and Publishing to Universal Product Data Feed.
The middle tier(DataWald) will pickup the updated records by the cut time in the sync control layer.  Then, the data will be processed with the validation and transformation rules in the metadata management layer.  If any record with an exception or failed in the process will be marked as "F" and can be resynchronized from the middle tier(DataWald) with the proper correction; otherwise, it will be synchronized to the target table, "universal_products"(AWS DynamoDB) for the universal product data feed.

![3rd Stage](/images/2019-10-02_13-52-29.png)

**Step 1** Schedule **BackOffice Task** powered by AWS CloudWatch.

**Step 2** Data collection from ERP(NetSuite).
1. Invoke **Core Task**.
2. Invoke **MicroCore NS Task**.
3. Collect data from ERP(NetSuite).
4. Push data to **DataWald API**.  

**Step 3** Dispatch **Frontend Task** with AWS SQS.
1. Place data to a AWS SQS queue.
2. Dispatch **Frontend Task**.

**Step 4** Data synchronization to the table **universal_products** by **Frontend Task**.
1. Retrieve data from the AWS SQS queue.
2. Invoke **Core Task**.
3. Invoke **MicroCore DynamoDB Task**.
4. Synchronize data to the table **universal_products**.
5. Update the status for each entity of the data.
6. Update the status for a task in the sync control layer.

### Final Stage: E-Commerce(Magento 2) Pickup Data from Universal Product Data Feed.
Eventially, a scheduled job in the E-Commerce(Magento 2) will fetch the data from the universal product data feed(RESTful API) with the interval timeslot and put the products online.

![Final Stage](/images/2019-10-02_13-52-47.png)
