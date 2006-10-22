#!/bin/sh

#################################################################################
#
#  Rootkit Hunter installer
# --------------------------
#
# Copyright Michael Boelen ( michael AT rootkit DOT nl )
# See LICENSE file for use of this software
#
#################################################################################

INSTALLER_NAME="Rootkit Hunter installer"
INSTALLER_VERSION="1.2.6"
INSTALLER_COPYRIGHT="Copyright 2003-2005, Michael Boelen"
INSTALLER_LICENSE="

Under active development by the Rootkit Hunter project team. For reporting
bugs, updates, patches, comments and questions see: rkhunter.sourceforge.net

Rootkit Hunter comes with ABSOLUTELY NO WARRANTY. This is free
software, and you are welcome to redistribute it under the terms
of the GNU General Public License. See LICENSE for details.
"

APPNAME="rkhunter"
APPVERSION="1.2.9"
RKHINST_OWNER="0:0"
RKHINST_BINMODE="0750"
RKHINST_FILEMODE="0640"
RKHINST_PERL_LOC="/usr/bin/perl"

# rootmgu: modified for solaris
case `uname` in
AIX|OpenBSD|SunOS)
	# rootmgu:
	# What is the default shell
	if print >/dev/null 2>&1; then
		alias echo='print'
		N="-n"
		E=""
		ECHOOPT="--"
	else
		E="-e"
		ECHOOPT=""
	fi
	;;
*)
	E="-e"
	N="-n"
	ECHOOPT=""
	;;
esac

# rootmgu: some lines added for solaris...
case `uname` in
SunOS)
	# We need /usr/xpg4/bin before other commands on solaris 
	PATH="/usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" 
	#export PATH
	;;
*)
	;;
esac

showHelp() { # Show help / version
	echo "${INSTALLER_NAME}"
	echo "${INSTALL_LICENSE}"
	echo "Usage: $0 <parameters>."
	echo ""
	echo "Valid parameters:"
	echo $ECHOOPT "--help (-h)          : Show this help."
	echo $ECHOOPT "--installdir <value> : Installation directory. Mandatory switch."
	echo $ECHOOPT "                       Accepted values are:"
	echo $ECHOOPT "                       - (none: use default prefix),"
        echo $ECHOOPT "                       - default (somewhat FHS compliant tree),"
        echo $ECHOOPT "                       - /usr,"
        echo $ECHOOPT "                       - /usr/local,"
	echo $ECHOOPT "                       - oldschool (previous installer version prefixes),"
	echo $ECHOOPT "                       - custom (supply custom prefix),"
	echo $ECHOOPT "                       use --installdir <value> show to show a layout."
	exit 1
}

showVersion() { echo "${INSTALLER_NAME} ${INSTALL_VERSION}"; exit 1; }

selectTemplate() { # Take input from the "--installdir parameter"
case "$1" in
	oldschool) # The way RKH used to be set up.
		PREFIX="/usr/local"
		LIBDIR="$PREFIX/$APPNAME/lib"
		VARDIR="$LIBDIR"
		SHAREDIR="$LIBDIR"
		# Override:
		RKHINST_DOC_DIR="$PREFIX/$APPNAME/lib/docs"
		SYSCONFIGDIR="$PREFIX/etc"
		BINDIR="$PREFIX/bin"
		;;
	custom_*) # Say you want to use something else
		PREFIX=`echo "$INSTALLTEMPLATE"|sed -e "s/custom_//g"`
		LIBDIR="$PREFIX/lib"
		VARDIR="$PREFIX/var"
		SHAREDIR="$PREFIX/share"
		SYSCONFIGDIR="$PREFIX/etc"
		BINDIR="$PREFIX/bin"
		;;
	/usr) # 
		PREFIX="/usr"
		LIBDIR="$PREFIX/lib"
		VARDIR="/var"
		SHAREDIR="$PREFIX/share"
		SYSCONFIGDIR="/etc"
		BINDIR="$PREFIX/bin"
		;;
	/usr/local) # 
		PREFIX="/usr/local"
		LIBDIR="$PREFIX/lib"
		VARDIR="/var"
		SHAREDIR="$PREFIX/share"
		SYSCONFIGDIR="$PREFIX/etc"
		BINDIR="$PREFIX/bin"
		;;
	default) # The default template.
		PREFIX="/usr/local"
		LIBDIR="$PREFIX/lib"
		VARDIR="/var"
		SHAREDIR="$PREFIX/share"
		SYSCONFIGDIR="/etc"
		BINDIR="$PREFIX/bin"
		;;
	*)	# None chosen.
		echo "No template chosen."
		;;
