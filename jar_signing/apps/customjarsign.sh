#! /bin/bash
# $Header: customjarsign.sh 120.0.12020000.5 2024/06/12 07:54:46 rsatyava noship $
# +===========================================================================+
# |  Copyright (c) 2024, Oracle and/or its affiliates.                        |
# |                        All rights reserved.                               |
# |                       Version 12.0.0                                      |
# +===========================================================================+
# |
# | FILENAME
# |   customjarsign.sh
# |
# | DESCRIPTION
# |   Code signing script to sign client jars using custom process.
# |   This script will be called from AD patch tools and from adadmin. when AD_SIGN_MODE is CUSTOM
# |   This script will be called by AD with the full pathname of the jarlist.txt file,
# |   The jarlist.txt file contains full pathnames of JARs that must be signed, one per line
# |   This script must exit 0 upon success and something else in case of error
# |   This script must do it's own logging (error and debug).
# |
# | USAGE
# |      customjarsign.sh /path/to/jarlist.txt
# |
# | CHANGE LOG:
# |     "ER 36492441 - CONFIGURABLE JAR SIGNING FOR ORACLE E-BUSINESS SUITE."
# |
# +===========================================================================+
# dbdrv: none 

# Since this is a template file adding a template variable to avoid GSCC error
# node_info_file='/u01/app/oracle/apps/fs1/FMW_Home/Oracle_EBS-app1/applications/oacore/APP-INF/node_info.txt'
#

# print usage and exit
#-------------------------------------------------------------------------------
usage ()
{
   echo >&2 "usage: $pgm  /path/to/jarlist.txt"
   exit 1
}

# print error message and exit
#-------------------------------------------------------------------------------
errexit ()
{
   echo >&2 "ERROR: $1"
   exit 1
}

# validate the jarlist.txt file
#-------------------------------------------------------------------------------
validatejarlist ()   #  $1 name of file listing JARs
{
  jarlist="$1"
  if [ ! -f "$jarlist" ] ;then
     errexit "jarlist file '$jarlist' does not exist"
  fi

  if [ ! -r "$jarlist" ] ;then
     errexit "Cannot read jarlist file '$jarlist'"
  fi

  jars=$( grep '^/.*\.jar' "$jarlist" )

  njars=$( echo "$jars" | wc -l )
  if [ "$njars" -eq 0 ] ;then 
     errexit "No JARs in jarlist file '$jarlist'"
  fi

  for jar in $jars ;do
    if [ ! -f "$jar" ] ;then
       errexit "JAR '$jar' does not exist"
    fi
    if [ ! -r "$jar" ] ;then
       errexit "Cannot read JAR '$jar'"
    fi
    if [ ! -w "$jar" ] ;then
       errexit "Cannot write JAR '$jar'"
    fi
  done 

  echo "INFO: Validated read/write-ability of $njars JAR files from '$jarlist'"
}

# This test function relies on an already configured native JAR signing setup.
# Adjust keystore passwords if not default.

# sign one JAR using KEYSTORE file 
#-------------------------------------------------------------------------------
signjar_keystore ()  #  $1 name of 1 JAR file
{
  if [ -d "$APPL_TOP_NE" ] ;then   # EBS R12.2
     JRIDIR="$APPL_TOP_NE/ad/admin"
  else
     JRIDIR="$APPL_TOP/admin"
  fi
  AD_KEYSTORE="$JRIDIR/adkeystore.dat"
  AD_KEYSTORE_ALIAS=$( awk '{print $1}' "$JRIDIR/adsign.txt" )
  AD_SIGFILE=$(        awk '{print $3}' "$JRIDIR/adsign.txt" )

  export AD_KEYSTORE_SPASS="puneet"
  export AD_KEYSTORE_KPASS="myxuan"

  ztsaurl="http://timestamp.digicert.com"
  zproxyhost="www-proxy"
  zproxyport=80
  timestamp="-tsa ${ztsaurl} -J-Dhttp.proxyHost=${zproxyhost} -J-Dhttp.proxyPort=${zproxyport}"

  echo "INFO: KEYSTORE Signing JAR '$1' ..."

  jarsigner -keystore "${AD_KEYSTORE}" -storepass:env AD_KEYSTORE_SPASS -keypass:env AD_KEYSTORE_KPASS \
	$timestamp -sigfile "${AD_SIGFILE}" "$1" "${AD_KEYSTORE_ALIAS}" 

  return $?
}

# This test function assumes Digicert PKCS11 signing cloud service
# You will have to install the code and set parameters provided by Digicert
# Other commercial CAs have similar PKCS11 solutions

# sign one JAR using PKCS11 provider for Java jarsigner
#-------------------------------------------------------------------------------
signjar_pkcs11 ()  #  $1 name of 1 JAR file
{
  AD_PKCS11_providerArg="pkcs11properties.cfg"		# config file to load DLL or SO //
  AD_PKCS11_ALIAS="032452-9823742-987234"		# from HSM or CloudKey //
  AD_PKCS11_TIMESTAMP="http://timestamp.digicert.com"	# URL to your commercial CA's timestamp service 
  AD_SIGFILE="CUST"

  zproxyhost="www-proxy"
  zproxyport=80
  timestamp="-tsa $AD_PKCS11_TIMESTAMP -J-Dhttp.proxyHost=${zproxyhost} -J-Dhttp.proxyPort=${zproxyport}"

  # set variables required by the the DLL or SO that implements the PKCS11 provider
  export SM_HOST=https://clientauth.one.digicert.com 
  export SM_API_KEY="<API key>"
  export SM_CLIENT_CERT_FILE=idkeystore.p12
  export SM_CLIENT_CERT_PASSWORD="<password>"

  echo "INFO: PKCS11 Signing JAR '$1' ..."

  jarsigner -keystore NONE -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg "${AD_PKCS11_providerArg}" \
	$timestamp -sigfile "${AD_SIGFILE}"  "$1" "${AD_PKCS11_ALIAS}"

  return $?
}

# sign one JAR file using YOUR custom scripting
#-------------------------------------------------------------------------------
signjar_custom ()  #  $1 name of 1 JAR file
{
  /home/oracle/dba/bin/signjar.sh "$1"
  status=$?
  return $status
}


# sign one JAR file - pick the sample function to try/test
#-------------------------------------------------------------------------------
signjar ()  #  $1 name of 1 JAR file
{
  # Switch between signing options
   # signjar_keystore  "$1"	# this option simply piggybacks on an existing KEYSTORE setup, for testing of CUSTOM mode
   # signjar_pkcs11    "$1"	# if a Cloudy HSM is installed and the PKCS#11 provider has been configured
     signjar_custom    "$1"	# anything you want...
}

# sign all JARs in the jarlist.txt file - one by one
#-------------------------------------------------------------------------------
signjars ()  #  $1 name of file listing JARs
{
  jars=$( cat "$1" | grep '^/.*\.jar' )
  for jar in $jars ;do
    if ! signjar "$jar" ; then
       errexit "Error signing JAR '$jar'"
    fi
  done
}

# MAIN processing
#-------------------------------------------------------------------------------

pgm=$(basename "$0")
pgm=$0

case  $# in
  1 ) : ;;      # one and only parameter is the pathname of jarlist.txt
  * ) usage ;;
esac

validatejarlist "$1"	# validate input file, exits in case of error

signjars "$1"		# sign all JARs in input file, exits in case of error

exit  $?

# END of customsign.sh
