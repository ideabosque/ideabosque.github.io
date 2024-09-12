---
layout: page
title: Universal Inventory Feed
date: 2019-10-02 09:51
summary: Universal Inventory Feed.
categories: NetSuite Magento2
---

Within the scenario, there are two types of the Inventory source(vendors and inhouse).  Since products from vendors are imported as **nonInventoryResaleItem** into ERP(NetSuite), the Inventory of those products will be managed outside of the ERP(NetSuite).  Then, the system will merge the sources of the inventory into one universal inventory data feed.

### The source of inventory from vendors.
![The source of inventory from vendors](/images/2019-12-01_14-23-29.png)
Each vendor has to expose its inventory feed by a public link or push the data to a dedicated S3 bucket with the format(CSV, JSON or XML).  Then, a scheduled task can fetch the data and push it to the table "universal_products-inventory"(AWS DynamoDB).

### The inventory of products managed by inhouse.
![The inventory of products managed by inhouse](/images/2019-12-01_14-21-15.png)
The inventory of the items(**inventoryItem**) managed in ERP(NetSuite) will be synchronized by scheduled **BackOffice Task** with the cut time(**lastQuantityAvailableChange**) controlled by sync control layer.  Then, the inventory data will be pushed to the table "universal_products-inventory"(AWS DynamoDB).

### E-Commerce inventory catchup.
![E-Commerce inventory catchup](/images/2019-12-01_14-24-02.png)
A scheduled job in the E-Commerce(Magento 2) will fetch data with the internal timeslot by the last updated date from the universal inventory feed to catchup stock level of the items.