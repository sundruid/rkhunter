#!/bin/sh

#######################################################################
#
# Auto-updater client 1.0.1
# Author: Michael Boelen (michael AT rootkit DOT nl)
#
#######################################################################
#
# Change URLPREFIX (in your virutal host, WITHOUT ending slash)
# Be sure you have put the latest stable file into the correct
# directory (at your server)
# Change the actions in this scripts (scroll down)
#
#######################################################################
#
# Changelog
#
#######################################################################
#
# 1.0.1
# - Extended texts
# 1.00
# - First release

WORKDIR="/usr/local/rkhunter"
UPDATESDIR="/usr/local/rkhunter/updates"

# Without ending slash
URLPREFIX="http://www.mydomain.com/rkhunter"

# The tool which will be used to create MD5 Digests
# Linux (md5sum)
# FreeBSD (md5 -q)
MD5="md5 -q"

if [ ${AUTOUPDATE} -eq 1 ]; then
  wget ${URLPREFIX}/rk_latest.dat -O ${WORKDIR}/rk_latest.dat
  if [ $? -eq 0 ]
    then
      MYLATEST=`cat ${WORKDIR}/my_latest.dat`      
     
      if [ -f ${WORKDIR}/rk_latest.dat ]; then
        RKLATEST=`cat ${WORKDIR}/rk_latest.dat`
	else
	RKLATEST="0000"
      fi

      # If there is a new version, do some actions.
      # CHANGE THE FILES BELOW 
      if [ ! "${MYLATEST}" = "${RKLATEST}" ]
        then
	  # - Insert get option here
	  # wget ${URLPREFIX}/latest.tar.gz
          # - Insert here install option
	  # cp latest.tar.gz /usr/local/install/latest.tar.gz
	  # cd /usr/local/install
	  # tar xfvz latest.tar.gz
	  # cd rkhunter
	  # ./installer.sh
	  # - Add some cleanup options here
	  echo "Action here"
      fi
      cp ${WORKDIR}/rk_latest.dat ${WORKDIR}/my_latest.dat

    else
      echo "Warning: Couldn't fetch latest information."
  fi
fi

