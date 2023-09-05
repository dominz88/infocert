#!/usr/bin/env bash

function usage {
  cat <<-EOF
  Usage:
  -c  Certificate file
  -d  Domain, do not use with -i
  -i  IP address, do not use with -d
  -h  This help
  -k  Private key file
  -p  Port
  -r  CSR file
EOF
  exit 1
}

function download_certificate {
  echo | openssl s_client -servername "${1}" -connect "${1}:${2}" 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
}

function get_certificate_info {
  openssl x509 -text -noout -in "${1}" | grep -e "Subject:" -e "Not Before" -e "Not After" -e "DNS:" | awk '{$1=$1};1'
}

function get_csr_info {
  openssl req -in "${1}" -noout -text | grep -e "Subject:" -e "DNS:" | awk '{$1=$1};1'
}

function get_certificate_modulus {
  openssl x509 -noout -modulus -in "${1}" | openssl md5 | awk '{print $2}'
}

function get_key_modulus {
  openssl rsa -noout -modulus -in "${1}" | openssl md5 | awk '{print $2}'
}

function get_csr_modulus {
  openssl req -noout -modulus -in "${1}" | openssl md5 | awk '{print $2}'
}

function main {
  # Parse options
  local OPTIND
  while getopts ':c:d:i:k:p:r:h' OPTION; do
    if [[ "$OPTARG" =~ ^- ]]; then
      usage
    fi

    case "$OPTION" in
    c)
      CERTIFICATE="${OPTARG}"
      ;;
    d)
      DOMAIN="${OPTARG}"
      ;;
    i)
      IP="${OPTARG}"
      ;;
    k)
      PRIVATE_KEY="${OPTARG}"
      ;;
    p)
      PORT="${OPTARG}"
      ;;
    r)
      CSR="${OPTARG}"
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
    esac
  done

  # Set colors
  RED=$'\e[1;31m'
  GREEN=$'\e[1;32m'
  END_COLOR=$'\e[0m'

  # Default port is 443
  if [ -z "${PORT}" ]; then
    PORT=443
  fi

  # When a domain name is provided, then download the certificate
  if [ ! -z "${DOMAIN}" ] || [ ! -z "${IP}" ]; then

    # When empty, IP equals DOMAIN and vice versa
    if [ -z "${IP}" ]; then
      IP="${DOMAIN}"
    elif [ -z "${DOMAIN}" ]; then
      DOMAIN="${IP}"
    fi
    
    REMOTE_CERTIFICATE="/tmp/${DOMAIN}.crt"
    download_certificate "${DOMAIN}" "${PORT}" > "${REMOTE_CERTIFICATE}"
    
    if [ -f "${REMOTE_CERTIFICATE}" ]; then
      echo "========== REMOTE CERTIFICATE =========="
      get_certificate_info "${REMOTE_CERTIFICATE}"
      REMOTE_CERTIFICATE_MODULUS=$(get_certificate_modulus "${REMOTE_CERTIFICATE}")
      [ ! -z "${REMOTE_CERTIFICATE_MODULUS}" ] && echo "Remote certificate modulus:" "${REMOTE_CERTIFICATE_MODULUS}"
      echo " "
    fi
  fi

  # Get info for each file

  if [ -f "${CERTIFICATE}" ]; then
    echo "========== CERTIFICATE =========="
    get_certificate_info "${CERTIFICATE}"
    CERTIFICATE_MODULUS=$(get_certificate_modulus "${CERTIFICATE}")
    [ ! -z "${CERTIFICATE_MODULUS}" ] && echo "Certificate modulus:" "${CERTIFICATE_MODULUS}"
    echo " "
  fi

  if [ -f "${CSR}" ]; then
    echo "========== CSR =========="
    get_csr_info "${CSR}"
    CSR_MODULUS=$(get_csr_modulus "${CSR}")
    [ ! -z "${CSR_MODULUS}" ] && echo "CSR modulus:" "${CSR_MODULUS}"
    echo ""
  fi

  if [ -f "${PRIVATE_KEY}" ]; then
    echo "========== PRIVATE KEY =========="
    KEY_MODULUS=$(get_key_modulus "${PRIVATE_KEY}")
    [ ! -z "${KEY_MODULUS}" ] && echo "Key modulus:" "${KEY_MODULUS}"
    echo ""
  fi

  echo ========== COMPARE ==========
  # REMOTE CERT VS CERT
  if [ ! -z "${REMOTE_CERTIFICATE_MODULUS}" ] && [ ! -z "${CERTIFICATE_MODULUS}" ]; then
    if [ "${REMOTE_CERTIFICATE_MODULUS}" == "${CERTIFICATE_MODULUS}" ]; then
      printf "%s\n" "${GREEN}REMOTE CERT == CERT${END_COLOR}"
    else
      printf "%s\n" "${RED}REMOTE CERT != CERT${END_COLOR}"
    fi
  fi
  
  # REMOTE CERT VS KEY
  if [ ! -z "${REMOTE_CERTIFICATE_MODULUS}" ] && [ ! -z "${KEY_MODULUS}" ]; then
    if [ "${REMOTE_CERTIFICATE_MODULUS}" == "${KEY_MODULUS}" ]; then
      printf "%s\n" "${GREEN}REMOTE CERT == KEY${END_COLOR}"
    else
      printf "%s\n" "${RED}REMOTE CERT != KEY${END_COLOR}"
    fi
  fi

  # REMOTE CERT VS CSR
  if [ ! -z "${REMOTE_CERTIFICATE_MODULUS}" ] && [ ! -z "${CSR_MODULUS}" ]; then
    if [ "${REMOTE_CERTIFICATE_MODULUS}" == "${CSR_MODULUS}" ]; then
      printf "%s\n" "${GREEN}REMOTE CERT == CSR${END_COLOR}"
    else
      printf "%s\n" "${RED}REMOTE CERT != CSR${END_COLOR}"
    fi
  fi
  
  # CERT VS KEY
  if [ ! -z "${CERTIFICATE_MODULUS}" ] && [ ! -z "${KEY_MODULUS}" ]; then
    if [ "${CERTIFICATE_MODULUS}" == "${KEY_MODULUS}" ]; then
      printf "%s\n" "${GREEN}CERT == KEY${END_COLOR}"
    else
      printf "%s\n" "${RED}CERT != KEY${END_COLOR}"
    fi
  fi

  # CERT VS CSR
  if [ ! -z "${CERTIFICATE_MODULUS}" ] && [ ! -z "${CSR_MODULUS}" ]; then
    if [ "${CERTIFICATE_MODULUS}" == "${CSR_MODULUS}" ]; then
      printf "%s\n" "${GREEN}CERT == CSR${END}"
    else
      printf "%s\n" "${RED}CERT != CSR${END}"
    fi
  fi

  # CSR VS KEY
  if [ ! -z "${CSR_MODULUS}" ] && [ ! -z "${KEY_MODULUS}" ]; then
    if [ "${KEY_MODULUS}" == "${CSR_MODULUS}" ]; then
      printf "%s\n" "${GREEN}CSR == KEY${END}"
    else
      printf "%s\n" "${RED}CSR != KEY${END}"
    fi
  fi
}

main $@
