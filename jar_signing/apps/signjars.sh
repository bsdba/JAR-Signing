#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Configure $CSC_HOST to be accessible via ssh using key pair
#
# Signs all jar files older than $DAYS using $CSC_HOST
#
export CSC_HOST=mycschost.domain
if [ "$JAVA_TOP" = "" ]; then
  echo "Environment must be set"
  exit 1
fi
TIMESTAMP='Y'
if [ "$#" -eq 1 ]; then
  if [ "$1" = "--notime" ]; then
     TIMESTAMP='N'
  else
     echo "Usage $(basename $0) [--notime]"
     exit
  fi
fi
FILES=/tmp/jarlist.$$
export FILES

cd $JAVA_TOP
find . -type f -name '*.jar' -mtime -1 > $FILES
fc=$(wc -l $FILES | cut -f1 -d' ')
if [ $fc -eq 0 ]; then
  echo "Nothing to do"
  exit 0
fi
echo "Found jar files changed in the last day"
echo "Signing $fc jar files"
HOST=$(hostname | cut -f1 -d.)
export HOST
ssh $CSC_HOST mkdir -p "${HOST}"
ssh $CSC_HOST rm -rf "$HOST/*"
rsync $FILES $CSC_HOST:"$HOST/jarlist.txt"
for fn in $(cat $FILES)
do
  ssh $CSC_HOST mkdir -p "${HOST}/$(dirname $fn)"
  rsync $fn $CSC_HOST:"${HOST}/$fn"
done
if [ "$TIMESTAMP" = 'Y' ]; then
   ssh $CSC_HOST bin/signall_time.sh $HOST
else
  ssh $CSC_HOST bin/signall.sh $HOST
fi
status=$?
if [ $status -ne 0 ]; then
  echo "1 or more files did not sign correctly"
fi
rsync -a $CSC_HOST:"${HOST}/*" .
