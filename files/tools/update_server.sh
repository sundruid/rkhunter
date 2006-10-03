#!/bin/sh

#######################################################################
#
# Auto-updater server 1.0.0
# Author: Michael Boelen (michael AT rootkit DOT nl)
#
#######################################################################
#
# If you want to auto-update rkhunter from the official website,
# run this tool on your 'rkhunter mirror server'.
#
# Set AUTOUPDATE and the MD5 setting
# After that, put the latest version (of YOUR choice, or the automatic
# one), in the UPDATES directory, with 'latest.tar.gz' as filename.
#
#######################################################################
#
# Changelog
#
#######################################################################
#
# 1.00
# - First release

# Auto-update (0=no, 1=yes)
AUTOUPDATE=0

WORKDIR="/usr/local/rkhunter"
UPDATESDIR="/usr/local/rkhunter/updates"

# The tool which will be used to create MD5 Digests
# Linux (md5sum)
# FreeBSD (md5 -q)
MD5="md5 -q"

if [ ${AUTOUPDATE} -eq 1 ]; then
	wget http://www.rootkit.nl/rkhunter/rkhunter_latest.dat -O ${WORKDIR}/rk_latest.dat
	if [ $? -eq 0 ]; then
		if [ -f ${WORKDIR}/my_latest.dat ]; then
			MYLATEST=`cat ${WORKDIR}/my_latest.dat`      
		else
			MYLATEST="1111"
		fi
		if [ -f ${WORKDIR}/rk_latest.dat ]; then
			RKLATEST=`cat ${WORKDIR}/rk_latest.dat`
		else
			RKLATEST="0000"
		fi
		if [ ! "${MYLATEST}" = "${RKLATEST}" ]; then
			wget http://www.rootkit.nl/rkhunter/rkhunter_latest.dat -O ${UPDATESDIR}/latest.tar.gz
		fi
	else
		echo "Warning: Couldn't fetch latest information."
	fi
fi

LATESTFILE="${UPDATESDIR}/latest.tar.gz"
if [ -f ${LATESTFILE} ]; then
	${MD5} ${LATESTFILE} > ${WORKDIR}/my_latest.dat
else
	echo "${LATESTFILE} doesn't exists yet. Please create it (copy) or use auto-update"
fi
