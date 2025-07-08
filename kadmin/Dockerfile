FROM ubuntu:24.04

RUN apt-get update && apt-get install -y apt-utils
RUN echo krb5-admin-server krb5-admin-server/newrealm note EXAMPLE.TEST | debconf-set-selections 
RUN apt-get install -y krb5-admin-server

RUN mkdir -p /var/log/kerberos

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
