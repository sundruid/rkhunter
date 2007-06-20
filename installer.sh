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
INSTALLER_COPYRIGHT="Copyright 2003-2007, Michael Boelen"
INSTALLER_LICENSE="

Under active development by the Rootkit Hunter project team. For reporting
bugs, updates, patches, comments and questions see: rkhunter.sourceforge.net

Rootkit Hunter comes with ABSOLUTELY NO WARRANTY. This is free
software, and you are welcome to redistribute it under the terms
of the GNU General Public License. See LICENSE for details.
"

APPNAME="rkhunter"
APPVERSION="1.3.0"
RKHINST_OWNER="0:0"
RKHINST_MODE_EX="0750"
RKHINST_MODE_RW="0640"
RKHINST_LAYOUT=""
USE_CVS=0
STRIPROOT=""
N="-n"

umask 027

OPERATING_SYSTEM=`uname 2>/dev/null`

case "${OPERATING_SYSTEM}" in
AIX|OpenBSD|SunOS)
	if [ -z "$RANDOM" ]; then
		if [ -n "`which bash 2>/dev/null | grep '^/'`" ]; then
			exec bash $0 $*
		else
			exec ksh $0 $*
		fi

		exit 0
	fi
	;;
esac

# rootmgu: modified for solaris
case "${OPERATING_SYSTEM}" in
AIX|OpenBSD|SunOS)
	# If running ksh, then use print command.
	if print >/dev/null 2>&1; then
		alias echo='print'
	fi
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
	echo "Usage: $0 <parameters>"
	echo ""
	echo "Ordered valid parameters:"
	echo "--help (-h)      : Show this help."
	echo "--examples       : Show layout examples."
	echo "--layout <value> : Choose installation template (mandatory switch)."
	echo "                   The templates are:"
        echo "                    - default: (FHS compliant),"
        echo "                    - /usr,"
        echo "                    - /usr/local,"
	echo "                    - oldschool: previous version file locations,"
	echo "                    - custom: supply your own prefix,"
	echo "                    - RPM: for building RPM's. Requires \$RPM_BUILD_ROOT."
	echo "--striproot      : Strip path from custom layout (for package maintainers)."
	echo "--install        : Install according to chosen layout."
	echo "--show           : Show chosen layout."
	echo "--remove         : Uninstall according to chosen layout."

	exit 1
}

showExamples() { # Show examples
	echo "${INSTALLER_NAME}"
	echo ""
	echo "Examples: "
	echo "1. Show layout, files in /usr:"
	echo "     installer.sh --layout /usr --show"
	echo ""
	echo "2. Install, layout /usr/local:"
	echo "     installer.sh --layout /usr/local --install"
	echo ""
	echo "3. Install in temporary directory /tmp/rkhunter/usr/local,"
	echo " with files in /usr/local (for package maintainers):"
	echo "      mkdir -p /tmp/rkhunter/usr/local"
	echo "     installer.sh --layout custom /tmp/rkhunter/usr/local \\"
	echo "     --striproot /tmp/rkhunter --install"
	echo ""
	echo "4. Remove files, layout /usr/local:"
	echo "     installer.sh --layout /usr/local --remove"
	echo ""
	echo "Note: The installer will not remove files when a custom layout is chosen."

	exit 1
}

showVersion() { echo "${INSTALLER_NAME} ${INSTALL_VERSION} ${INSTALLER_LICENSE}"; exit 1; }

