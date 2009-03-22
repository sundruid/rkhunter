#!/bin/sh

################################################################################
#
#  Rootkit Hunter installer
# --------------------------
#
# Copyright Michael Boelen ( michael AT rootkit DOT nl )
# See LICENSE file for use of this software
#
################################################################################

INSTALLER_NAME="Rootkit Hunter installer"
INSTALLER_VERSION="1.2.9"
INSTALLER_COPYRIGHT="Copyright 2003-2009, Michael Boelen"
INSTALLER_LICENSE="

Under active development by the Rootkit Hunter project team. For reporting
bugs, updates, patches, comments and questions see: rkhunter.sourceforge.net

Rootkit Hunter comes with ABSOLUTELY NO WARRANTY. This is free
software, and you are welcome to redistribute it under the terms
of the GNU General Public License. See LICENSE for details.
"

APPNAME="rkhunter"
APPVERSION="1.3.5"
RKHINST_OWNER="0:0"
RKHINST_MODE_EX="0750"
RKHINST_MODE_RW="0640"
RKHINST_MODE_RWR="0644"
RKHINST_LAYOUT=""
RKHINST_ACTION=""
RKHINST_ACTION_SEEN=0
USE_CVS=0
STRIPROOT=""
N="-n"

umask 027

OPERATING_SYSTEM=`uname 2>/dev/null`

if [ "${OPERATING_SYSTEM}" = "SunOS" ]; then
	if [ -z "$RANDOM" ]; then
		if [ -n "`which bash 2>/dev/null | grep '^/'`" ]; then
			exec bash $0 $*
		else
			exec ksh $0 $*
		fi

		exit 0
	fi
fi

case "${OPERATING_SYSTEM}" in
AIX|OpenBSD|Darwin|SunOS|IRIX*)
	# What is the default shell?
	if print >/dev/null 2>&1; then
		alias echo='print'
		ECHOOPT="--"
	elif [ "${OPERATING_SYSTEM}" = "IRIX" -o "${OPERATING_SYSTEM}" = "IRIX64" ]; then
		ECHOOPT=""
	elif [ "${OPERATING_SYSTEM}" = "Darwin" ]; then
		ECHOOPT=""
	else
		ECHOOPT="-e"
	fi

	if [ "${OPERATING_SYSTEM}" = "SunOS" ]; then
		# We need /usr/xpg4/bin before other directories on Solaris 
		PATH="/usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" 
	fi
	;;
*)
	ECHOOPT="-e"

	#
	# We want to get the actual shell used by this program, and
	# so we need to test /bin/sh.
	#

	MYSHELL=/bin/sh
	test -h ${MYSHELL} && MYSHELL=`readlink ${MYSHELL} 2>/dev/null`
	MYSHELL=`basename ${MYSHELL} 2>/dev/null`

	if [ "${MYSHELL}" = "dash" -o "${MYSHELL}" = "ash" ]; then
		ECHOOPT=""
	fi
	;;
esac


showHelp() { # Show help / version
	echo $ECHOOPT "${INSTALLER_NAME} ${INSTALLER_VERSION}"
	echo $ECHOOPT "Usage: $0 <parameters>"
	echo $ECHOOPT ""
	echo $ECHOOPT "Ordered valid parameters:"
	echo $ECHOOPT "--help (-h)      : Show this help."
	echo $ECHOOPT "--examples       : Show layout examples."
	echo $ECHOOPT "--layout <value> : Choose installation template (mandatory switch)."
	echo $ECHOOPT "                   The templates are:"
        echo $ECHOOPT "                    - default: (FHS compliant),"
        echo $ECHOOPT "                    - /usr,"
        echo $ECHOOPT "                    - /usr/local,"
	echo $ECHOOPT "                    - oldschool: previous version file locations,"
	echo $ECHOOPT "                    - custom: supply your own prefix,"
	echo $ECHOOPT "                    - RPM: for building RPM's. Requires \$RPM_BUILD_ROOT."
	echo $ECHOOPT "                    - DEB: for building DEB's. Requires \$DEB_BUILD_ROOT."
	echo $ECHOOPT "                    - TGZ: for building Slackware TGZ's. Requires \$TGZ_BUILD_ROOT."
	echo $ECHOOPT "--striproot      : Strip path from custom layout (for package maintainers)."
	echo $ECHOOPT "--install        : Install according to chosen layout."
	echo $ECHOOPT "--show           : Show chosen layout."
	echo $ECHOOPT "--remove         : Uninstall according to chosen layout."
	echo $ECHOOPT "--version        : Show the installer version."

	exit 1
}

