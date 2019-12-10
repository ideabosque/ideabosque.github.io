---
layout: post
title: Google Sheets as PIM for Magento 2
date: 2019-12-08 09:50
summary: Utilize Google Sheets as PIM (Products Information Management) for Magento 2.
categories: Magento2 GoogleSheets
---

Google Sheets is a great tool to collaborate with product data management in a team. The following steps are to demonstrate how to perform the publishing of products from Google Sheets to Magento 2 with a Python script and Python modules.
### Create a sheet in Google Sheets with the following template. 

sku | name | type_id | attribute_name_1 | attribute_name_2 | attribute_value_1 | attribute_value_2
--- | --- | --- | --- | --- | --- | ---
abc-111 | XXXXXXXXXX | simple | description | color | XXXXXXXXXX | White

* sku: Required for identity of each product.
* attribute_name_{x}: An attribute code such as 'description', 'color'.
* attribute_value_{x}: The value associated with attribute_name_{x}.
* Rest of columns will be treated as attributes.

### Share the sheet and get the id and gid.

1. Make the sheet shared for everyone by a link.
2. With the sheet url (https://docs.google.com/spreadsheets/d/{id}/edit#gid={gid}), you will be able to retrieve the **id** and **gid**.

### Install the python modules.

We have to install the following modules to support the products synchronization.
```bash
pip install sshtunnel
pip install AWS-Mage2Connector
```

### Magento 2 connection setting.

The following example is the setting for the connection. 
```python
"SSHSERVER": "XXX.XXX.XXX.XXX",     # Remote Magento 2 server by IP or full domain address.
"SSHSERVERPORT": 22,                # SSH Port.
"SSHUSERNAME": "XXXXXXXXXX",        # SSH Username.
"SSHPKEY": "id_rsa",                # SSH Key (Either use SSHKEY or SSHPASSWORD).
"SSHPASSWORD": "XXXXXXXXXX",        # SSH Password (Either use SSHKEY or SSHPASSWORD).
"REMOTEBINDSERVER": "localhost",    # The MySQL server IP address.
"REMOTEBINDSERVERPORT": 3306,       # The MySQL server port.
"LOCALBINDSERVER": "0.0.0.0",       # Allow binding server.
"LOCALBINDSERVERPORT": 10022,       # Local binding port.
"MAGE2DBSERVER": "127.0.0.1",       # Using local binding IP address for the remote MySQL server.
"MAGE2DBUSERNAME": "root",          # MySQL username.
"MAGE2DBPASSWORD": "12345abc",      # MySQL password.
"MAGE2DB": "magento232",            # MySQL database.
"MAGE2DBPORT": 10022,               # Using local binding port for the remote MySQL server.
"VERSION": "EE"                     # Magento 2 version either EE or CE.
```

### The Python Script for synchronization from the Google Sheets to Magento 2.

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function

import requests, csv, sys, traceback, json
from io import StringIO
from datetime import datetime, date
from decimal import Decimal
from aws_mage2connector import Mage2Connector
from sshtunnel import SSHTunnelForwarder
from time import sleep

import logging
logging.basicConfig(
    level=logging.INFO,
    handlers=[
        logging.FileHandler("products_data_sync.log"),
        logging.StreamHandler(sys.stdout)
    ]
)   
logger = logging.getLogger()


# Helper class to convert an entity to JSON.
class JSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            if o % 1 > 0:
                return float(o)
            else:
                return int(o)
        elif isinstance(o, (datetime, date)):
            return o.strftime("%Y-%m-%d %H:%M:%S")
        elif isinstance(o, (bytes, bytearray)):
            return str(o)
        else:
            return super(JSONEncoder, self).default(o)


# Mage2 From Google Sheet
class ProductsDataSync(object):
    def __init__(self, **params):
        self.mage2Connector = Mage2Connector(
            setting=params.get("mage2_setting"), 
            logger=logger
        )

    def getRows(self, googleSheetId, gid, decode):
        dataFeedUrl = "https://docs.google.com/spreadsheets/d/{id}/export?format=csv&id={id}&gid={gid}".format(
            id=googleSheetId,
            gid=gid
        )

        s = requests.get(dataFeedUrl).content

        rows = []
        for row in csv.DictReader(StringIO(s.decode(decode))):
            row = dict(
                (
                    k.lower().strip().replace(" ", "_").replace("/", "_").replace("(", "").replace(")", ""), 
                    v.strip().split("|") if len(v.split("|")) > 1 else v.strip()
                ) for k, v in row.items() if k is not None and (v!="" and v is not None)
            )
            if "sku" in row.keys() and row["sku"] != "---":
                row = {
                    'sku': row.pop('sku'),
                    'data': row
                }
                rows.append(row)
        return rows

    def syncProduct(self, mage2Setting, attributeSet, products):
        with SSHTunnelForwarder(
            (mage2Setting['SSHSERVER'], mage2Setting['SSHSERVERPORT']),
            ssh_username=mage2Setting['SSHUSERNAME'],
            ssh_pkey=mage2Setting.get('SSHPKEY'),
            ssh_password=mage2Setting.get('SSHPASSWORD'),
            remote_bind_address=(mage2Setting['REMOTEBINDSERVER'], mage2Setting['REMOTEBINDSERVERPORT']),
            local_bind_address=(mage2Setting['LOCALBINDSERVER'], mage2Setting['LOCALBINDSERVERPORT'])
        ) as server:
            sleep(2)
            for product in products:
                sku = product["sku"]
                typeId = product["data"].pop("type_id", "simple")
                storeId = product["data"].pop("store_id", "0")
                product["data"] = dict(
                    (k, v) for k, v in product["data"].items() if v is not None
                )
                try:
                    product['product_id'] = self.mage2Connector.syncProduct(sku, attributeSet, data, typeId, storeId)
                    product['sync_status'] = 'S'
                except Exception:
                    product['sync_status'] = 'F'
                    product['log'] = traceback.format_exc()
                
                logger.info(json.dumps(
                        product, indent=4, cls=JSONEncoder, ensure_ascii=False
                    )
                )
            del self.mage2Connector
            server.stop()
            server.close()

    @classmethod
    def dataSync(cls, **params):
        productsDataSync = cls(**params)
        mage2Setting = params.get('mage2_setting')
        googleSheetId = params.get('google_sheet_id')
        gid = params.get('gid')
        decode = params.get('decode')
        attributeSet = params.get('attribute_set')

        # Retrieve value 'attribute_value_x' by 'attribute_name_x'.
        txFunct = lambda src: src.get(
            list(
                filter(lambda key: key.find('attribute_name') != -1 and src[key]==src['code'], src.keys())
            ).pop().replace('name', 'value')
        ) if any((k.find('attribute_name') != -1 and v == src['code'] for k,v in src.items())) else None

        products = []
        for row in productsDataSync.getRows(googleSheetId, gid, decode):
            product = {
                'sku': row['sku'],
                'data': {}
            }
            for k,v in row['data'].items():
                if k.find('attribute') != -1:
                    product['data'][v] = txFunct({'code': v, **row['data']})
                else:
                    product['data'][k] = v
            products.append(product)

        productsDataSync.syncProduct(mage2Setting, attributeSet, products)


if __name__ == '__main__':
    ## Parameters
    params = {
        'decode': 'utf-8',
        'google_sheet_id': "XXXXXXXXXX",
        'gid': "XXXXXXXXXX",
        'attribute_set': 'Default',
        'mage2_setting': {
            "SSHSERVER": "XXX.XXX.XXX.XXX",
            "SSHSERVERPORT": 22,
            "SSHUSERNAME": "XXXXXXXXXX",
            "SSHPASSWORD": "XXXXXXXXXX",
            "REMOTEBINDSERVER": "localhost",
            "REMOTEBINDSERVERPORT": 3306,
            "LOCALBINDSERVER": "0.0.0.0",
            "LOCALBINDSERVERPORT": 10022,
            "MAGE2DBSERVER": "127.0.0.1",
            "MAGE2DBUSERNAME": "root",
            "MAGE2DBPASSWORD": "12345abc",
            "MAGE2DB": "magento232",
            "MAGE2DBPORT": 10022,
            "VERSION": "EE"
        }
    }
    
    ProductsDataSync.dataSync(**params)

```