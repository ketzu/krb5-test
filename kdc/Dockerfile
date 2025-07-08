FROM ubuntu:24.04

RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y krb5-kdc

RUN mkdir -p /var/log/kerberos
RUN mkdir -p /var/lib/krb5kdc/

EXPOSE 88

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
