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
RKHINST_MODE_EX="0750"
RKHINST_MODE_RW="0640"
RKHINST_PERL_LOC="/usr/bin/perl"
USE_CVS=0

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
	echo "Usage: $0 <parameters>."
	echo ""
	echo "Valid parameters:"
	echo $ECHOOPT "--help (-h)      : Show this help."
	echo $ECHOOPT "--install        : Install according to chosen layout."
	echo $ECHOOPT "--show           : Show chosen layout."
	echo $ECHOOPT "--remove         : Deinstall according to chosen layout."
	echo $ECHOOPT "--layout <value> : Chose installation template (mandatory switch)."
	echo $ECHOOPT "                   The templates are:"
        echo $ECHOOPT "                    - default: (FHS compliant),"
        echo $ECHOOPT "                    - /usr,"
        echo $ECHOOPT "                    - /usr/local,"
	echo $ECHOOPT "                    - oldschool: previous version file locations,"
	echo $ECHOOPT "                    - custom: supply your own prefix,"
	echo $ECHOOPT "                    - RPM: for building RPM's. Requires \$RPM_BUILD_ROOT."
	echo $ECHOOPT "                    If no layout value is given the default layout is used."
	echo $ECHOOPT "--examples       : Show --layout examples."

	exit 1
}

showExamples() { # Show examples
	echo "${INSTALLER_NAME}"
	echo ""
	echo "Examples: "
	echo $ECHOOPT " Show layout, files in /usr:"
	echo $ECHOOPT " installer.sh --show --layout /usr"
	echo $ECHOOPT " Show custom layout, files in /opt:"
	echo $ECHOOPT " installer.sh --show --layout custom /opt"
	echo $ECHOOPT " Install, layout /usr/local:"
	echo $ECHOOPT " installer.sh --install --layout /usr/local"
	echo $ECHOOPT " Remove files, layout /usr/local:"
	echo $ECHOOPT " installer.sh --remove --layout /usr/local"
	echo $ECHOOPT " The installer will not remove files when RPM or custom layout is chosen."

	exit 1
}

showVersion() { echo $E "${INSTALLER_NAME} ${INSTALL_VERSION} ${INSTALLER_LICENSE}"; exit 1; }

selectTemplate() { # Take input from the "--installdir parameter"
case "$1" in
	/usr|/usr/local|default|custom_*|RPM)
		case "$1" in
			default)
				PREFIX="/usr/local"
				;;
			custom_*)
				PREFIX=`echo "${RKHINST_LAYOUT}"|sed "s|custom_||g"`
				#if [ "X${PREFIX}" = "X" ]; then
				#	echo $E "Bad prefix chosen, exiting."
				#	exit 1
				#else
					case "${PREFIX}" in
						.)
							echo "Rewriting for local install."
							;;
						.*|/.*)
							echo $E "Bad prefix chosen, exiting."
							exit 1
							;;
					esac
				echo "${PATH}" | grep -q "${PREFIX}/bin" || \
				echo $E "MAKE SURE YOU WANT PREFIX to be ${PREFIX}"
				#fi
				;;
			RPM)	PREFIX="${RPM_BUILD_ROOT}/usr/local"
				;;
			*)	PREFIX="$1"
				;;
		esac
		case "$1" in
			RPM)
				;;
			*)
				if [ ! -d "${PREFIX}" ]; then
					echo $E "Bad prefix chosen (nonexistent dirname), exiting."
					exit 1
				fi
				;;
		esac
		case "$1" in
			/usr/local|custom_*)
				SYSCONFIGDIR="${PREFIX}/etc"
				;;
			RPM)	SYSCONFIGDIR="${RPM_BUILD_ROOT}/etc"
				;;
			*)	SYSCONFIGDIR="/etc"
				;;
		esac
		case "$1" in
			custom_*)
				LIBDIR="${PREFIX}/lib"; VARDIR="${PREFIX}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			RPM)
				LIBDIR="${PREFIX}/lib"; VARDIR="${RPM_BUILD_ROOT}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			*)
				LIBDIR="${PREFIX}/lib"; VARDIR="/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
		esac
		;;
	oldschool) # The rigid way, like RKH used to be set up.
		PREFIX="/usr/local"; SYSCONFIGDIR="${PREFIX}/etc"; LIBDIR="${PREFIX}/${APPNAME}/lib"
		VARDIR="${LIBDIR}"; SHAREDIR="${LIBDIR}"; RKHINST_DOC_DIR="${PREFIX}/${APPNAME}/lib/docs"
		BINDIR="${PREFIX}/bin"
		;;
	*)	# None chosen.
		echo $E "No template chosen, exiting."; exit 1
		;;
