---
layout: post
title: Maximize AWS Lambda Executing Time
date: 2019-11-26 13:43
summary: Maximize AWS Lambda Executing Time.
categories: Serverless AWS-Lambda
---

Since the maximum time for an AWS Lambda function to be executed is 900 seconds (15 minutes), it will be better to trace the remaining time closely if there is a big dataset that is processed.  How much data that has been processed as the offset value and the remaining time in a session of an AWS Lambda function call could be used to determine if it is required to invoke the next session of the AWS Lambda function to process the dataset from the offset value.  The following code example is to demonstrate how to process a big dataset by an AWS Lambda function with multiple calls in sequence.

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import print_function

import boto3, os, json, time

import logging
logger = logging.getLogger()
logger.setLevel(eval(os.environ["LOGGINGLEVEL"]))
lastRequestId = None

def getRows():
	# Retrieve rows.
	...
	
	return rows
	
def getDataSet(**event):
	offset = int(event.get("offset"), "0")
	total = 0
	rows = []
	for row in getRows():
		total += 1
		if offset == 0:
            # Initiate the row.
            ...
            
			rows.append(row)
		if offset > 0:
			offset -= 1
	return rows, total

def syncData(**event):
	offset = int(event.get("offset"), "0")
	rows, total = getDataSet(**event)
	for row in rows:
		start_ms = int(round(time.time()*1000))
		# Process the row.
		...
		
		offset += 1
		spend_ms = int(round(time.time()*1000)) - start_ms
		yield offset, total, spend_ms

def handler(event, context):
    # TODO implement
    global lastRequestId
    if lastRequestId == context.aws_request_id:
        return # abort
    else:
        lastRequestId = context.aws_request_id # keep request id for next invokation

	max_spend_ms = 0
	logger.info("Allow MS/Loop: {allowms}/{loop}".format(
		allowms=context.get_remaining_time_in_millis(), 
		loop=int(event.get("loop", "0")))
	)
	next_loop = lambda offset, total, max_spend_ms: \
		context.get_remaining_time_in_millis() - max_spend_ms*5 <= 0 and total - offset > 0
	for offset, total, spendms in dataSync(**params):
		max_spend_ms = spendms if spendms > max_spend_ms else max_spend_ms
		if next_loop(offset, total, max_spend_ms):
			loop = int(event.get("loop", "0")) + 1
			assert  loop <= 100, "Over the limit of loops."
			payload = dict(event, **{"offset": str(offset), "loop": str(loop)})
			logger.info("payload: {payload}".format(
					payload=json.dumps(payload, indent=4)
				)
			)
			boto3.client('lambda').invoke(
				FunctionName=context.invoked_function_arn,
				InvocationType="event",
				Payload=json.dumps(payload)
			)
			break
```