selectTemplate() { # Take input from the "--installdir parameter"
case "$1" in
	/usr|/usr/local|default|custom_*|RPM)
		case "$1" in
			default)
				PREFIX="/usr/local"
				;;
			custom_*)
				PREFIX=`echo "${RKHINST_LAYOUT}"|sed "s|custom_||g"`
				case "${PREFIX}" in
					.)
						if [ "$action" = "install" ]; then
							echo "Standalone installation into ${PWD}/files"
						fi
						;;
					.*|/.*)
						echo "Bad prefix chosen, exiting."
						exit 1
						;;
					*)
						if [ "$action" = "install" ]; then
							rkhtmpvar=`echo "${PATH}" | grep "${PREFIX}/bin"`
							if [ -z "${rkhtmpvar}" ]; then
								echo
								echo "Note: Directory ${PREFIX}/bin is not in your PATH"
								echo
							fi
						fi
						;;
				esac
				;;
			RPM)	if [ -n "${RPM_BUILD_ROOT}" ]; then
					PREFIX="${RPM_BUILD_ROOT}/usr/local"
				else
					echo "RPM prefix chosen but \$RPM_BUILD_ROOT variable not found, exiting."
					exit 1
				fi
				;;
			*)	PREFIX="$1"
				;;
		esac
		case "$1" in
			RPM)
				;;
			*)
				if [ "$action" = "install" ]; then
					if [ ! -d "${PREFIX}" ]; then
						echo "Bad prefix chosen (nonexistent dirname), exiting."
						echo "\"mkdir -p ${PREFIX}\" first?"
						exit 1
					fi
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
			RPM)	if [ `uname -m` = x86_64 -a -d "${PREFIX}/lib64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
				VARDIR="${RPM_BUILD_ROOT}/var"; SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
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
		echo "No template chosen, exiting."; exit 1
		;;
esac

RKHINST_ETC_DIR="${SYSCONFIGDIR}"
RKHINST_BIN_DIR="${BINDIR}"
RKHINST_SCRIPT_DIR="${LIBDIR}/${APPNAME}/scripts"

if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
	RKHINST_DB_DIR="${VARDIR}/${APPNAME}/db"
	RKHINST_TMP_DIR="${VARDIR}/${APPNAME}/tmp"
	RKHINST_DOC_DIR="${SHAREDIR}/${APPNAME}/docs"
else
	RKHINST_DB_DIR="${VARDIR}/lib/${APPNAME}/db"
	RKHINST_TMP_DIR="${VARDIR}/lib/${APPNAME}/tmp"
	RKHINST_DOC_DIR="${SHAREDIR}/doc/${APPNAME}-${APPVERSION}"
fi

RKHINST_MAN_DIR="${SHAREDIR}/man/man8"
RKHINST_LANG_DIR="${RKHINST_DB_DIR}/i18n"

RKHINST_ETC_FILE="${APPNAME}.conf"
RKHINST_BIN_FILES="${APPNAME}"
RKHINST_SCRIPT_FILES="check_modules.pl check_update.sh check_port.pl filehashmd5.pl filehashsha1.pl showfiles.pl stat.pl readlink.sh"
RKHINST_DB_FILES="backdoorports.dat mirrors.dat os.dat programs_bad.dat programs_good.dat defaulthashes.dat md5blacklist.dat suspscan.dat"
RKHINST_DOC_FILES="ACKNOWLEDGMENTS CHANGELOG FAQ LICENSE README WISHLIST"
RKHINST_MAN_FILES="${APPNAME}.8"

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
			echo "Standalone installation into ${PWD}/files"
			;;
		*)
			selectTemplate "$1"
			echo "PREFIX:             ${PREFIX}"
			echo "Application:        ${RKHINST_BIN_DIR}"
			echo "Configuration file: ${RKHINST_ETC_DIR}"
			echo "Documents:          ${RKHINST_DOC_DIR}"
			echo "Man page:           ${RKHINST_MAN_DIR}"
			echo "Scripts:            ${RKHINST_SCRIPT_DIR}"
			echo "Databases:          ${RKHINST_DB_DIR}"
			echo "Temporary files:    ${RKHINST_TMP_DIR}"
			if [ -n "${STRIPROOT}" ]; then
				echo; echo "Got STRIPROOT=\"${STRIPROOT}\""
			fi
			;;
	esac
		
	exit 0
}

retValChk() { 
case "$?" in
	0) echo "OK."
	   ;;
	1) echo "FAILED. Exiting."
	   exit 1
	   ;;
	*) echo "Exited with unhandled exit value $?. Exiting."
	   exit 1
	   ;;
esac
}

useCVS() { 
echo $N "Looking for cvs binary: "
SEARCH=`which cvs 2>/dev/null`
if [ "${SEARCH}" = "" ]; then
	echo "not found." 
else
	cvs -z3 -d:pserver:anonymous@rkhunter.cvs.sourceforge.net:/cvsroot/rkhunter co rkhunter
	case "$?" in
		0)
		echo "Succeeded getting Rootkit Hunter source from CVS."
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
		echo "Refreshing source complete. Commence."
		;;
		*)
		echo "FAILED getting Rootkit Hunter from CVS, exiting."
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
# Preflight checks
echo "Checking system for: "

echo $N " ${INSTALLER_NAME} files: "
if [ -f "./files/${APPNAME}" ]; then
	echo "found. OK"
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
	echo "failed. Installer files not in "${PWD}/files". Exiting."
	exit 1
fi

