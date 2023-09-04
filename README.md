# Infocert

This script is for people who, like me, can't remember the right openssl options even after years and years of performing the same tasks. 

In short it can:

* Get the validity of a certificate
* List the domains included in a certificate
* Validate a certificate or a CSR against a private key to see if they match.
* If an URL is provided it will download the certificate to /tmp/

Only RSA certificates are supported.

## Requirements
* bash
* openssl

## Usage
    -c	Certificate, do not use with -d
    -d	Domain, do not use with -c
    -i	IP
    -h	This help
    -k	Private key
    -p	Port, do not use with -c
    -r	CSR

```
$ bash scripts/infocert.sh -d github.com
========== CERTIFICATE ==========
Not Before: Feb 14 00:00:00 2023 GMT
Not After : Mar 14 23:59:59 2024 GMT
Subject: C = US, ST = California, L = San Francisco, O = "GitHub, Inc.", CN = github.com
DNS:github.com, DNS:www.github.com
Certificate modulus: baf59ff7f5b05fde6799439b6f31a290```
