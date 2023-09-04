# Infocert
Dirty script to get the domains included in a tls certificate.

It can also validate a certificate (from a local file or a remote server) or a CSR against a private key to see if they match.

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
