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
INSTALLER_VERSION="1.2.11"
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
ERRCODE=0
STRIPROOT=""

umask 027

OPERATING_SYSTEM=`uname 2>/dev/null`

if [ "${OPERATING_SYSTEM}" = "SunOS" ]; then
	if [ -z "$RANDOM" ]; then
		if [ -n "`which bash 2>/dev/null | grep -v ' '`" ]; then
			exec bash $0 $*
		elif [ -n "`which ksh 2>/dev/null | grep -v ' '`" ]; then
			exec ksh $0 $*
		else
			echo "Unable to find the bash or ksh shell to run the installer. Exiting."
			exit 1
		fi

		exit 0
	fi

	# We need /usr/xpg4/bin before other directories on Solaris.
	PATH="/usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" 
fi


showHelp() { # Show help / version
	echo "${INSTALLER_NAME} ${INSTALLER_VERSION}"
	echo "Usage: $0 <parameters>"
	echo ""
	echo "Ordered valid parameters:"
	echo '--help (-h)      : Show this help.'
	echo "--examples       : Show layout examples."
	echo '--layout <value> : Choose installation template (mandatory switch).'
	echo "                   The templates are:"
        echo '                    - default: (FHS compliant),'
        echo "                    - /usr,"
        echo "                    - /usr/local,"
	echo "                    - oldschool: previous version file locations,"
	echo "                    - custom: supply your own prefix,"
	echo "                    - RPM: for building RPM's. Requires \$RPM_BUILD_ROOT."
	echo "                    - DEB: for building DEB's. Requires \$DEB_BUILD_ROOT."
	echo "                    - TGZ: for building Slackware TGZ's. Requires \$TGZ_BUILD_ROOT."
	echo '--striproot      : Strip path from custom layout (for package maintainers).'
	echo "--install        : Install according to chosen layout."
	echo "--show           : Show chosen layout."
	echo "--remove         : Uninstall according to chosen layout."
	echo "--version        : Show the installer version."

	return
}

showExamples() { # Show examples
	echo "${INSTALLER_NAME}"
	echo ""
	echo "Examples:"
	echo "1. Show layout, files in /usr:"
	echo "        installer.sh --layout /usr --show"
	echo ""
	echo "2. Install in /usr/local:"
	echo "        installer.sh --layout /usr/local --install"
	echo ""
	echo '3. Install in chosen (custom) directory /opt:'
	echo "        installer.sh --layout custom /opt --install"
	echo ""
	echo "4. Install in temporary directory /tmp/rkhunter/usr/local,"
	echo '   with files in /usr/local (for package maintainers):'
	echo "        mkdir -p /tmp/rkhunter/usr/local"
	echo "        installer.sh --layout custom /tmp/rkhunter/usr/local \\"
	echo "                     --striproot /tmp/rkhunter --install"
	echo ""
	echo "5. Remove files, layout /usr/local:"
	echo "        installer.sh --layout /usr/local --remove"
	echo ""

	return
}

showVersion() { echo "${INSTALLER_NAME} ${INSTALLER_VERSION} ${INSTALLER_LICENSE}"; return; }