echo " Available file retrieval tools: "
echo $N "      wget: "
SEARCH=`which wget 2>/dev/null`
if [ "${SEARCH}" = "" ]; then
	echo "not found." 

	echo $N "     links: "
	SEARCH=`which links 2>/dev/null`
	if [ "${SEARCH}" = "" ]; then
		echo "not found."

		echo $N "    elinks: "
		SEARCH=`which elinks 2>/dev/null`
		if [ "${SEARCH}" = "" ]; then
			echo "not found."

			echo $N "      lynx: "
			SEARCH=`which lynx 2>/dev/null`
			if [ "${SEARCH}" = "" ]; then
				echo "not found."

				echo $N "      curl: "
				SEARCH=`which curl 2>/dev/null`
				if [ "${SEARCH}" = "" ]; then
					echo "not found."

					echo $N "       GET: "
					SEARCH=`which GET 2>/dev/null`
					if [ "${SEARCH}" = "" ]; then
						echo "not found."

						echo $N "      bget: "
						SEARCH=`which bget 2>/dev/null`
						if [ "${SEARCH}" = "" ]; then
							echo "NOT found."
						fi
					fi
				fi
			fi
		fi
	fi
fi

if [ -n "${SEARCH}" ]; then
	echo "found. OK"
else
	echo " Please install one of wget, links, elinks, lynx, curl, GET or"
	echo "   bget (from www.cpan.org/authors/id/E/EL/ELIJAH/bget)"
fi

# Perl will be found in Rkhunter itself.

RKHINST_DIRS="$RKHINST_DOC_DIR $RKHINST_MAN_DIR $RKHINST_ETC_DIR $RKHINST_BIN_DIR"
RKHINST_DIRS_EXCEP="$RKHINST_SCRIPT_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR $RKHINST_LANG_DIR"

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
		echo "NOT writable: exiting."
		exit 1
	else
		echo "writable. OK"
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
				PREFIX="${PWD}"
				echo "LOGFILE=${PREFIX}/rkhunter.log" >> rkhunter.conf 
				echo "TMPDIR=$PREFIX" >> rkhunter.conf 
				echo "DBDIR=$PREFIX" >> rkhunter.conf 
				echo "SCRIPTDIR=$PREFIX" >> rkhunter.conf 
				echo "INSTALLDIR=$PREFIX" >> rkhunter.conf
				sed -e "s|-f /etc/rkhunter.conf|-f $PREFIX/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$PREFIX|g" rkhunter > rkhunter.
				mv -f rkhunter. rkhunter
				chmod "${RKHINST_MODE_EX}" rkhunter
				echo "Finished install in \"${PREFIX}\"."
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

echo "Checking installation directories:"

if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
	RKHDIR_LIST="${RKHINST_DIRS}"
else
	RKHDIR_LIST="${RKHINST_DIRS} ${LIBDIR} ${VARDIR}/lib"
fi

umask 022
for DIR in ${RKHDIR_LIST}; do
	echo $N " Directory ${DIR}: "
	if [ -d "${DIR}" ]; then
		echo $N "exists, and is "
		if [ ! -w "${PREFIX}" ]; then
			echo "NOT writable: exiting."
			exit 1
		else
			echo "writable. OK"
		fi
	else
		echo $N "creating: "
		mkdir -p ${DIR}; retValChk
	fi
done
umask 027

for DIR in ${RKHINST_DIRS_EXCEP}; do
	echo $N " Directory ${DIR}: "
	if [ -d "${DIR}" ]; then
		echo $N "exists, and is "
		if [ ! -w "${PREFIX}" ]; then
			echo "NOT writable: exiting."
			exit 1
		else
			echo "writable. OK"
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
				cp -f ./files/"${FILE}" "${RKHINST_MAN_DIR}"; retValChk
				chmod "${RKHINST_MODE_RW}" "${RKHINST_MAN_DIR}/${FILE}"
				;;
		esac
done

# Application documents
for FILE in ${RKHINST_DOC_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}"; retValChk
done

# Language support files
echo $N " Installing language support files: "
find ./files/i18n -type f | while read FILE; do
	cp "${FILE}" "${RKHINST_LANG_DIR}"
done; retValChk

# Application
for FILE in ${RKHINST_BIN_FILES}; do
	echo $N " Installing ${FILE}: " 
	case "${RKHINST_LAYOUT}" in
		RPM)	
			cp -f ./files/"${FILE}" "${RKHINST_BIN_DIR}/${FILE}"; retValChk
			;;
		*)	
			sed -e "s|-f /etc/rkhunter.conf|-f $RKHINST_ETC_DIR/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$RKHINST_ETC_DIR|g" ./files/"${FILE}" > "${RKHINST_BIN_DIR}/${FILE}"; retValChk
			;;
	esac
	chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
