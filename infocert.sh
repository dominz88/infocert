#!/usr/bin/env bash

# Dirty script to get the validity and SANs of a local or remote
# certificate or to find out if a certificate matches a private key

function usage
{
cat <<-EOF
    Usage:
    -c	Certificate, do not use with -d
    -d	Domain, do not use with -c
    -i	IP
    -h	This help
    -k	Private key
    -p	Port, do not use with -c
    -r	CSR
EOF

    exit 1

}

function download_certificate
{

    echo | openssl s_client -servername $DOMAIN -connect $IP:$PORT 2>/dev/null \
         sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}

function get_certificate_info 
{
    openssl x509 -text -noout -in $CERTIFICATE \
        | grep -e "Subject:" -e "Not Before" -e "Not After" -e "DNS:"| awk '{$1=$1};1'
}

function get_csr_info 
{
    openssl req -in $CSR -noout -text | grep -e "Subject:" -e "DNS:"| awk '{$1=$1};1'
}

function get_certificate_modulus 
{
    openssl x509 -noout -modulus -in "$CERTIFICATE" | openssl md5 | awk '{print $2}'
}

function get_key_modulus 
{
    openssl rsa -noout -modulus -in $PRIVATE_KEY | openssl md5 | awk '{print $2}'
}

function get_csr_modulus
{
    openssl req -noout -modulus -in $CSR | openssl md5 | awk '{print $2}'
}

function main 
{
#Parse options

local OPTIND
while getopts ':c:d:i:k:p:r:h' OPTION; do
    if [[ "$OPTARG" =~ ^- ]]; then
        usage
        fi

        case "$OPTION" in
	c)
        CERTIFICATE="$OPTARG"
        ;;
	d)
        DOMAIN="$OPTARG"
        ;;
	i)	
        IP="$OPTARG"
        ;;
	k)
        PRIVATE_KEY="$OPTARG"
        ;;
	p)
        PORT="$OPTARG"
        ;;
	r)
        CSR="$OPTARG"
        ;;
	*)
        usage
        ;;
	esac
done

# Set colors 
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
END=$'\e[0m'

# Default port is 443
if [ -z "$PORT" ]
then
	PORT=443
fi

# When a domain name is provided, then download the certificate
if [ ! -z "$DOMAIN" ] || [ ! -z "$IP" ]
then

CERTIFICATE="/tmp/certificate"

# When empty, IP equals DOMAIN and viceversa
if [ -z "$IP" ]
then
    IP=$DOMAIN
elif [ -z "$DOMAIN" ]
then
    DOMAIN=$IP
fi
    download_certificate > $CERTIFICATE
fi

# Get infor for each file

if [ -f "$CERTIFICATE" ]
then
    echo "========== CERTIFICATE =========="
    get_certificate_info
    CERTIFICATE_MODULUS=$(get_certificate_modulus)
    [ ! -z $CERTIFICATE_MODULUS ] && echo "Cerficate modulus:" $CERTIFICATE_MODULUS
    echo " "
fi

if [ -f "$CSR" ]
then
    echo "========== CSR =========="
    get_csr_info
    CSR_MODULUS=$(get_csr_modulus)
    [ ! -z $CSR_MODULUS ] && echo "CSR modulus:" $CSR_MODULUS
    echo ""
fi

if [ -f "$PRIVATE_KEY" ]
then
    echo "========== PRIVATE KEY =========="
    KEY_MODULUS=$(get_key_modulus)
    [ ! -z $KEY_MODULUS ] && echo "Key modulus:" $KEY_MODULUS
    echo ""
fi

# Compare modulus 
if [ ! -z $CERTIFICATE_MODULUS ] && [ ! -z $KEY_MODULUS ]
then
    if [ "$CERTIFICATE_MODULUS" == "$KEY_MODULUS" ]
	then
        printf "%s\n" "${GREEN}CERT == KEY${END}"
    else
        printf "%s\n" "${RED}CERT != KEY${END}"
    fi
fi

if  [ ! -z $CERTIFICATE_MODULUS ] && [ ! -z $CSR_MODULUS ]
then
    if [ "$CERTIFICATE_MODULUS" == "$CSR_MODULUS" ]
    then
        printf "%s\n" "${GREEN}CERT == CSR${END}"
    else
        printf "%s\n" "${RED}CERT != CSR${END}"
    fi
fi

if [ ! -z $CSR_MODULUS ] && [ ! -z $KEY_MODULUS ]
then
    if [ "$KEY_MODULUS" == "$CSR_MODULUS" ]
    then
        printf "%s\n" "${GREEN}CSR == KEY${END}"
    else
        printf "%s\n" "${RED}CSR != KEY${END}"
    fi
fi
}


main $@