esac

RKHINST_ETC_DIR="${SYSCONFIGDIR}"
RKHINST_BIN_DIR="${BINDIR}"
RKHINST_SCRIPT_DIR="${LIBDIR}/${APPNAME}/scripts"
RKHINST_DB_DIR="${VARDIR}/${APPNAME}/db"
RKHINST_TMP_DIR="${VARDIR}/${APPNAME}/tmp"
RKHINST_DOC_DIR="${SHAREDIR}/doc/${APPNAME}-${APPVERSION}"
RKHINST_MAN_DIR="${SHAREDIR}/man/man8"

RKHINST_ETC_FILE="${APPNAME}.conf"
RKHINST_BIN_FILES="${APPNAME}"
RKHINST_SCRIPT_FILES="check_modules.pl check_update.sh check_port.pl filehashmd5.pl filehashsha1.pl showfiles.pl"
RKHINST_DB_FILES="backdoorports.dat mirrors.dat os.dat programs_bad.dat programs_good.dat defaulthashes.dat md5blacklist.dat"
RKHINST_DOC_FILES="ACKNOWLEDGMENTS CHANGELOG FAQ LICENSE README WISHLIST"
RKHINST_MAN_FILES="development/${APPNAME}.8"

}

# Additions we need to be aware / take care of:
# any /contrib/ files which should include any RH*L/alike ones:
# Additions we need to be aware / take care of wrt RH*L/alike:
# /etc/cron.daily/01-rkhunter (different versions of cronjob)
# /etc/sysconfig/rkhunter (config for cronjob)
# /etc/logrotate.d/rkhunter

showTemplate() { # Take input from the "--installdir parameter"
	case "$1" in
		custom_.)
			# Dump *everything* in the current dir.
			echo "Rewrite on for local install."
			;;
		*)
			selectTemplate "$1"
			echo $E "PREFIX:             ${PREFIX}"
			echo $E "Application:        ${RKHINST_BIN_DIR}"
			echo $E "Configuration file: ${RKHINST_ETC_DIR}"
			echo $E "Documents:          ${RKHINST_DOC_DIR}"
			echo $E "Man page:           ${RKHINST_MAN_DIR}"
			echo $E "Scripts:            ${RKHINST_SCRIPT_DIR}"
			echo $E "Databases:          ${RKHINST_DB_DIR}"
			echo $E "Temporary files:    ${RKHINST_TMP_DIR}"
			;;
	esac
		
	exit 0
}

searchfile() {
	if [ "${PATH}" = "" ]; then
		PATH="${PATH}:/usr/bin:/usr/local/bin"
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

useCVS() { 
echo $N "Looking for cvs binary: "
SEARCH=`which cvs 2>/dev/null`
if [ "${SEARCH}" = "" ]; then
	echo $E "not found." 
else
	cvs -z3 -d:pserver:anonymous@rkhunter.cvs.sourceforge.net:/cvsroot/rkhunter co rkhunter
	case "$?" in
		0)
		echo $E "Succeeded getting Rootkit Hunter source from CVS."
		if [ -d "./files" ]; then
			echo $N "Removing stale ./files directory: "
			rm -rf "./files"; retValChk
		fi
		echo $N "Move CVS ./files directory to .: "
		mv -f rkhunter/files .; retValChk
		find ./files -type d -name CVS | while read dir; do
			echo $N "Removing CVS directory ${dir}: "
			rm -rf "${dir}"; retValChk
		done
		case "${RKHINST_LAYOUT}" in
		RPM) 
			;;
		*)
			find ./files | while read ITEM; do
				chown "${RKHINST_OWNER}" "${ITEM}" 2>/dev/null
			done
			;;
		esac
		echo $E "Refreshing source complete. Commence."
		;;
		*)
		echo $E "FAILED getting Rootkit Hunter from CVS, exiting."
		exit 1
		;;
	esac
fi
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
if [ -f "./files/${APPNAME}" ]; then
	echo $E "found. OK"
	if [ $USE_CVS -eq 1 ]; then
		# You want it, and you got it!
		# The hottest source in the land..
		useCVS
	fi
	case "${RKHINST_LAYOUT}" in
	RPM) 
		;;
	*)
		find ./files | while read ITEM; do
			chown "${RKHINST_OWNER}" "${ITEM}" 2>/dev/null
		done
		;;
	esac
