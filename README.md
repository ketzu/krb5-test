# Kerberos Docker Setup for Integration Testing

A ontainerized Kerberos setup designed for integration testing with minimal configuration.

## Overview

This project provides a single-container Kerberos Key Distribution Center (KDC) that:

- Initializes a Kerberos database with configurable principals
- Generates keytabs for service authentication
- Supports dynamic configuration via environment variables
- Requires minimal setup and maintenance

## Quick Start

1. **Start the KDC:**

   ```bash
   docker-compose up -d
   ```

2. **Access generated keytabs:**

   ```bash
   # Keytabs are available in the ./data directory
   ls -la ./data/*.keytab
   ```

3. **View logs:**

   ```bash
   # KDC logs
   docker-compose logs kdc

   # Or view log files directly
   tail -f ./logs/krb5kdc.log
   ```

## Configuration

### Environment Variables

The KDC container supports the following environment variables:

| Variable       | Default                 | Description                                  |
| -------------- | ----------------------- | -------------------------------------------- |
| `REALM`        | `EXAMPLE.TEST`          | Kerberos realm name                          |
| `KDC_PASSWORD` | `password`              | Master key password for database creation    |
| `PRINCIPALS`   | `admin/admin:adminpass` | Comma-separated list of principals to create |

### Principal Configuration Format

The `PRINCIPALS` environment variable accepts a comma-separated list of principals in the format:

```
principal_name:password[,principal_name:password,...]
```

**Principal Types:**

- **User principals**: `username:password` - Creates a user with the specified password
- **Service principals**: `service/hostname:randkey` - Creates a service principal with random key and generates a keytab

### Example Configuration

```yaml
# docker-compose.yml
services:
  kdc:
    environment:
      - REALM=MYCOMPANY.COM
      - KDC_PASSWORD=secretpassword
      - PRINCIPALS=admin/admin:adminpass,alice:userpass,bob:userpass,myapp/localhost:randkey,HTTP/testserver:randkey
```

## Keytab Generation

### Automatic Keytab Generation

Service principals (those with `randkey` password) automatically generate keytabs:

```yaml
PRINCIPALS=myapp/localhost:randkey,HTTP/testserver:randkey
```

This creates:

- `/data/myapp_localhost.keytab` - For service `myapp/localhost@REALM`
- `/data/HTTP_testserver.keytab` - For service `HTTP/testserver@REALM`

### Keytab File Naming

Keytab files are named by replacing forward slashes with underscores:

- `service/hostname` → `service_hostname.keytab`
- `HTTP/myserver` → `HTTP_myserver.keytab`

### Using Keytabs in Tests

```bash
# Export keytab location
export KRB5_KTNAME=/path/to/data/myapp_localhost.keytab

# Authenticate using keytab
kinit -k myapp/localhost@EXAMPLE.TEST

# Verify authentication
klist
```

### Volume Mounts

- `/data` - Configuration files and generated keytabs
- `/var/log/kerberos` - Log files
- `/var/lib/krb5kdc` - Database files (persistent across restarts)