selectTemplate() { # Take input from the "--installdir parameter"
	case "$1" in
	/usr|/usr/local|default|custom_*|RPM|DEB|TGZ)
		case "$1" in
		default)
			PREFIX="/usr/local"
			;;
		custom_*)
			PREFIX=`echo "${RKHINST_LAYOUT}" | sed 's/custom_//g'`

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
		RPM)
			if [ -n "${RPM_BUILD_ROOT}" ]; then
				PREFIX="${RPM_BUILD_ROOT}/usr/local"
			else
				echo "RPM prefix chosen but \$RPM_BUILD_ROOT variable not found, exiting."
				exit 1
			fi
			;;
		DEB)
			if [ -n "${DEB_BUILD_ROOT}" ]; then
				PREFIX="${DEB_BUILD_ROOT}/usr"
			else
				echo "DEB prefix chosen but \$DEB_BUILD_ROOT variable not found, exiting."
				exit 1
			fi
			;;
		TGZ)
			if [ -n "${TGZ_BUILD_ROOT}" ]; then
				PREFIX="${TGZ_BUILD_ROOT}/usr"
			else
				echo "TGZ prefix chosen but \$TGZ_BUILD_ROOT variable not found, exiting."
				exit 1
			fi
			;;
		*)
			PREFIX="$1"
			;;
		esac

		case "$1" in
		RPM|DEB|TGZ)
			;;
		*)
			if [ "${RKHINST_ACTION}" = "install" ]; then
				if [ ! -d "${PREFIX}" ]; then
					echo "Bad prefix chosen: non-existent directory. Exiting."
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
		RPM)
			SYSCONFIGDIR="${RPM_BUILD_ROOT}/etc"
			;;
		DEB)
			SYSCONFIGDIR="${DEB_BUILD_ROOT}/etc"
			;;
		TGZ)
			SYSCONFIGDIR="${TGZ_BUILD_ROOT}/etc"
			;;
		*)
			SYSCONFIGDIR="/etc"
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
		RPM)
			if [ "`uname -m`" = "x86_64" ]; then
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
		echo "No template chosen, exiting."
		exit 1
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

	return
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

	return
}


useCVS() {
	# If the 'which' output contains a space, then it is probably an error.
	SEARCH=`which cvs 2>/dev/null | grep -v ' '`

	if [ -z "${SEARCH}" ]; then
		echo "Unable to find the 'cvs' command."
		exit 1
	else
		cvs -z3 -d:pserver:anonymous@rkhunter.cvs.sourceforge.net:/cvsroot/rkhunter co rkhunter
		ERRCODE=$?

		if [ $ERRCODE -eq 0 ]; then
			echo "Succeeded in getting Rootkit Hunter source from CVS."

			if [ -d "./files" ]; then
				rm -rf "./files" >/dev/null 2>&1
			fi

			mv -f rkhunter/files .

			if [ -d "./files/CVS" ]; then
				rm -rf "./files/CVS" >/dev/null 2>&1
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
			echo "Failed to get Rootkit Hunter from CVS: code $ERRCODE: exiting."
			exit 1
		fi
	fi

	return
}


#################################################################################
#
# Start installation
#
#################################################################################