done

# Configuration file
for FILE in ${RKHINST_ETC_FILE}; do
	# We need people to make local changes themselves, so
	# give opportunity and alert. Don't use Perl to get value.
	if [ -n "$RANDOM" ]; then
		RANDVAL=$RANDOM
	else
		RANDVAL=`date +%Y%m%d%H%M%S 2>/dev/null`
	fi

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

# Strip root from fake root install.
if [ -n "${STRIPROOT}" ]; then
	find "${PREFIX}" -type f | while read f; do 
		grep "${PREFIX}" "${f}" >/dev/null 2>&1 && { echo $N " Striproot ${f}: "; sed -i "s|${STRIPROOT}||g" "${f}"; retValChk; }
	done
fi

echo "Installation finished."

} # End doInstall


doRemove()  {
RKHINST_DIRS="$RKHINST_ETC_DIR $RKHINST_BIN_DIR $RKHINST_SCRIPT_DIR $RKHINST_DOC_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR $RKHINST_LANG_DIR"
RKHINST_DIRS_POST="$VARDIR $SHAREDIR $PREFIX"

echo "Starting uninstallation"
echo ""

# Check PREFIX
echo $N "Checking PREFIX $PREFIX: "
if [ -e "${PREFIX}" ]; then
	echo $N "exists, and is "
	if [ ! -w "${PREFIX}" ]; then
		echo "NOT writable: exiting."
		exit 1
	else
		echo "writable. OK"
	fi
else
	echo "does NOT exist, exiting."
	#exit 1
fi

# Standalone removal involves just deleting the 'files' subdirectory.
if [ "$PREFIX" = "." ]; then
	rm -rf ./files 2>/dev/null
	echo "Uninstallation complete."
	return
fi

echo "Removing installation files:"

# Man page
for FILE in ${RKHINST_MAN_FILES}; do
	if [ -f "${RKHINST_MAN_DIR}/${FILE}" ]; then
		echo $N " Removing ${FILE}: "
		rm -f "${RKHINST_MAN_DIR}/${FILE}"; retValChk
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
	echo ""
	echo "Please remove any ${RKHINST_ETC_DIR}/${FILE}.* files manually."
	echo ""
done

# Helper scripts: remove dir
# Application documents: remove dir
# Databases: remove dir
# Language support: remove dir

echo "Removing installation directories:"

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

if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
	if [ -d "/usr/local/rkhunter" ]; then
		echo ""
		echo "Note: The directory '/usr/local/rkhunter' still exists."
	fi
fi

echo ""
echo "Done removing files. Please double-check."

} # end doRemove

if [ $# -eq 0 ]; then
	showHelp
fi

while [ $# -ge 1 ]; do
	case $1 in
	h | -h | --help | --usage)
		showHelp
		;;
	-e | --examples) showExamples
		;;
	-v | --version)
		showVersion
		;;
	-l | --layout)
		shift 1
		case "$1" in
			custom)
				shift 1
				if [ -n "$1" ]; then
					RKHINST_LAYOUT="custom_$1"
				else
					echo "No custom layout given, exiting."
					exit 1
				fi
				;;
			default|oldschool|/usr|/usr/local|RPM)
				RKHINST_LAYOUT="$1"
				;;
			*)
				echo "Unknown layout given, exiting."
				exit 1
				;;
		esac
		;;
	-s | --striproot)
		shift 1
		if [ -n "$1" ]; then
			STRIPROOT="$1"
		else
			echo "Striproot requested but no directory name given, exiting."
			exit 1
		fi
		;;
	--show|--remove|--install)
		if [ -z "${RKHINST_LAYOUT}" ]; then
			echo "No layout given. The '--layout' option must be specified first."
			exit 1
		fi
		action=`echo "$1"|sed "s/-//g"`;
		case "$action" in
			show)	showTemplate $RKHINST_LAYOUT
				;;
			remove)	# Clean active window
				clear
				selectTemplate $RKHINST_LAYOUT
				doRemove
				;;
			install) # Clean active window
				 clear
				 selectTemplate $RKHINST_LAYOUT
				 doInstall
				 ;;
			*)	echo "No action given, exiting."
				exit 1
				;;
		esac
		exit 0
		;;
	*)
		echo "Wrong option \""${1}"\" given, exiting."
		showHelp
		;;
	esac
	shift
done

exit 0
