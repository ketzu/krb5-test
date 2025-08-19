#!/bin/bash

set -e

# Set default values for environment variables
REALM=${REALM:-EXAMPLE.TEST}
KDC_PASSWORD=${KDC_PASSWORD:-password}
PRINCIPALS=${PRINCIPALS:-"admin/admin:adminpass"}
IFS=',' read -ra PRINCIPAL_ARRAY <<< "$PRINCIPALS"

# Copy configuration files from mounted data directory
cp /data/krb5.conf /etc/krb5.conf
cp /data/kdc.conf /etc/krb5kdc/kdc.conf
cp /data/kadm5.acl /etc/krb5kdc/kadm5.acl

# Initialize Kerberos database if it doesn't exist
if [ ! -f /var/lib/krb5kdc/principal ]; then
    echo "Initializing Kerberos database for realm: $REALM"
    kdb5_util -P "$KDC_PASSWORD" -r "$REALM" create -s
    echo "Database initialized."
else
    echo "Database already exists."
fi

echo "Removing all existing keytabs"
rm -f /data/*.keytab

# Create principals
echo "Creating principals and keytabs..."
for principal in "${PRINCIPAL_ARRAY[@]}"; do
    IFS=':' read -r principal_name password <<< "$principal"
    if [ "$password" = "randkey" ]; then
        if kadmin.local -q "getprinc $principal_name@$REALM" >/dev/null 2>&1; then
            echo "Principal $principal_name@$REALM already exists"
        else
            echo "Creating service principal: $principal_name@$REALM"
            kadmin.local -q "addprinc -randkey $principal_name@$REALM"
        fi
        # Generate keytab
        keytab_name=$(echo "$principal_name" | sed 's/\//_/g')
        kadmin.local -q "ktadd -k /data/${keytab_name}.keytab $principal_name@$REALM"
        echo "Keytab created: /data/${keytab_name}.keytab"
    else
        if kadmin.local -q "getprinc $principal_name@$REALM" >/dev/null 2>&1; then
            echo "Principal $principal_name@$REALM already exists"
        else
            echo "Creating user principal: $principal_name@$REALM"
            kadmin.local -q "addprinc -pw $password $principal_name@$REALM"
        fi
    fi
done
echo "Principal creation completed."

# Start KDC
echo "Starting Kerberos KDC for realm: $REALM"
exec /usr/sbin/krb5kdc -n
