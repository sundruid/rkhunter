#!/bin/sh

if [ "$1" = "" -o "$2" = "" -o "$3" = "" -o "$4" = "" -o "$5" = "" ]
  then
    echo "Usage $0 <path/to/rkhunter.conf> <path/to/mirrors.dat> </path/to/dbdir> </path/to/md5>" 
    exit 1
fi 

WGETFOUND=0
CONFFILE=$1
# Mirrors
MIRRORFILE=$2
DBDIR=$3
MD5=$4
LOGFILE=$5

debug()
  {
    echo $1 >> ${LOGFILE}
  }

debug "--------------------------------------------------"
debug "Updater output:"

BINPATHS="/bin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /sw/bin"

for I in ${BINPATHS}; do
  J=${I}"/wget"
    if [ -f ${J} ]; then
      WGETFOUND=1
      WGETBINARY=${J}
    fi
done

if [ ${WGETFOUND} -eq 0 ]
  then
    echo "Fatal error: can't find WGet"
    exit 1
fi

# Retrieve file info
FILEINFO=`cat ${CONFFILE} | grep 'UPDATEFILEINFO=' | tr -d 'UPDATEFILEINFO='`

if [ "${FILEINFO}" = "" ]
  then
    echo "Fatal error. Missing line 'UPDATEFILEINFO=' or wrong/non-existing file"
    echo "Please check your configuration file (${CONFFILE})"
    exit 1
fi

checkupdate()
  {
    echo -n "${FILEDESC}: "  
    UPDATEDBURL="${FIRSTMIRROR}/${VERSIONUPDATEURL}"
    LATESTVERSION="`${WGETBINARY} -q -O - ${UPDATEDBURL}`"
    if [ "${LATESTVERSION}" = "" ]
      then
        echo "ERROR"
        echo "Fatal error: Problem while fetching file"
        exit 1
    fi
      
    CURRENTVERSION=`cat ${DBDIR}/${FILENAME} | grep '000:version' | cut -d ':' -f3`
    if [ "${CURRENTVERSION}" = "" ]
      then
        CURRENTVERSION=`cat ${DBDIR}/${FILENAME} | grep 'version=' | cut -d '=' -f2`
	if [ "${CURRENTVERSION}" = "" ]
	  then
            echo "ERROR"
            echo "Fatal error: no valid version tag in filename"
	    exit 1
	fi
    fi
    
    if [ "${LATESTVERSION}" = "" ]
      then
        echo "Skipped"
        echo "Error: can't obtain valid version tag from downloaded file (or 404 error). Possible outdated mirror."
	debug "Tried to fetch ${UPDATEDBURL}"
      else


        if [ ${CURRENTVERSION} -lt ${LATESTVERSION} ]
          then
	    echo "${WHITE}Update available${NORMAL}"

	    # Fetch file
	    GETFILE="${FIRSTMIRROR}/${FILENAME}.gz"
	    TMPFILE="`mktemp ${DBDIR}/rkhunter.upd.gz.XXXXXX`" || exit 1
	    
	    if [ ! "`${WGETBINARY} -q -O - ${GETFILE} | gunzip -c > ${TMPFILE}`" ]
	      then	      
	        cat ${TMPFILE} >${DBDIR}/${FILENAME}
		echo "  Action: Database updated (current version: ${CURRENTVERSION}, new version ${LATESTVERSION})"
	      else
	        echo "Fatal error: Can't retrieve file: ${GETFILE}"
	    fi
	    rm -f ${TMPFILE}
	  else
	    if [ ${CURRENTVERSION} -gt ${LATESTVERSION} ]
	      then
	        echo "Mirror outdated. Skipped"
		echo "  Info (current version: ${CURRENTVERSION}, version of mirror: ${LATESTVERSION})"
	      else
	        echo "Up to date"
	    fi
        fi
    fi
  }


if [ -f ${MIRRORFILE} ]
  then

    MIRRORSVERSION=`cat ${MIRRORFILE} | grep 'version=' | head -n 1`

    # Retrieve first mirror
    FIRSTMIRROR=`cat ${MIRRORFILE} | grep 'mirror=' | head -n 1`
    OTHERMIRRORS=`cat ${MIRRORFILE} | grep -v 'version=' | grep -v ${FIRSTMIRROR}`

    # Clean up files    
    if [ -f ${MIRRORFILE}.new ]; then
        rm -f ${MIRRORFILE}.new
    fi

    echo "${MIRRORSVERSION}" > ${MIRRORFILE}.new
    for I in ${OTHERMIRRORS}; do
      echo ${I} >> ${MIRRORFILE}.new
    done;

    echo ${FIRSTMIRROR} >> ${MIRRORFILE}.new
    # Use rotated file
    cat ${MIRRORFILE}.new >${MIRRORFILE}
    echo "Mirrorfile ${MIRRORFILE} rotated"
    rm -f ${MIRRORFILE}.new

    FIRSTMIRROR=`echo ${FIRSTMIRROR} | cut -d '=' -f2`
    echo "Using mirror ${FIRSTMIRROR}"

##############################################################################################
    
    LATESTVERSION="unknown"
    FILEDESC="[DB] Mirror file                      "
    FILENAME="mirrors.dat"
    VERSIONUPDATEURL="mirrors.dat.ver"

    checkupdate

###########################
    
    LATESTVERSION="unknown"
    FILEDESC="[DB] MD5 hashes system binaries       "
    FILENAME="defaulthashes.dat"
    VERSIONUPDATEURL="defaulthashes.dat.ver"

    checkupdate

###########################

    LATESTVERSION="unknown"
    FILEDESC="[DB] Operating System information     "
    FILENAME="os.dat"
    VERSIONUPDATEURL="os.dat.ver"

    checkupdate

###########################

    LATESTVERSION="unknown"
    FILEDESC="[DB] MD5 blacklisted tools/binaries   "
    FILENAME="md5blacklist.dat"
    VERSIONUPDATEURL="md5blacklist.dat.ver"

    checkupdate

###########################

    LATESTVERSION="unknown"
    FILEDESC="[DB] Known good program versions      "
    FILENAME="programs_good.dat"
    VERSIONUPDATEURL="programs_good.dat.ver"

    checkupdate

###########################

    LATESTVERSION="unknown"
    FILEDESC="[DB] Known bad program versions       "
    FILENAME="programs_bad.dat"
    VERSIONUPDATEURL="programs_bad.dat.ver"

    checkupdate

##############################################################################################

    echo "" ; echo ""; echo ""

  else

    echo "Fatal error: ${MIRRORFILE} does not exist"
    exit 1

fi
