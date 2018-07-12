FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -q -y update 
RUN apt-get -q -y install amavisd-new spamassassin libdbi-perl libdbd-mysql-perl\
                          arj bzip2 cabextract cpio file gzip nomarch pax unzip zoo zip zoo \
                          \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 
ADD data/spamassassin/plugins /etc/spamassassin/plugins

CMD ["amavisd-new", "foreground"]
