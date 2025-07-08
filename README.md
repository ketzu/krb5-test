# Kerberos Docker Setup for Integration Testing

A lightweight, containerized Kerberos setup designed for integration testing with minimal configuration and maximum flexibility.

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

## Integration Testing Examples

### Java Application with Kerberos

```yaml
# docker-compose.yml for testing
services:
  kdc:
    environment:
      - REALM=TEST.REALM
      - PRINCIPALS=testuser:testpass,myapp/localhost:randkey
    volumes:
      - ./data:/data

  app:
    depends_on:
      - kdc
    environment:
      - KRB5_CONFIG=/data/krb5.conf
      - KRB5_KTNAME=/data/myapp_localhost.keytab
    volumes:
      - ./data:/data
```

### Python Application Testing

```python
# test_kerberos.py
import os
import subprocess

def test_kerberos_auth():
    # Set environment
    os.environ['KRB5_CONFIG'] = '/data/krb5.conf'
    os.environ['KRB5_KTNAME'] = '/data/myapp_localhost.keytab'

    # Authenticate
    result = subprocess.run(['kinit', '-k', 'myapp/localhost@EXAMPLE.TEST'],
                          capture_output=True, text=True)
    assert result.returncode == 0

    # Verify ticket
    result = subprocess.run(['klist'], capture_output=True, text=True)
    assert 'myapp/localhost@EXAMPLE.TEST' in result.stdout
```

### Web Service Testing

```yaml
# For testing web services with Kerberos authentication
services:
  kdc:
    environment:
      - REALM=WEB.TEST
      - PRINCIPALS=HTTP/webapp:randkey,testuser:testpass

  webapp:
    depends_on:
      - kdc
    environment:
      - KRB5_CONFIG=/data/krb5.conf
      - KRB5_KTNAME=/data/HTTP_webapp.keytab
      - SERVICE_PRINCIPAL=HTTP/webapp@WEB.TEST
```

## Directory Structure

```
.
├── docker-compose.yml          # Main compose file
├── data/                      # Configuration and keytabs
│   ├── krb5.conf             # Kerberos client configuration
│   ├── kdc.conf              # KDC configuration
│   ├── kadm5.acl             # Admin ACL (legacy, minimal impact)
│   └── *.keytab              # Generated keytabs
├── logs/                     # Log files
│   └── krb5kdc.log          # KDC logs
└── kdc/                      # KDC container
    ├── Dockerfile            # Container definition
    └── entrypoint.sh         # Initialization script
```

## Architecture

### Single Container Design

- **KDC (Key Distribution Center)**: Handles authentication requests
- **Database**: SQLite-based principal database
- **Configuration**: Runtime configuration via mounted volumes
- **Keytabs**: Generated during initialization and stored in `/data`

### Initialization Process

1. **Database Creation**: Creates Kerberos database if it doesn't exist
2. **Principal Creation**: Parses `PRINCIPALS` environment variable
3. **Keytab Generation**: Creates keytabs for service principals
4. **Service Start**: Starts KDC daemon

### Volume Mounts

- `/data` - Configuration files and generated keytabs
- `/var/log/kerberos` - Log files
- `/var/lib/krb5kdc` - Database files (persistent across restarts)

## Troubleshooting

### Common Issues

**Database initialization fails:**

```bash
# Check if database files exist
docker-compose exec kdc ls -la /var/lib/krb5kdc/

# View initialization logs
docker-compose logs kdc
```

**Keytab not found:**

```bash
# List generated keytabs
ls -la ./data/*.keytab

# Check principal creation logs
docker-compose logs kdc | grep "Creating"
```

**Authentication fails:**

```bash
# Test with kinit
kinit testuser@EXAMPLE.TEST

# Check ticket cache
klist

# Verify KDC is running
docker-compose ps
```

### Debug Mode

Enable detailed logging by modifying `/data/kdc.conf`:

```ini
[logging]
    kdc = FILE:/var/log/kerberos/krb5kdc.log
    admin_server = FILE:/var/log/kerberos/kadmin.log
    default = FILE:/var/log/kerberos/krb5lib.log
```

## Security Considerations

⚠️ **Warning**: This setup is designed for testing environments only.

- Uses weak default passwords
- Stores keytabs in plain text
- No encryption for inter-container communication
- Simplified ACL configuration

**For production use:**

- Use strong, randomly generated passwords
- Implement proper key management
- Enable network encryption
- Configure proper access controls

## Advanced Usage

### Custom Principal Creation

Create additional principals after startup:

```bash
# Connect to container
docker-compose exec kdc bash

# Add new principal
kadmin.local -q "addprinc -pw newpassword newuser@EXAMPLE.TEST"

# Generate new keytab
kadmin.local -q "ktadd -k /data/newservice.keytab newservice/host@EXAMPLE.TEST"
```

### Multiple Realms

For testing cross-realm authentication, modify the configuration:

```yaml
# Additional KDC for different realm
services:
  kdc2:
    build: kdc/
    environment:
      - REALM=ANOTHER.TEST
      - PRINCIPALS=crossuser:crosspass
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with integration scenarios
5. Submit a pull request

## License

This project is provided as-is for testing purposes.
