#!/bin/bash

OSMFILE=$1
THREADS=${2:-2}

load_cmd="./src/build/utils/setup.php \
    --osm-file $OSMFILE \
    --all \
    --threads $THREADS"

load_reverse_only_cmd="./src/build/utils/setup.php \
    --osm-file $OSMFILE \
    --all \
    --threads $THREADS \
    --reverse-only"

drop_cmd="./src/build/utils/setup.php --drop"

choosen_cmd="$load_cmd"

if [ -n "$NOMINATIM_REVERSE_ONLY" ]; then
  choosen_cmd="$load_reverse_only_cmd"
fi

AS_NOMINATIM=False

if [[ $EUID -eq 0 ]]; then
  choosen_cmd="gosu nominatim:nominatim $choosen_cmd"
  drop_cmd="gosu nominatim:nominatim $drop_cmd"
  AS_NOMINATIM=True
fi

if [ $(id -u -n) = "nominatim" ]; then
  AS_NOMINATIM=True
fi

if ! [ "$AS_NOMINATIM" = "True" ]; then
  echo "Should only be run as nominatim user"
  exit 1
fi

eval "$choosen_cmd"

if [ -n "$DROP_ADTER_IMPORT" ]; then
  eval "$drop_cmd"
fi

exit 0