doInstall()  {
	# Preflight checks
	if [ -f "./files/${APPNAME}" ]; then
		echo "Checking system for: ${INSTALLER_NAME} files: found"

		if [ $USE_CVS -eq 1 ]; then
			# You want it, and you got it!
			# The hottest source in the land...
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
		echo "Checking system for: ${INSTALLER_NAME} files: FAILED"
		echo "Installer files not in \"${PWD}/files\". Exiting."
		exit 1
	fi


	echo " Available file retrieval tools:"

	for RKHWEBCMD in wget links elinks lynx curl GET bget; do
		SEARCH=`which ${RKHWEBCMD} 2>/dev/null | grep -v ' '`

		if [ -z "${SEARCH}" ]; then
			echo "    ${RKHWEBCMD}: not found"
		else
			break
		fi
	done

	if [ -n "${SEARCH}" ]; then
		echo "    ${RKHWEBCMD}: found"
	else
		echo ""
		echo " Please install one of wget, links, elinks, lynx, curl, GET or"
		echo ' bget (from www.cpan.org/authors/id/E/EL/ELIJAH/bget)'
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
		if [ -d "${PREFIX}" ]; then
			if [ -w "${PREFIX}" ]; then
				echo " Checking PREFIX $PREFIX: it exists and is writable."

				# That's enough for a standalone installation.
				if [ "${PREFIX}" = "." ]; then
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

					echo "LOGFILE=${PREFIX}/rkhunter.log" >>rkhunter.conf 
					echo "TMPDIR=$PREFIX" >>rkhunter.conf 
					echo "DBDIR=$PREFIX" >>rkhunter.conf 
					echo "SCRIPTDIR=$PREFIX" >>rkhunter.conf 
					echo "INSTALLDIR=$PREFIX" >>rkhunter.conf
					echo "USER_FILEPROP_FILES_DIRS=$PREFIX/rkhunter.conf" >>rkhunter.conf

					sed -e "s|-f /etc/rkhunter.conf|-f $PREFIX/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$PREFIX|g" rkhunter >rkhunter.
					mv -f rkhunter. rkhunter

					chmod "${RKHINST_MODE_EX}" rkhunter

					echo "Finished install in \"${PREFIX}\"."

					exit 0
				fi
			else
				echo " Checking PREFIX $PREFIX: it exists, but it is NOT writable. Exiting."
				exit 1
			fi
		elif [ -e "${PREFIX}" ]; then
			echo " Checking PREFIX $PREFIX: it is NOT a directory. Exiting."
			exit 1
		else
			echo " Checking PREFIX $PREFIX: it does NOT exist. Exiting."
			exit 1
		fi
		;;
	esac # end Check PREFIX


	echo " Checking installation directories:"

	if [ "${RKHINST_LAYOUT}" = "oldschool" ]; then
		RKHDIR_LIST="${RKHINST_DIRS}"
	else
		RKHDIR_LIST="${RKHINST_DIRS} ${LIBDIR} ${VARDIR}/lib"
	fi

	umask 022
	for DIR in ${RKHDIR_LIST}; do
		if [ -d "${DIR}" ]; then
			if [ -w "${PREFIX}" ]; then
				echo "  Directory ${DIR}: exists and is writable."
			else
				echo "  Directory ${DIR}: exists, but it is NOT writable. Exiting."
				exit 1
			fi
		else
			mkdir -p ${DIR}
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo "  Directory ${DIR}: creating: OK"
			else
				echo "  Directory ${DIR}: creating: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
		fi
	done
	umask 027

	for DIR in ${RKHINST_DIRS_EXCEP}; do
		if [ -d "${DIR}" ]; then
			if [ -w "${PREFIX}" ]; then
				echo "  Directory ${DIR}: exists and is writable."
			else
				echo "  Directory ${DIR}: exists, but it is NOT writable. Exiting."
				exit 1
			fi
		else
			mkdir -p "${DIR}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo "  Directory ${DIR}: creating: OK"
			else
				echo "  Directory ${DIR}: creating: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
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
		*.pl|*.sh)
			cp -f ./files/"${FILE}" "${RKHINST_SCRIPT_DIR}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_SCRIPT_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
			;;
		*.dat)
			cp -f ./files/"${FILE}" "${RKHINST_DB_DIR}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_DB_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
			;;
		*.8)
			cp -f ./files/"${FILE}" "${RKHINST_MAN_DIR}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RWR}" "${RKHINST_MAN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
			;;
		esac
	done


	# Application documents
	for FILE in ${RKHINST_DOC_FILES}; do
		cp -f ./files/"${FILE}" "${RKHINST_DOC_DIR}"
		ERRCODE=$?

		if [ $ERRCODE -eq 0 ]; then
			echo " Installing ${FILE}: OK"
			chmod "${RKHINST_MODE_RWR}" "${RKHINST_DOC_DIR}/${FILE}"
		else
			echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
			exit 1
		fi
	done


	# Language support files
	find ./files/i18n -type f | while read FILE; do
		cp "${FILE}" "${RKHINST_LANG_DIR}"
		ERRCODE=$?

		test $ERRCODE -ne 0 && break
	done

	if [ $ERRCODE -eq 0 ];then
		echo " Installing language support files: OK"
	else
		echo " Installing language support files: FAILED: Code $ERRCODE: exiting."
		exit 1
	fi


	# Application
	for FILE in ${RKHINST_BIN_FILES}; do
		case "${RKHINST_LAYOUT}" in
		RPM|DEB|TGZ)	
			cp -f ./files/"${FILE}" "${RKHINST_BIN_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
			;;
		*)	
			sed -e "s|-f /etc/rkhunter.conf|-f $RKHINST_ETC_DIR/rkhunter.conf|g" -e "s|CONFIGFILE=\"/etc|CONFIGFILE=\"$RKHINST_ETC_DIR|g" ./files/"${FILE}" >"${RKHINST_BIN_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_EX}" "${RKHINST_BIN_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi
			;;
		esac
	done


	# Configuration file
	for FILE in ${RKHINST_ETC_FILE}; do
		# We need people to make local changes themselves, so
		# give opportunity and alert. Don't use Perl to get value.
		if [ -n "$RANDOM" ]; then
			RANDVAL=$RANDOM
		else
			RANDVAL=`date +%Y%m%d%H%M%S 2>/dev/null`

			if [ -z "${RANDVAL}" ]; then
				RANDVAL=$$
			fi
		fi

		if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
			NEWFILE="${FILE}.${RANDVAL}"

			cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}/${NEWFILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE} in no-clobber mode: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${NEWFILE}"
			else
				echo " Installing ${FILE} in no-clobber mode: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi

			echo "" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "INSTALLDIR=${PREFIX}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "DBDIR=${RKHINST_DB_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "TMPDIR=${RKHINST_TMP_DIR}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"
			echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >>"${RKHINST_ETC_DIR}/${NEWFILE}"

			case "${RKHINST_LAYOUT}" in
			RPM|DEB|TGZ)
				;;
			*)
				echo " >>>"
				echo " >>> PLEASE NOTE: inspect for update changes in \"${RKHINST_ETC_DIR}/${NEWFILE}\""
				echo " >>> and apply to \"${RKHINST_ETC_DIR}/${FILE}\" before running Rootkit Hunter."
				echo " >>>"
				;;
			esac
		else
			cp -f "./files/${FILE}" "${RKHINST_ETC_DIR}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Installing ${FILE}: OK"
				chmod "${RKHINST_MODE_RW}" "${RKHINST_ETC_DIR}/${FILE}"
			else
				echo " Installing ${FILE}: FAILED: Code $ERRCODE: exiting."
				exit 1
			fi

			echo "" >>"${RKHINST_ETC_DIR}/${FILE}"

			if [ -n "${RPM_BUILD_ROOT}" ]; then
				echo "INSTALLDIR=${PREFIX}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${RPM_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
			elif [ -n "${TGZ_BUILD_ROOT}" ]; then
				echo "INSTALLDIR=${PREFIX}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" | sed "s|${TGZ_BUILD_ROOT}||g" >>"${RKHINST_ETC_DIR}/${FILE}"
			# Done with a patch during the build process
			elif [ -z "${DEB_BUILD_ROOT}" ]; then
				echo "INSTALLDIR=${PREFIX}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "DBDIR=${RKHINST_DB_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "SCRIPTDIR=${RKHINST_SCRIPT_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "TMPDIR=${RKHINST_TMP_DIR}" >>"${RKHINST_ETC_DIR}/${FILE}"
				echo "USER_FILEPROP_FILES_DIRS=${RKHINST_ETC_DIR}/${FILE}" >>"${RKHINST_ETC_DIR}/${FILE}"
			fi
		fi
	done


	# Strip root from fake root install.
	if [ -n "${STRIPROOT}" ]; then
		find "${PREFIX}" -type f | while read FILE; do 
			STR=`grep "${PREFIX}" "${FILE}" 2>/dev/null`

			if [ -n "${STR}" ]; then
				sed -i "s|${STRIPROOT}||g" "${FILE}"
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Striproot ${FILE}: OK"
				else
					echo " Striproot ${FILE}: FAILED: Code $ERRCODE: exiting."
					exit 1
				fi
			fi
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

	return
} # End doInstall


