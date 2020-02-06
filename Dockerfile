# Intermediate container - PHP with Apache, plus Osmosis, plus Osmium
FROM webdevops/php-apache:7.4 AS php-with-osmosis-and-osmium

# Install osmosis
RUN mkdir -p /opt/osmosis && \
    cd /opt/osmosis && \
    wget -O osmosis-latest.tgz https://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz && \
    tar xvfz osmosis-latest.tgz && \
    rm osmosis-latest.tgz && \
    chmod a+x bin/osmosis && \
    ln -s /opt/osmosis/bin/osmosis /usr/local/bin/osmosis

# Install osmium
RUN apt-get -y update -qq && \
    apt-get install -y --no-install-recommends python3-pip && \
    pip3 install --no-cache-dir osmium && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*


# Nominatim container
FROM php-with-osmosis-and-osmium AS nominatim

RUN apt-get -y update -qq && \
    apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev \
    libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
    postgresql-server-dev-11 postgresql-contrib-11 \
    libboost-python-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*

# Nominatim install
ENV NOMINATIM_VERSION v3.4.1

RUN groupadd -r -g 403 nominatim && \
    useradd -r -u 403 -g nominatim -m -d /home/nominatim -s /bin/bash -c Nominatim nominatim

RUN mkdir -p /home/nominatim && cd /home/nominatim && git clone --recursive https://github.com/openstreetmap/Nominatim ./src && \
    cd ./src && git checkout tags/$NOMINATIM_VERSION && git submodule update --recursive --init && \
    mkdir build && cd build && cmake .. && make && \
    rm -rf /home/nominatim/src/.git && \
    chown -R nominatim:nominatim /home/nominatim

# Load initial data
RUN curl http://www.nominatim.org/data/country_grid.sql.gz > /home/nominatim/src/data/country_osm_grid.sql.gz && \
    chmod o=rwx /home/nominatim/src/build

COPY nominatim/local.php /home/nominatim/src/build/settings/local.php
COPY nominatim/loadmapfile.sh /home/nominatim/loadmapfile.sh

RUN chown -R nominatim:nominatim /home/nominatim

COPY nominatim/10-nominatim.conf /opt/docker/etc/httpd/conf.d/

ENV PHP_DISMOD=amqp,apcu,bcmath,bz2,curl,gd,imagick,imap,ioncube,ldap,mbstring,memcached,mongodb,mysqli,mysqlnd,pdo_mysql,pdo_sqlite,redis,soap,sqlite3,vips,zip

USER nominatim
WORKDIR /home/nominatim


# Postgres with PostGIS container
FROM kartoza/postgis:11.0-2.5 AS nominatim-postgres

# It requires nominatim.so library for C- functions - we copy it from nominatim container
COPY --from=nominatim /home/nominatim/src/build/module/nominatim.so /home/nominatim/src/build/module/nominatim.so 
RUN chown -R postgres:postgres /home/nominatim

COPY postgres/create-www-data-user.sql /docker-entrypoint-initdb.d/create-www-data-user.sql

ENV POSTGRES_USER=nominatim
ENV POSTGRES_PASS=nominatim1234
ENV POSTGRES_DBNAME=nominatim
ENV POSTGRES_TEMPLATE_EXTENSIONS=true
ENV POSTGRES_MULTIPLE_EXTENSIONS=postgis,hstore,postgis_topology
ENV EXTRA_CONF=include_dir='conf.d'
