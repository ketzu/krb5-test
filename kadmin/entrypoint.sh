#!/bin/bash

set -e

# Copy configuration files from mounted data directory
cp /data/krb5.conf /etc/krb5.conf
cp /data/kdc.conf /etc/krb5kdc/kdc.conf
cp /data/kadm5.acl /etc/krb5kdc/kadm5.acl

# Start kadmin server
echo "Starting Kerberos Admin Server..."
exec /usr/sbin/kadmind -nofork