else
	echo $E "failed. Installer files not in "${PWD}/files". Exiting."
	exit 1
fi

echo $E " available file retrieval tools: "
echo $N "  wget: "
SEARCH=`which wget 2>/dev/null`
if [ "${SEARCH}" = "" ]; then
	echo $E "not found." 
	echo $N "  fetch: "
	SEARCH=`which fetch 2>/dev/null`
	if [ "${SEARCH}" = "" ]; then
		echo $E "not found."
		echo $N "  curl: "
		SEARCH=`which curl 2>/dev/null`
		if [ "${SEARCH}" = "" ]; then
			echo $E "NOT found: please install one of wget, fetch or curl."
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
	echo "  and restart the installer."
else
	echo $E "found. OK"
fi

RKHINST_DIRS="$RKHINST_DOC_DIR $RKHINST_MAN_DIR $RKHINST_ETC_DIR $RKHINST_BIN_DIR"
RKHINST_DIRS_EXCEP="$RKHINST_SCRIPT_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR"

echo "Starting installation/update"
echo ""

case "${RKHINST_LAYOUT}" in
		RPM)
			;;
		*) 
# Check PREFIX
echo $N "Checking PREFIX $PREFIX: "
if [ -e "${PREFIX}" ]; then
	echo $N "exists, and is "
	if [ ! -w "${PREFIX}" ]; then
		echo $E "NOT writable: exiting."
		exit 1
	else
		echo $E "writable. OK"
		# That's enough for a "." install.
		case "${PREFIX}" in
			.)	
				chown -R ${RKHINST_OWNER} ./files 
				find ./files -type d -name CVS | while read DIR; do
					rm -rf "${DIR}"
				done
				find ./files -type f | while read ITEM; do
					case "${ITEM}" in
						*.sh|*.pl|rkhunter)
							chmod "${RKHINST_MODE_EX}" "${ITEM}"
							;;
						rkhunter.conf|*)
							chmod "${RKHINST_MODE_RW}" "${ITEM}"
							;;
					esac
				done
				cd ./files
				echo "TMPDIR=$PREFIX" >> rkhunter.conf 
				echo "DBDIR=$PREFIX" >> rkhunter.conf 
				echo "SCRIPTDIR=$PREFIX" >> rkhunter.conf 
				echo "INSTALLDIR=$PREFIX" >> rkhunter.conf
				sed -e "s|-f /etc/rkhunter.conf|-f $PREFIX/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$PREFIX|g" rkhunter > rkhunter.
				mv -f rkhunter. rkhunter
				echo $E "Finished install in PREFIX \"${PREFIX}\" (${PWD})."
				exit 0
			;;
		esac
	fi
else
	echo "does NOT exist, exiting."
	exit 1
fi
;;
esac # end Check PREFIX

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
		mkdir -p "${DIR}"; retValChk
	fi
	case "${DIR}" in
		*/${APPNAME}|*/${APPNAME}/*|*/${APPNAME}-${APPVERSION}) 
			chmod "${RKHINST_MODE_EX}" "${DIR}"
			;;
	esac
done

# Helper scripts, database and man page
for FILE in ${RKHINST_SCRIPT_FILES} ${RKHINST_DB_FILES} ${RKHINST_MAN_FILES}; do
	case "${FILE}" in
		*.pl|*.sh)	echo $N " Installing ${FILE}: "
				cp -f ./files/"${FILE}" "${RKHINST_SCRIPT_DIR}"; retValChk
				chmod "${RKHINST_MODE_EX}" "${RKHINST_SCRIPT_DIR}/${FILE}"
				;;
		*.dat)		echo $N " Installing ${FILE}: "
				cp -f ./files/"${FILE}" "${RKHINST_DB_DIR}"; retValChk
				chmod "${RKHINST_MODE_RW}" "${RKHINST_DB_DIR}/${FILE}"
				;;
		*.8)		echo $N " Installing ${FILE}: "
				cp -f ./files/"${FILE}" "${RKHINST_MAN_DIR}/`basename ${FILE}`"; retValChk
				chmod "${RKHINST_MODE_RW}" "${RKHINST_MAN_DIR}/`basename ${FILE}`"
				;;
		esac
done

# Application documents
for FILE in ${RKHINST_DOC_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}"; retValChk
done

