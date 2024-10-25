#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Signs the file passed as arg 1 
#

if [ "$#" -ne 1 ]; then
   echo "$(basename $0): Usage $(basename $0) jarfile"
   exit 127
fi
if [ ! -f $1 ]; then
   echo "$1 not found"
   exit 127
fi
. /etc/sysconfig/CSC
echo "Removing prior signature if any"
unzip -l $1 'META-INF/*.SF' 'META-INF/*.RSA'
zip -d $1 'META-INF/*.SF' 'META-INF/*.RSA'
#echo $KEYPASS | jarsigner -verbose:all -keystore NONE -storetype PKCS11 -tsa http://timestamp.globalsign.com/tsa/r6advanced1 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg $JAVA_HOME/bin/eToken.cfg $1 $ALIAS
echo $KEYPASS | jarsigner -verbose:all -keystore NONE -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg $JAVA_HOME/bin/eToken.cfg $1 $ALIAS
status=$?
if [ "$status" -eq 0 ]; then
   echo "$1 signed successfully"
   exit 0
else
   echo "ERROR: $1 was not signed, exit status $status"
   exit $status
fi
