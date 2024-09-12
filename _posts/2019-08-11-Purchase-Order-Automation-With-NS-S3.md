---
layout: page
title: Purchase Order Automation With Vendors
date: 2019-08-11 20:01
summary: Purchase order automation built with NetSuite and S3 Bucket.
categories: NetSuite SuiteTalk
---

Automating the workflow of the purchase order will create greater success in the business’s operation among the purchase vendors. If we can build the process to automate the workflow to reduce human error, the accuracy of the operation will be increased and the cost of low-quality data or human mistakes will be reduced. The automatic workflow will include the following two parts: sending POs to the vendors and receiving invoices (item fulfillments) from the vendors.
### Sending POs to the vendors:
First, the workflow will be initiated which are issued by PO transactions in NetSuite. Periodically, the middle tier(DataWald) will be triggered by a rule in AWS Cloud Watch to pull down PO transactions and place the records into the staging table in AWS DynamoDB.  Second, the middle Tier (DataWald) will push the records into a queue and dispatch a task with rules and logic to process the data into the destination(S3 bucket) with the configured format such as XML, JSON.  Then each vendor could pick up the files from the dedicated bucket.
![Sending POs to Vendors Workflow](/images/2019-08-18_23-18-11.png)

**Step 1** Schedule **BackOffice Task** powered by AWS CloudWatch.

**Step 2** Data collection from ERP(NetSuite).
1. Invoke **Core Task**.
2. Invoke **MicroCore NS Task**.
3. Collect data from ERP(NetSuite).
4. Push data to **DataWald API**.  

**Step 3** Dispatch **Frontend Task** with AWS SQS.
1. Place data to a AWS SQS queue.
2. Dispatch **Frontend Task**.

**Step 4** Data synchronization to AWS S3 buckets by **Frontend Task**.
1. Retrieve data from the AWS SQS queue.
2. Invoke **Core Task**.
3. Invoke **MicroCore S3 Task**.
4. Export data to AWS S3 buckets with a configured format.
5. Update the status for each entity of the data.
6. Update the status for a task in the sync control layer.

### Receiving invoices (item fulfillments) from vendors:
When each vendor processes a PO, a corresponding invoice (item fulfillment) file will be placed in the bucket.  A periodic task will scan each bucket(assigned to each vendor) and merge all invoices(item fulfillments) files into one if all related invoices(item fulfillments) of a sales order are sent back and then place the files in a dedicated bucket.  Next, another scheduled task will process the merged files from the bucket to a staging table in AWS DynamoDB.  In the meantime, the logic will check the records (a.k.a item fulfillments in the system) and update accordingly. That is, any new record or change on previous ones will be placed into a queue and the system will dispatch a task to process it properly.  Then, the records in the queue will be processed into NetSuite.  The last step is a task will be fired to inspect if each record is processed successfully or not and update the details of the status.  If any record is failed for any reason, the system will  resend the record after correcting the data in the staging table.

![Receiving Invoices Workflow 0](/images/2019-08-19_23-02-52-0.png)

**Step 1**: Each vendor places back the invoice files to a dedicated bucket. 
**Step 2**: Schedule **MergeItemFulfillments Task** powered by AWS CloudWatch.
**Step 3**: Scan and pickup files from all buckets.
**Step 4**: Merge files into one and place to the destination bucket.

![Receiving Invoices Workflow](/images/2019-08-19_23-02-52.png)

**Step 1** Schedule **Frontend Task** powered by AWS CloudWatch.

**Step 2** Data collection from the AWS S3 bucket.
1. Invoke **Core Task**.
2. Invoke **MicroCore S3 Task**.
3. Collect data from the AWS S3 bucket.
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

To automate the workflow of the purchase order is a matter of the efficiency of the business's operation among the purchase vendors.
