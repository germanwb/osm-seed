#!/usr/bin/env bash

# OSMOSIS tuning: https://wiki.openstreetmap.org/wiki/Osmosis/Tuning,https://lists.openstreetmap.org/pipermail/talk/2012-October/064771.html
if [ -z "$MEMORY_JAVACMD_OPTIONS" ]; then
    echo JAVACMD_OPTIONS=\"-server\" > ~/.osmosis
else
    memory="${MEMORY_JAVACMD_OPTIONS//i}"
    echo JAVACMD_OPTIONS=\"-server -Xmx$memory\" > ~/.osmosis
fi
# Read the DB and create the planet osm file
date=`date '+%Y-%m-%d:%H:%M'`
planetPBFFile=history-latest-${date}.pbf
stateFile="state.txt"

# Creating a gcloud-service-key to authenticate the gcloud
if [ $STORAGE == "GS" ]; then
    echo $GCLOUD_SERVICE_KEY | base64 --decode --ignore-garbage > gcloud-service-key.json
    /root/google-cloud-sdk/bin/gcloud --quiet components update
    /root/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file gcloud-service-key.json
    /root/google-cloud-sdk/bin/gcloud config set project $GCLOUD_PROJECT
fi

# Creating the replication file
osmosis --read-apidb \
host=$POSTGRES_HOST \
database=$POSTGRES_DB \
user=$POSTGRES_USER \
password=$POSTGRES_PASSWORD \
validateSchemaVersion=no \
--write-pbf \
file=$planetPBFFile

# AWS
if [ $STORAGE == "S3" ]; then 
    # Save the path file
    echo "$S3_OSM_PATH/planet/full-history/$planetPBFFile" >> $stateFile
    # Upload to S3
    aws s3 cp $planetPBFFile $S3_OSM_PATH/planet/full-history/$planetPBFFile
    aws s3 cp $stateFile $S3_OSM_PATH/planet/full-history/$stateFile --acl public-read
fi

# Google Storage
if [ $STORAGE == "GS" ]; then 
    # Save the path file
    echo "$GS_OSM_PATH/planet/full-history/$planetPBFFile" >> $stateFile
    # Upload to GS
    gsutil cp $planetPBFFile $GS_OSM_PATH/planet/full-history/$planetPBFFile
    gsutil cp $stateFile $GS_OSM_PATH/planet/full-history/$stateFile
fi