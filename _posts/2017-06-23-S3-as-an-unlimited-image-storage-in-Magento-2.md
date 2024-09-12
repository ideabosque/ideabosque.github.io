---
layout: page
title: AWS S3 as an Unlimited Media Storage in Magento 2
date: 2017-06-23 18:35
summary: Using AWS S3 as an unlimited image storage in Magento 2.
categories: S3 Magento2
---
The powerful module migrates the image functionalities with extraordinary agility. It provides users to resize from Magento into AWS serverless infrastructure. The user could also have endless storage for media and AWS cloudfront CDN support. Under the AWS auto scaling, the module and function will help to archive the auto scaling easily.

### User Case
The image request is sent to AWS CloudFront for the image. If the resized image is cached in AWS CloudFront or stored in AWS S3 bucket, the image url will be returned. If there is no resized image ready, the 404 error will trigger a call to the AWS Api Gateway to invoke an AWS Lambda function to generate a resized image based on the origin url and put back to the S3 bucket. Then, the resized image S3 url will be returned as a 301 url.

### Image CDN/Resize Architecture Diagram
![Image CDN/Resize Architecture Diagram](/images/2016-06-23_16-18-32.png)

**Option 1**: There is the cache stored in AWS CloudFront. The image url will be returned.

**Option 2**: There is no cache in AWS CloudFront but the resized image is stored in the S3 bucket. AWS CloudFront will request the image from the S3 bucket and return to image url.

**Option 3**: There is no resized image in the AWS S3 bucket. Then, when the request is sent to the AWS S3 bucket for the resized image, a 404 error will be triggered a call to the AWS Api Gateway to generate the resized image. The AWS Lambda function will generate the resized image based on the origin url and put back to the AWS S3 bucket. Eventually, the AWS Lambda function will return the resized image url as a 301 url.

### Image CDN/Resize Sequence Diagram
![Image CDN/Resize Sequence Diagram](/images/2016-06-23_16-19-01.png)