# Application
for FILE in ${RKHINST_BIN_FILES}; do
	echo $N " Installing ${FILE}: " 
	sed -e "s|-f /etc/rkhunter.conf|-f $PREFIX/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$PREFIX|g" ./files/"${FILE}" > "${RKHINST_BIN_DIR}/${FILE}"; retValChk
	chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
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
		chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${NEWFILE}"
		
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
		chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${FILE}"

		echo "" >> "${RKHINST_ETC_DIR}/${FILE}"
		if [ -n "${RPM_BUILD_ROOT}" ]; then
			echo "INSTALLDIR=${PREFIX}" | sed "s|${RPM_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
		else
			echo "INSTALLDIR=${PREFIX}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
		fi
	fi
done
} # End doInstall


doRemove()  {
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

RKHINST_DIRS="$RKHINST_ETC_DIR $RKHINST_BIN_DIR $RKHINST_SCRIPT_DIR $RKHINST_DOC_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR"
RKHINST_DIRS_POST="$VARDIR $SHAREDIR $PREFIX"

echo "Starting deinstallation"
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
	#exit 1
fi

echo $ECHOOPT "Removing installation files:"

# Man page
for FILE in ${RKHINST_MAN_FILES}; do
	if [ -f "${RKHINST_MAN_DIR}/`basename ${FILE}`" ]; then
		echo $N " Removing ${FILE}: "
		rm -f "${RKHINST_MAN_DIR}/`basename ${FILE}`"; retValChk
	fi
done

# Application
for FILE in ${RKHINST_BIN_FILES}; do
	if [ -f "${RKHINST_BIN_DIR}/${FILE}" ]; then
		echo $N " Removing ${RKHINST_BIN_DIR}/${FILE}: "
		rm -f "${RKHINST_BIN_DIR}/${FILE}"; retValChk
	fi
done

# Configuration file
for FILE in ${RKHINST_ETC_FILE}; do
	if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
		echo $N " Removing ${RKHINST_ETC_DIR}/${FILE}: "
		rm -f "${RKHINST_ETC_DIR}/${FILE}"; retValChk
	fi
	echo $E " Please remove any ${RKHINST_ETC_DIR}/${FILE}.* manually."
done

# Helper scripts: remove dir
# Application documents: remove dir
# Databases: remove dir

echo $ECHOOPT "Removing installation directories:"

for DIR in ${RKHINST_DIRS}; do
	case "${DIR}" in 
		*/${APPNAME}|*/${APPNAME}-${APPVERSION}) 
			if [ -d "${DIR}" ]; then
				echo $N " Removing ${DIR}: "
				rm -rf "${DIR}"; retValChk
			fi
			;;
		*/${APPNAME}/*)
			DIR=`dirname "${DIR}"`
			if [ -d "${DIR}" ]; then
				echo $N " Removing ${DIR}: "
				rm -rf "${DIR}"; retValChk
			fi
			;;
	esac
done

# Could use patch for removing custom $VARDIR $SHAREDIR $PREFIX here.

} # end doRemove

if [ $# -eq 0 ]; then
	showHelp
fi

while [ $# -ge 1 ]; do
	case $1 in
	-h | --help | --usage)
		showHelp
		;;
	-v | --version)
		showVersion
		;;
	--show|--remove|--install)
		action=`echo "$1"|sed "s/-//g"`
		;;
	--layout)
		shift 1
		case "$1" in
			custom)
				shift 1
				if [ -n "$1" ]; then
					RKHINST_LAYOUT="custom_$1"
				else
					echo $E "No custom layout given, exiting."
					exit 1
				fi
				;;
			default|oldschool|/usr|/usr/local|RPM)
				RKHINST_LAYOUT="$1"
				;;
			*)
				RKHINST_LAYOUT="default"
				;;
		esac
		case "$action" in
			show)	showTemplate $RKHINST_LAYOUT
				;;
			remove)	selectTemplate $RKHINST_LAYOUT
				doRemove
				;;
			install) selectTemplate $RKHINST_LAYOUT
				 doInstall
				 ;;
			*)	echo $E "No option given, exiting."
				exit 1
				;;
		esac
		;;
	--examples) showExamples
		;;
	--mentalfloss) # Since you read the source here's something for you:
		USE_CVS=1
		;;
	*)
		echo $E "Wrong option given, exiting."
		showHelp
		;;
	esac
	shift
done

exit 0