esac
RKHINST_SCRIPT_DIR="$LIBDIR/$APPNAME/scripts"
RKHINST_SCRIPT_FILES="check_modules.pl check_update.sh check_port.pl filehashmd5.pl filehashsha1.pl showfiles.pl"
RKHINST_DB_DIR="$VARDIR/$APPNAME/db"
RKHINST_DB_FILES="backdoorports.dat mirrors.dat os.dat programs_bad.dat programs_good.dat defaulthashes.dat md5blacklist.dat"
RKHINST_DOC_DIR="$SHAREDIR/doc/$APPNAME-$APPVERSION"
RKHINST_DOC_FILES="ACKNOWLEDGMENTS CHANGELOG FAQ LICENSE README WISHLIST"
RKHINST_MAN_DIR="$SHAREDIR/man/man8"
RKHINST_MAN_FILES="development/$APPNAME.8"
RKHINST_ETC_DIR="$SYSCONFIGDIR"
RKHINST_ETC_FILE="$APPNAME.conf"
RKHINST_BIN_DIR="$BINDIR"
RKHINST_BIN_FILES="$APPNAME"
RKHINST_TMP_DIR="$VARDIR/$APPNAME/tmp"
}

# Additions we need to be aware / take care of:
# any /contrib/ files which should include any RH*L/alike ones:
# 
# Additions we need to be aware / take care of wrt RH*L/alike:
# /etc/cron.daily/01-rkhunter (different versions of cronjob)
# /etc/sysconfig/rkhunter (config for cronjob)
# /etc/logrotate.d/rkhunter
#

showTemplate() { # Take input from the "--installdir parameter"
	case "$1" in
		custom_.)
			# Dump *everything* in the current dir.
			echo "Rewrite on for local install."
			;;
		*)
			case "$1" in 
				custom_*)
					PREFIX=`echo "$INSTALLTEMPLATE"|sed -e "s/custom_//g"`
					echo; echo ">>>>>>>>>>>>>>>>>>>> MAKE SURE YOU WANT PREFIX=$PREFIX"; echo
				;;
			esac
			selectTemplate "$1"
			echo "PREFIX:             $PREFIX"
			echo "Application:        $RKHINST_BIN_DIR"
			echo "Configuration file: $RKHINST_ETC_DIR"
			echo "Documents:          $RKHINST_DOC_DIR"
			echo "Man page:           $RKHINST_MAN_DIR"
			echo "Scripts:            $RKHINST_SCRIPT_DIR"
			echo "Databases:          $RKHINST_DB_DIR"
			echo "Temporary files in: $RKHINST_TMP_DIR"
			;;
	esac
		
	exit 0
}

searchfile() {
	if [ "${PATH}" = "" ]; then
		PATH="$PATH:/usr/bin:/usr/local/bin"
	fi

	#    PATH=`echo ${PATH} | tr ':' ' '`
}

retValChk() { 
case "$?" in
	0) echo $E "OK."
	   ;;
	1) echo $E "FAILED. Exiting."
	   exit 1
	   ;;
	*) echo $E "Exited with unhandled exit value $?. Exiting."
	   exit 1
	   ;;
esac
}
	
#################################################################################
#
# Start installation
#
#################################################################################

