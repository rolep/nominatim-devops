FROM webdevops/php-apache:7.4 AS with-osmosis-and-osmium

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



FROM with-osmosis-and-osmium AS build

RUN apt-get -y update -qq && \
    apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev \
    libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
    postgresql-server-dev-11 postgresql-11-postgis-2.5 postgresql-contrib-11 \
    libboost-python-dev

# Nominatim install
ENV NOMINATIM_VERSION v3.4.1
RUN mkdir -p /home/nominatim && cd /home/nominatim && git clone --recursive https://github.com/openstreetmap/Nominatim ./src && \
    cd ./src && git checkout tags/$NOMINATIM_VERSION && git submodule update --recursive --init && \
    mkdir build && cd build && cmake .. && make && \
    rm -rf /home/nominatim/src/.git

# Load initial data
RUN curl http://www.nominatim.org/data/country_grid.sql.gz > /home/nominatim/src/data/country_osm_grid.sql.gz
RUN chmod o=rwx /home/nominatim/src/build

COPY local.php /home/nominatim/src/build/settings/local.php
COPY loadmapfile.sh /home/nominatim/loadmapfile.sh



FROM with-osmosis-and-osmium

RUN groupadd -r -g 403 nominatim && \
    useradd -r -u 403 -g nominatim -m -d /home/nominatim -s /bin/bash -c Nominatim nominatim

COPY --from=build /home/nominatim /home/nominatim/
RUN chown -R nominatim:nominatim /home/nominatim

COPY 10-nominatim.conf /opt/docker/etc/httpd/conf.d/

ENV NOMINATIM_VERSION v3.4.1

USER nominatim
WORKDIR /home/nominatim
