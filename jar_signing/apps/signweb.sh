#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Configure $CSC_HOST to be accessible via ssh using key pair
#
# Signs all jar files accessed via client listed in $FILES using $CSC_HOST
#
export CSC_HOST=mycschost.domain

if [ "$JAVA_TOP" = "" ]; then
  echo "Environment must be set"
  exit 1
fi
# Shared file maintained by maintain_jarweb.sh
FILES=/stage/EBS/usedjarlist.web
JARS=/tmp/jarlist_$$.txt
if [ ! -s "$FILES" ]; then
  echo "$FILES not found or is emply"
  exit 127
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
export FILES
cat $FILES |  sed "s:^/OA_JAVA:.$JAVA_TOP:"   | sed 's:^/:./:' > $JARS


cd $JAVA_TOP
fc=$(wc -l $JARS | cut -f1 -d' ')
if [ $fc -eq 0 ]; then
  echo "Nothing to do"
  rm -f $JARS
  exit 0
fi
echo "Signing $fc jar files"
HOST=$(hostname | cut -f1 -d.)
export HOST
ssh $CSC_HOST mkdir -p "${HOST}"
ssh $CSC_HOST rm -rf "$HOST/*"
rsync $JARS $CSC_HOST:"$HOST/jarlist.txt"
for fn in $(cat $JARS)
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
rm -f $JARS
