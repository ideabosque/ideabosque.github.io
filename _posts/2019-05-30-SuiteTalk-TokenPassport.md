---
layout: post
title: SuiteTalk TokenPassport
date: 2019-05-30 19:22
summary: How to implement SuiteTalk(NetSuite) TokenPassport.
categories: NetSuite SuiteTalk
---

With SuiteTalk, we have to retrieve/generate the TokenPassport first to initiate the commnuication.  Here are two python modules which will be applied.  
* [Python Zeep](https://python-zeep.readthedocs.io/en/master/) is very efficient and useful package to be embraced into the system for SOAP/WSDL comunication.
* [Python Tenacity](https://github.com/jd/tenacity) is a module to apply the retry mechanism, since each api endpoint has the traffic throttle of the traffic.

### Sequence Diagram
![Sequence Diagram](/images/2019-06-03_17-33-17.png)

```python
def _generateTimestamp(self):
    return str(int(time()))

def _generateNonce(self, length=20):
    """Generate pseudorandom number
    """
    return ''.join([str(random.randint(0, 9)) for i in range(length)])

def _getSignatureMessage(self, nonce, timestamp):
    return '&'.join(
        (
            self.ACCOUNT,
            self.CONSUMER_KEY,
            self.TOKEN_ID,
            nonce,
            timestamp,
        )
    )

def _getSignatureKey(self):
    return '&'.join((self.CONSUMER_SECRET, self.TOKEN_SECRET))

def _getSignatureValue(self, nonce, timestamp):
    key = self._getSignatureKey()
    message = self._getSignatureMessage(nonce, timestamp)
    hashed = hmac.new(
        key=key.encode('utf-8'),
        msg=message.encode('utf-8'),
        digestmod=hashlib.sha256
    ).digest()
    return base64.b64encode(hashed).decode()

@property
def tokenPassport(self):
    TokenPassport = self.getDataType("ns0:TokenPassport")
    TokenPassportSignature = self.getDataType("ns0:TokenPassportSignature")

    nonce = self._generateNonce()
    timestamp = self._generateTimestamp()
    tokenPassportSignature = TokenPassportSignature(
        self._getSignatureValue(nonce, timestamp),
        algorithm='HMAC-SHA256'
    )

    return TokenPassport(
        account=self.ACCOUNT,
        consumerKey=self.CONSUMER_KEY,
        token=self.TOKEN_ID,
        nonce=nonce,
        timestamp=timestamp,
        signature=tokenPassportSignature
    )
```