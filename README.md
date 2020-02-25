Nominatim API Image:

  - based on [WebDevops PHP-Apache image](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-apache.html#), so contains recent PHP with a lot of modules with Apache web-server
  - added [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis) binary
  - installed [Osmium Tool](ihttps://osmcode.org/osmium-tool/manual.html#introduction)
  - installed [osmctools](https://gitlab.com/osm-c-tools/osmctools)
  - added osmium-tools and osmctools
  - runs as user _nominatim_ from `/home/nominatim`
  - most of PHP modules present in the image are disabled (pre-set in `PHP_DISMOD` env var)

Nominatim PostgreSQL image:
  - based on [kartoza Docker-PostGIS image](https://github.com/kartoza/docker-postgis)
  - Nominatim requires database to run external C function from nominatim library - 
      for this to work in separate container we copy library built during Nominatim API build
      into PostgreSQL container

docker-compose file with separate PostgreSQL and Nominatim API containers
  - 
  - postgresql has 

Build nominatim and postgres images:
```
docker-compose build
```


* You can create _external_ docker volume for nominatim database, to be safe if accidentally calling `down -v`.

Based on these answers: [one](https://help.openstreetmap.org/questions/48843/merging-two-or-more-geographical-areas-to-import-two-or-more-osm-files-in-nominatim), [two](https://stackoverflow.com/questions/22960641/how-to-load-multiple-osm-files-into-nominatim).

```
# Convert needed files into o5m format
osmconvert ukraine-latest.osm.pbf -o=ukraine-latest.o5m
osmconvert bulgaria-latest.osm.pbf -o=bulgaria-latest.o5m

# Merge result into one file
osmconvert ukraine-latest.o5m ukraine-latest.o5m -o=together.o5m

# Convert merged file into pbf
osmconvert together.o5m -o=together.osm.pbf
```

```
./src/builld/utils/setup.php --osm-file /maps/together.osm.pbf --all --thread 8
```


Alternatively, you can run all import steps manually one by one, as `--all` flag does.
I.e., if yu want to use already created empty database - yu can skip first step `--create-db`.

```
create-db
setup-db
import-data --osm-file
create-functions
create-tables [--reverse-only]
create-partition-tables
create-partition-functions
import-wikipedia-articles
load-data
calculate-postcodes
index
create-search-indices
create-country-names
```
