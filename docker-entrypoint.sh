#!/bin/sh
#set -eo pipefail


# Start all the things
echo "TPM2 Simulator" > /etc/motd
echo "starting simulator"

cd /opt/tpm2simulator/run
/opt/tpm2simulator/src/tpm_server >>/opt/tpm2simulator/log/tpm2.log 2>&1 &

echo "starting tpm2-abrmd "
tpm2-abrmd --allow-root --tcti=mssim > /opt/tpm2simulator/log/abrmd.log 2>&1

export TPM2TOOLS_TCTI="mssim:host=localhost,port=2321"

cd ~
/bin/bash
