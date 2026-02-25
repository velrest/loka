#!/bin/sh

# Configure mc to connect to our minio container
mc alias set dc-minio http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD --api S3v4;

# Only run if this is the initial setup
if [ "$1" != "-u" ]; then
  # Create buckets for DMS and alexandria
  mc mb -p dc-minio/orangerie-dev;
fi
