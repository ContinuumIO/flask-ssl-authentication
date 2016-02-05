#!/usr/bin/env bash

#adapted from https://serversforhackers.com/self-signed-ssl-certificates

KEYDIR=flask-local
mkdir -p "$KEYDIR"

# Set the wildcarded domain
# we want to use
DOMAIN="flask.local"

# A blank passphrase
PASSPHRASE=""

# Information needed for root key
SUBJ="
C=US
ST=Virginia
O=
commonName=Root Flask Local Certificate Authority
organizationalUnitName=
emailAddress=
"

# Generate the root key
openssl genrsa -out "$KEYDIR"/root.key 2048

# And a self-signed certificate
openssl req -x509 -new -nodes -key "$KEYDIR"/root.key -sha256 -days 1024 -out \
	"$KEYDIR"/root.pem -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE

# Generate server and client keys
openssl genrsa -out "$KEYDIR"/server.key 2048
openssl genrsa -out "$KEYDIR"/grace.key 2048
openssl genrsa -out "$KEYDIR"/cecilia.key 2048

# Information needed for server certificate
SERVER_SUBJ="
C=US
ST=Virginia
O=
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

# Information needed for Grace Hopper's certificate
GRACE_SUBJ="
C=US
ST=Virginia
O=
commonName=Grace Hopper
organizationalUnitName=
emailAddress=
"

# Information needed for Cecilia Payne's certificate
CECILIA_SUBJ="
C=US
ST=Virginia
O=
commonName=Cecilia Payne
organizationalUnitName=
emailAddress=
"

# Create certificate signing requests
openssl req -new -nodes -key "$KEYDIR"/server.key -sha256 -days 1024 -out \
	"$KEYDIR"/server.csr -subj "$(echo -n "$SERVER_SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE
openssl req -new -nodes -key "$KEYDIR"/grace.key -sha256 -days 1024 -out \
	"$KEYDIR"/grace.csr -subj "$(echo -n "$GRACE_SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE
openssl req -new -nodes -key "$KEYDIR"/cecilia.key -sha256 -days 1024 -out \
	"$KEYDIR"/cecilia.csr -subj "$(echo -n "$CECILIA_SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE
# Then sign them
for name in server grace cecilia; do 
    openssl x509 -req -in "$KEYDIR/$name".csr -CA "$KEYDIR"/root.pem -CAkey "$KEYDIR"/root.key \
	    -CAcreateserial -out "$KEYDIR/$name".crt -days 500 -sha256
done

# Validate
for name in server grace cecilia; do
    openssl verify -CAfile "$KEYDIR"/root.pem "$KEYDIR/$name".crt
done

echo "copying root.pem, server.crt and server.key to dockerfiles/apache"
cp $KEYDIR/root.pem dockerfiles/apache/
cp $KEYDIR/server.crt dockerfiles/apache/
cp $KEYDIR/server.key dockerfiles/apache/

echo "exporting client certificates in pkcs12"
for name in grace cecilia; do
    openssl pkcs12 -export -nodes -in flask-local/"$name".crt -inkey flask-local/"$name".key -out flask-local/"$name".p12 -name ""$name"-flask-local" -passout pass:password
done