doInstall()  {
# Clean active window
clear

# Preflight checks
echo $E "Checking system for: "

echo $N " ${INSTALLER_NAME} files: "
if [ -f ./files/rkhunter ]; then
	echo $E "found. OK"
else
	echo $E "failed. Installer files not in $PWD/files. Exiting."
	exit 1
fi

echo $E " available file retrieval tools: "
echo $N "  Wget: "
SEARCH=`which wget 2>/dev/null`
if [ "${SEARCH}" = "" ]; then
	echo $E "not found." 
	echo $N "  Fetch: "
	SEARCH=`which fetch 2>/dev/null`
	if [ "${SEARCH}" = "" ]; then
		echo $E "not found."
		echo $N "  Curl: "
		SEARCH=`which curl 2>/dev/null`
		if [ "${SEARCH}" = "" ]; then
			echo $E "NOT found."
		else
			echo $E "found. OK"
		fi
	else
		echo $E "found. OK"
	fi
else
	echo $E "found. OK"
fi

echo $E " expected default tool locations: "
echo $N "  perl: "
if [ ! -f "${RKHINST_PERL_LOC}" ]; then
	echo $E "FAILED."
	echo "  Perl cannot be found in the default location,"
	echo "  please create a symbolic link to your Perl binary:"
	echo "  ie. ln -s <path_to>/perl "${RKHINST_PERL_LOC}""
else
	echo $E "found. OK"
fi

RKHINST_DIRS="$RKHINST_DOC_DIR $RKHINST_MAN_DIR $RKHINST_ETC_DIR $RKHINST_BIN_DIR"
RKHINST_DIRS_EXCEP="$RKHINST_SCRIPT_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR"

# echo "${INSTALLER_NAME} ${INSTALLER_VERSION} (${INSTALLER_COPYRIGHT})"
# echo "${INSTALLER_LICENSE}"
# echo $ECHOOPT "---------------"
echo "Starting installation/update"
echo ""

# Check PREFIX
echo $N "Checking PREFIX $PREFIX: "
if [ -e "${PREFIX}" ]; then
	echo $N "exists, and is "
	if [ ! -w "${PREFIX}" ]; then
		echo $E "NOT writable: exiting."
		exit 1
	else
		echo $E "writable. OK"
	fi
else
	echo "does NOT exist, exiting."
	exit 1
fi

echo $ECHOOPT "Checking installation directories:"

for DIR in ${RKHINST_DIRS}; do
	echo $N $ECHOOPT " Directory ${DIR}: "
	if [ -d "${DIR}" ]; then
		echo $N "exists, and is "
		if [ ! -w "${PREFIX}" ]; then
			echo $E "NOT writable: exiting."
			exit 1
		else
			echo $E "writable. OK"
		fi
	else
		# Create directory
		echo $N "creating: "
		mkdir -p ${DIR}; retValChk
	fi
done

for DIR in ${RKHINST_DIRS_EXCEP}; do
	echo $N $ECHOOPT " Directory ${DIR}: "
	if [ -d "${DIR}" ]; then
		echo $N "exists, and is "
		if [ ! -w "${PREFIX}" ]; then
			echo $E "NOT writable: exiting."
			exit 1
		else
			echo $E "writable. OK"
		fi
	else
		echo $N "creating: "
		# Create directory
		mkdir -p "${DIR}"; retValChk
	fi
	echo $N " Applying access control (owner $RKHINST_OWNER): "
	chown "${RKHINST_OWNER}" "${DIR}" ; retValChk
	echo $N " Applying access control (mode $RKHINST_BINMODE): "
	chmod "${RKHINST_BINMODE}" ${DIR} ; retValChk
done

# Helper scripts
for FILE in ${RKHINST_SCRIPT_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_SCRIPT_DIR}"; retValChk
done

# Application documents
for FILE in ${RKHINST_DOC_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}"; retValChk
done

# Man page
for FILE in ${RKHINST_MAN_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_MAN_DIR}"; retValChk
done

# Databases
for FILE in ${RKHINST_DB_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_DB_DIR}"; retValChk
	echo $N " Applying access control (mode ${RKHINST_FILEMODE}): "
	chmod "${RKHINST_FILEMODE}" "${RKHINST_DB_DIR}/${FILE}" ; retValChk
done

# Application
for FILE in ${RKHINST_BIN_FILES}; do
	echo $N " Installing ${FILE}: " 
	sed "s|CONFIGFILE=\"/usr/local|CONFIGFILE=\"$PREFIX|g" ./files/"${FILE}" > "${RKHINST_BIN_DIR}/${FILE}"; retValChk
	echo $N " Applying access control (mode ${RKHINST_BINMODE}): "
	chmod "${RKHINST_BINMODE}" "${RKHINST_BIN_DIR}/${FILE}" ; retValChk
done

# Configuration file
for FILE in ${RKHINST_ETC_FILE}; do
# We need people to make local changes themselves, so give opportunity and alert.
# Use Perl to get value, shell may not support "RANDOM".
RANDVAL=`perl -e 'printf "%d\n", time;'`
	if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
		NEWFILE="${FILE}.${RANDVAL}"
		echo $N " Installing ${FILE} in no-clobber mode: "
		cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}/${NEWFILE}"; retValChk
		
		echo "" >> "${RKHINST_ETC_DIR}/${NEWFILE}"
		echo "INSTALLDIR=${PREFIX}" >> "${RKHINST_ETC_DIR}/${NEWFILE}"
		echo "DBDIR=${RKHINST_DB_DIR}" >> "${RKHINST_ETC_DIR}/${NEWFILE}"
		echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >> "${RKHINST_ETC_DIR}/${NEWFILE}"
		echo "TMPDIR=${RKHINST_TMP_DIR}" >> "${RKHINST_ETC_DIR}/${NEWFILE}"
	
		echo " >>> "
		echo " >>> PLEASE NOTE: inspect for update changes in "${RKHINST_ETC_DIR}/${NEWFILE}""
		echo " >>> and apply to "${RKHINST_ETC_DIR}/${FILE}" before running Rootkit Hunter."
		echo " >>> "
	else
		echo $N " Installing ${FILE}: "
		cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}"; retValChk

		echo "" >> "${RKHINST_ETC_DIR}/${FILE}"
		echo "INSTALLDIR=${PREFIX}" >> "${RKHINST_ETC_DIR}/${FILE}"
		echo "DBDIR=${RKHINST_DB_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
		echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
		echo "TMPDIR=${RKHINST_TMP_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"

	fi
done

}


while [ $# -ge 1 ]; do
	case $1 in
	-h | --help | --usage)
		showHelp
		;;
	-v | --version)
		showVersion
		;;
	--installdir)
		shift 1
		case "$1" in
			custom)
				shift 1
				if [ -e "$1" ]; then
					INSTALLTEMPLATE="custom_$1"
				else
					echo "Wrong parameter"
					exit 1
				fi
				;;
			default|oldschool|/usr|/usr/local)
				INSTALLTEMPLATE="$1"
				;;
			*)
				INSTALLTEMPLATE="default"
				;;
		esac
		selectTemplate $INSTALLTEMPLATE
		shift 1
		if [ "$1" = "show" -o "$show" = "yes" ]; then
			showTemplate $INSTALLTEMPLATE
		fi
		doInstall
		;;
	--show)
		show=yes
		;;
	*)
		echo "Wrong parameter"
		exit 1
		;;
	esac
	shift
done

exit 0