doRemove()  {
	RKHINST_DIRS="$RKHINST_ETC_DIR $RKHINST_BIN_DIR $RKHINST_SCRIPT_DIR $RKHINST_DOC_DIR $RKHINST_DB_DIR $RKHINST_TMP_DIR $RKHINST_LANG_DIR"
	RKHINST_DIRS_POST="$VARDIR $SHAREDIR $PREFIX"

	echo "Starting uninstallation"
	echo ""

	# Check the PREFIX
	if [ -d "${PREFIX}" ]; then
		if [ -w "${PREFIX}" ]; then
			echo "Checking PREFIX $PREFIX: it exists and is writable."
		else
			echo "Checking PREFIX $PREFIX: it exists, but is NOT writable. Exiting."
			exit 1
		fi
	elif [ -e "${PREFIX}" ]; then
		echo "Checking PREFIX $PREFIX: it exists but it is not a directory. Exiting."
		exit 1
	else
		echo "Checking PREFIX $PREFIX: it does NOT exist. Exiting."
		exit 1
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
			rm -f "${RKHINST_MAN_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${FILE}: OK"
			else
				echo " Removing ${FILE}: FAILED: Code $ERRCODE"
			fi
		fi
	done


	# Application
	for FILE in ${RKHINST_BIN_FILES}; do
		if [ -f "${RKHINST_BIN_DIR}/${FILE}" ]; then
			rm -f "${RKHINST_BIN_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${RKHINST_BIN_DIR}/${FILE}: OK"
			else
				echo " Removing ${RKHINST_BIN_DIR}/${FILE}: FAILED: Code $ERRCODE"
			fi
		fi
	done


	# Configuration file
	for FILE in ${RKHINST_ETC_FILE}; do
		if [ -f "${RKHINST_ETC_DIR}/${FILE}" ]; then
			rm -f "${RKHINST_ETC_DIR}/${FILE}"
			ERRCODE=$?

			if [ $ERRCODE -eq 0 ]; then
				echo " Removing ${RKHINST_ETC_DIR}/${FILE}: OK"
			else
				echo " Removing ${RKHINST_ETC_DIR}/${FILE}: FAILED: Code $ERRCODE"
			fi
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
		*/${APPNAME}) 
			if [ -d "${DIR}" ]; then
				rm -rf "${DIR}"
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Removing ${DIR}: OK"
				else
					echo " Removing ${DIR}: FAILED: Code $ERRCODE"
				fi
			fi
			;;
		*/${APPNAME}-${APPVERSION}) 
			# Anything involving a specific version number
			# needs to remove all old versions as well.
			DIR=`dirname "${DIR}"`

			for RKHAPPDIR in ${DIR}/${APPNAME}-*; do
				if [ -d "${RKHAPPDIR}" ]; then
					rm -rf "${RKHAPPDIR}"
					ERRCODE=$?

					if [ $ERRCODE -eq 0 ]; then
						echo " Removing ${RKHAPPDIR}: OK"
					else
						echo " Removing ${RKHAPPDIR}: FAILED: Code $ERRCODE"
					fi
				fi
			done
			;;
		*/${APPNAME}/*)
			DIR=`dirname "${DIR}"`

			if [ -d "${DIR}" ]; then
				rm -rf "${DIR}"
				ERRCODE=$?

				if [ $ERRCODE -eq 0 ]; then
					echo " Removing ${DIR}: OK"
				else
					echo " Removing ${DIR}: FAILED: Code $ERRCODE"
				fi
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

	return
} # end doRemove


#
# Start of the installer
#

if [ $# -eq 0 ]; then
	showHelp
	exit 1
fi

while [ $# -ge 1 ]; do
	case "$1" in
	h | -h | --help | --usage)
		showHelp
		exit 1
		;;
	-e | --examples)
		showExamples
		exit 1
		;;
	-v | --version)
		showVersion
		exit 1
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
		RKHINST_ACTION=`echo "$1" | sed 's/-//g'`

		case "${RKHINST_ACTION}" in
		show)
			showTemplate $RKHINST_LAYOUT
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
		"")
			echo "No action given, exiting."
			exit 1
			;;
		*)
			echo "Unknown action given, exiting: ${RKHINST_ACTION}"
			exit 1
			;;
		esac

		exit 0
		;;
	*)
		echo "Unknown option given: $1"
		echo ""

		showHelp
		exit 1
		;;
	esac

	shift
done

# We only get here when some installation action was to be taken.
if [ $RKHINST_ACTION_SEEN -eq 0 ]; then
	echo "No action given, exiting."
fi

exit 0
