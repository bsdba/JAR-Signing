#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Configure $CSC_HOST to be accessible via ssh using key pair
#
# Signs single jar file designed to be called from customjarsign.sh
#

export CSC_HOST=mycschost.domain
if [ "$JAVA_TOP" = "" ]; then
  echo "Environment must be set"
  exit 1
fi
TIMESTAMP='Y'
if [ "$#" -eq 2 ]; then
  if [ "$1" = '--notime' ]; then
     TIMESTAMP='N'
     shift
  else
    echo "Usage: $(basename $0) [--notime] jarfile"
    exit 1
  fi
elif [ "$#" -ne 1 ]; then
  echo "Usage: $(basename $0) [--notime] jarfile"
  exit 1
fi
FILE="$1"
HOST=$(hostname | cut -f1 -d.)
export HOST
echo "Signing $FILE"
ssh $CSC_HOST mkdir -p "${HOST}"
ssh $CSC_HOST rm -rf "$HOST/*"
ssh $CSC_HOST mkdir -p "${HOST}/$(dirname $FILE)"
rsync -v $FILE $CSC_HOST:"${HOST}/$FILE"
if [ "$TIMESTAMP" = 'Y' ]; then
  ssh $CSC_HOST bin/signjar_time.sh $HOST/$FILE
else
  ssh $CSC_HOST bin/signjar.sh $HOST/$FILE
fi
status=$?
if [ $status -ne 0 ]; then
  echo "File did not sign correctly"
  exit $status
fi
rsync -v $CSC_HOST:"${HOST}/$FILE" $FILE
