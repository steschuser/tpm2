#!/bin/bash

AK_HANDLE=0x81010002

# Clear TPM2
tpm2_clear

# Create Endorsment Key
echo "create EK"
tpm2_createek -c ek.ctx -G rsa -u ek.pub
tpm2_flushcontext -t
# Create Attestation Key
## create AK
echo "create AK"
tpm2_createak -C ek.ctx -c ak.ctx -G rsa -g sha256 -s rsassa

## store in NV at 0x81010002
tpm2_evictcontrol -C o -c ak.ctx "$AK_HANDLE"
tpm2_flushcontext -t
## read public part, store in PEM and save creation parameters
tpm2_readpublic -c ak.ctx -f pem -o ak.pem > ak.yaml

## get name as well
cat ak.yaml | grep '^name:' | awk '{ print $2 }' > ak.name

# Create Public Key / SRK
echo "create SRK"
PARENT_CTX=primary_owner_key.ctx

tpm2_createprimary --hierarchy=o --hash-algorithm=sha256 --key-algorithm=rsa --key-context=${PARENT_CTX}
tpm2_flushcontext -t

## Load primary key to persistent handle
HANDLE=$(tpm2_evictcontrol --hierarchy=o --object-context=${PARENT_CTX} | cut -d ' ' -f 2 | head -n 1)

tpm2_flushcontext -t


# Make dir to store it all
mkdir /etc/tpm2

# Delete ctx
rm *.ctx
cp *.pub *.name *.pem *yaml /etc/tpm2

# Generate openssl key
tpm2tss-genkey -a rsa /etc/tpm2/rsa.tss -P "$HANDLE"
openssl rsa -engine tpm2tss -inform engine -in /etc/tpm2/rsa.tss -pubout -outform pem -out /etc/tpm2/rsa.pub


# Show created handles
echo "Active handles"
tpm2_getcap handles-persistent