showExamples() { # Show examples
	echo $ECHOOPT "${INSTALLER_NAME}"
	echo $ECHOOPT ""
	echo $ECHOOPT "Examples: "
	echo $ECHOOPT "1. Show layout, files in /usr:"
	echo $ECHOOPT "     installer.sh --layout /usr --show"
	echo $ECHOOPT ""
	echo $ECHOOPT "2. Install, layout /usr/local:"
	echo $ECHOOPT "     installer.sh --layout /usr/local --install"
	echo $ECHOOPT ""
	echo $ECHOOPT "3. Install in temporary directory /tmp/rkhunter/usr/local,"
	echo $ECHOOPT " with files in /usr/local (for package maintainers):"
	echo $ECHOOPT "      mkdir -p /tmp/rkhunter/usr/local"
	echo $ECHOOPT "     installer.sh --layout custom /tmp/rkhunter/usr/local \\"
	echo $ECHOOPT "     --striproot /tmp/rkhunter --install"
	echo $ECHOOPT ""
	echo $ECHOOPT "4. Remove files, layout /usr/local:"
	echo $ECHOOPT "     installer.sh --layout /usr/local --remove"
	echo $ECHOOPT ""
	echo $ECHOOPT "Note: The installer will not remove files when a custom layout is chosen."

	exit 1
}

showVersion() { echo "${INSTALLER_NAME} ${INSTALLER_VERSION} ${INSTALLER_LICENSE}"; exit 1; }

selectTemplate() { # Take input from the "--installdir parameter"
case "$1" in
	/usr|/usr/local|default|custom_*|RPM|DEB|TGZ)
		case "$1" in
			default)
				PREFIX="/usr/local"
				;;
			custom_*)
				PREFIX=`echo "${RKHINST_LAYOUT}"|sed "s|custom_||g"`
				case "${PREFIX}" in
					.)
						if [ "${RKHINST_ACTION}" = "install" ]; then
							echo "Standalone installation into ${PWD}/files"
						fi
						;;
					.*|/.*)
						echo "Bad prefix chosen, exiting."
						exit 1
						;;
					*)
						if [ "${RKHINST_ACTION}" = "install" ]; then
							RKHTMPVAR=`echo "${PATH}" | grep "${PREFIX}/bin"`
							if [ -z "${RKHTMPVAR}" ]; then
								echo ""
								echo "Note: Directory ${PREFIX}/bin is not in your PATH"
								echo ""
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
			DEB)    if [ -n "${DEB_BUILD_ROOT}" ]; then
					PREFIX="${DEB_BUILD_ROOT}/usr"
				else
					echo "DEB prefix chosen but \$DEB_BUILD_ROOT variable not found, exiting."
					exit 1
				fi
				;;
			TGZ)    if [ -n "${TGZ_BUILD_ROOT}" ]; then
					PREFIX="${TGZ_BUILD_ROOT}/usr"
				else
					echo "TGZ prefix chosen but \$TGZ_BUILD_ROOT variable not found, exiting."
					exit 1
				fi
				;;
			*)	PREFIX="$1"
				;;
		esac
		case "$1" in
			RPM|DEB|TGZ)
				;;
			*)
				if [ "${RKHINST_ACTION}" = "install" ]; then
					if [ ! -d "${PREFIX}" ]; then
						echo "Bad prefix chosen (non-existent directory), exiting."
						echo "Perhaps run \"mkdir -p ${PREFIX}\" first?"
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
			DEB)    SYSCONFIGDIR="${DEB_BUILD_ROOT}/etc"
				;;
			TGZ)    SYSCONFIGDIR="${TGZ_BUILD_ROOT}/etc"
				;;
			*)	SYSCONFIGDIR="/etc"
				;;
		esac
		case "$1" in
			custom_*)
				if [ "`uname -m`" = "x86_64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
				VARDIR="${PREFIX}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			RPM)	if [ "`uname -m`" = "x86_64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
				VARDIR="${RPM_BUILD_ROOT}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			DEB)
				LIBDIR="${PREFIX}/lib"
				VARDIR="${DEB_BUILD_ROOT}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			TGZ)
				if [ "`uname -m`" = "x86_64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
				VARDIR="${TGZ_BUILD_ROOT}/var"
				SHAREDIR="${PREFIX}/share"; BINDIR="${PREFIX}/bin"
				;;
			*)
				if [ -d "${PREFIX}/lib64" ]; then
					LIBDIR="${PREFIX}/lib64"
				else
					LIBDIR="${PREFIX}/lib"
				fi
				VARDIR="/var"
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
elif [ "${RKHINST_LAYOUT}" = "DEB" ]; then
	RKHINST_DB_DIR="${VARDIR}/lib/${APPNAME}/db"
	RKHINST_TMP_DIR="${VARDIR}/lib/${APPNAME}/tmp"
	RKHINST_DOC_DIR="${SHAREDIR}/doc/${APPNAME}"
	RKHINST_SCRIPT_DIR="${SHAREDIR}/${APPNAME}/scripts"
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
if [ "${RKHINST_LAYOUT}" = "DEB" ]; then
	RKHINST_DOC_FILES="ACKNOWLEDGMENTS FAQ README WISHLIST"
else
	RKHINST_DOC_FILES="ACKNOWLEDGMENTS CHANGELOG FAQ LICENSE README WISHLIST"
fi
RKHINST_MAN_FILES="${APPNAME}.8"

}

