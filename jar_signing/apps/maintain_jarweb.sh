#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Run weekly to update shared userjarlist.web file
#
. /u01/app/oracle/apps/EBSapps.env run
NEWFILES=/tmp/jarlist.web
# Weblist should be in a location accessible to all apps nodes
WEBLIST=/stage/EBS/usedjarlist.web
cd $FMW_HOME/webtier/instances/EBS_web_OHS1/diagnostics/logs/OHS/EBS_web
if [ -f $WEBLIST ]; then
  cp $WEBLIST $NEWFILES
fi
cat access* | awk ' $7 ~ /^\/OA_JAVA\/.*.jar/ && $(NF-1) < 400 {print $7}' | sort -u >> $NEWFILES
cat $NEWFILES | sort -u > ${NEWFILES}.1
cmp -s $WEBLIST ${NEWFILES}.1
status=$?
echo $status
if [ $status -ne 0 ]; then
  echo "Found new jar files in the access logs"
  cp ${NEWFILES}.1 $WEBLIST
fi
rm -f $NEWFILES ${NEWFILES}.1

