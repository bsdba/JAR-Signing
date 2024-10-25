#!/bin/bash
# Author Michael Brown
# Copyright 2024, Michael Brown
#
# Validates access to the CSC and lists it
#

. /etc/sysconfig/CSC
echo $KEYPASS | keytool -list -v -keystore NONE -storetype PKCS11 -providerclass sun.security.pkcs11.SunPKCS11 -providerArg $JAVA_HOME/bin/eToken.cfg 