# Additions we need to be aware / take care of:
# any /contrib/ files which should include any RH*L/alike ones:
# Additions we need to be aware / take care of wrt RH*L/alike:
# /etc/cron.daily/rkhunter (different versions of cronjob)
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
				echo ""; echo "Got STRIPROOT=\"${STRIPROOT}\""
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
		RPM|DEB|TGZ) 
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
	RPM|DEB|TGZ) 
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
for RKHWEBCMD in wget links elinks lynx curl GET bget; do
	echo $N "    ${RKHWEBCMD}: "

	SEARCH=`which ${RKHWEBCMD} 2>/dev/null`
	if [ -z "${SEARCH}" ]; then
		echo "not found."
	else
		break
	fi
done

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
		RPM|DEB|TGZ)
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
				find ./files -type f -name Entries -o -name Repository -o -name Root | while read FILE; do
					rm -rf "${FILE}"
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
				echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter.conf" >> rkhunter.conf
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
				chmod "${RKHINST_MODE_RWR}" "${RKHINST_MAN_DIR}/${FILE}"
				;;
		esac
done

# Application documents
for FILE in ${RKHINST_DOC_FILES}; do
	echo $N " Installing ${FILE}: "
	cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}"; retValChk
	chmod "${RKHINST_MODE_RWR}" "${RKHINST_DOC_DIR}/${FILE}"
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
		RPM|DEB|TGZ)	
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
		echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >> "${RKHINST_ETC_DIR}/${NEWFILE}"

		if [ "${RKHINST_LAYOUT}" != "RPM" -a "${RKHINST_LAYOUT}" != "DEB" -a "${RKHINST_LAYOUT}" != "TGZ" ]; then
			echo " >>> "
			echo " >>> PLEASE NOTE: inspect for update changes in "${RKHINST_ETC_DIR}/${NEWFILE}""
			echo " >>> and apply to "${RKHINST_ETC_DIR}/${FILE}" before running Rootkit Hunter."
			echo " >>> "
		fi
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
			echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${RPM_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
		elif [ -n "${TGZ_BUILD_ROOT}" ]; then
			echo "INSTALLDIR=${PREFIX}" | sed "s|${TGZ_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${TGZ_BUILD_ROOT}||g" >> "${RKHINST_ETC_DIR}/${FILE}"
		# Done with a patch during the build process
		elif [ -z "${DEB_BUILD_ROOT}" ]; then
			echo "INSTALLDIR=${PREFIX}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" >> "${RKHINST_ETC_DIR}/${FILE}"
			echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >> "${RKHINST_ETC_DIR}/${FILE}"
		fi
	fi
done

# Strip root from fake root install.
if [ -n "${STRIPROOT}" ]; then
	find "${PREFIX}" -type f | while read f; do 
		grep "${PREFIX}" "${f}" >/dev/null 2>&1 && { echo $N " Striproot ${f}: "; sed -i "s|${STRIPROOT}||g" "${f}"; retValChk; }
	done
fi

# Finally copy the passwd/group files to the TMP directory
# to avoid warnings when rkhunter is first run.

case "${RKHINST_LAYOUT}" in
	RPM|DEB|TGZ)	# This is done by a %post section in the spec file / postinst file.
		;;
	*)
		cp -p /etc/passwd ${RKHINST_TMP_DIR} >/dev/null 2>&1
		cp -p /etc/group ${RKHINST_TMP_DIR} >/dev/null 2>&1
		;;
esac

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

# Remove any old log files.
rm -f /var/log/rkhunter.log /var/log/rkhunter.log.old >/dev/null 2>&1

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
			default|oldschool|/usr|/usr/local|RPM|DEB|TGZ)
				RKHINST_LAYOUT="$1"
				;;
			*)
				echo "Unknown layout given, exiting: $1"
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

		RKHINST_ACTION_SEEN=1
		RKHINST_ACTION=`echo $ECHOOPT "$1"|sed "s/-//g"`

		case "${RKHINST_ACTION}" in
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
			"")	echo "No action given, exiting."
				exit 1
				;;
			*)	echo "Unknown action given, exiting: ${RKHINST_ACTION}"
				exit 1
				;;
		esac
		exit 0
		;;
	*)
		echo "Unknown option \"${1}\" given."
		echo ""
		showHelp
		;;
	esac
	shift
done

# We only get here when some installation action was to be taken.
if [ $RKHINST_ACTION_SEEN -eq 0 ]; then
	echo "No action given, exiting."
fi

exit 0
