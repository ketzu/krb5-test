#!/bin/bash

set -e

# Copy configuration files from mounted data directory
cp /data/krb5.conf /etc/krb5.conf
cp /data/kdc.conf /etc/krb5kdc/kdc.conf
cp /data/kadm5.acl /etc/krb5kdc/kadm5.acl

# Initialize Kerberos database if it doesn't exist
if [ ! -f /var/lib/krb5kdc/principal ]; then
    echo "Initializing Kerberos database..."
    kdb5_util -P password -r EXAMPLE.TEST create -s
    echo "Database initialized."
else
    echo "Database already exists, skipping initialization."
fi

# Start KDC
echo "Starting Kerberos KDC..."
exec /usr/sbin/krb5kdc -n
