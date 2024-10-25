#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Signs all files in the file jarlist.txt in the directory passed as Arg 1
#

if [ "$#" -ne 1 ]; then
   echo "$(basename $0): Usage $(basename $0) directory containing jarlist.txt"
   exit 127
fi
if [ ! -d $1 ]; then
   echo "$1 not found"
   exit 127
fi
cd $1
LOG=/tmp/$(basename $0).$$
OUT=/tmp/$(basename $0).out.$$
LOGDEST=/home/oracle/log
RUNNAME="$(basename $0)-$1"
date > $LOG
date > $OUT
if [ -f jarlist.txt ]; then
   fc=$(wc -l jarlist.txt | cut -f1 -d' ')
   if [ $fc -eq 0 ]; then
      echo "Nothing to do"
      echo "Nothing to do" >> ${LOGDEST}/${RUNNAME}.log
      exit 0
   fi
else
   echo "No jarlist.txt is present" 
   echo "No jarlist.txt is present" >> ${LOGDEST}/${RUNNAME}.log
   exit 127
fi
. /etc/sysconfig/CSC
stat=0
for fn in $(cat jarlist.txt)
do
  echo "Signing $fn"
  echo "Removing prior signature if any"
  unzip -l $fn 'META-INF/*.SF' 'META-INF/*.RSA'
  zip -d $fn 'META-INF/*.SF' 'META-INF/*.RSA'
  #echo $KEYPASS | jarsigner -verbose:all -keystore NONE -storetype PKCS11 -tsa http://timestamp.globalsign.com/tsa/r6advanced1 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg $JAVA_HOME/bin/eToken.cfg $fn $ALIAS >>$OUT
  echo $KEYPASS | jarsigner -verbose:all -keystore NONE -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg $JAVA_HOME/bin/eToken.cfg $fn $ALIAS >>$OUT 2>/dev/null
  status=$?
  if [ "$status" -eq 0 ]; then
   echo "$fn signed successfully" >>$LOG
   echo "$fn signed successfully" 
  else
   echo "ERROR: $fn was not signed, exit status $status" >>$LOG
   echo "ERROR: $fn was not signed, exit status $status"
   stat=1
  fi
done
mv $LOG ${LOGDEST}/${RUNNAME}.log
mv $OUT ${LOGDEST}/${RUNNAME}.out
cat ${LOGDEST}/${RUNNAME}.log
exit $stat
