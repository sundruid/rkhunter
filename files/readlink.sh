#!/bin/sh

#
# This is a short script to get the full pathname of a link file.
# It has the same effect as the Linux 'readlink -f' command. The
# script was written because some systems have no 'readlink' command,
# and others have no '-f' option for readlink. As such we use the 'ls'
# command to get the link target.
#
# We check the 'pwd' command because the shell builtin command will
# usually print out the current directory, which may be a link, rather
# than the true working directory. The 'pwd' command itself shows the
# true directory.
#
# A soft (symbolic) link has two parts to it:
#
#       linkname -> target
#
# Usage: readlink.sh [-f] <linkname> <pwd command>
#


test "$1" == "-f" && shift

LINKNAME=$1
PWD_CMD=$2

test -z "${LINKNAME}" -o ! -h "${LINKNAME}" && exit 1

TARGET=`ls -ld ${LINKNAME} | awk '{ print $NF }'`

test -z "${TARGET}" && exit 1

test -z "${PWD_CMD}" -o ! -x "${PWD_CMD}" && PWD_CMD="pwd"


#
# We must first get the full pathname to the linkname directory.
#

if [ -z "`echo \"${LINKNAME}\" | grep '/'`" ]; then
	#
	# If the link name is just a filename, then just get where we are.
	#

	LINKDIR=`${PWD_CMD}`
else
	LINKDIR=`echo "${LINKNAME}" | sed -e 's:/[^/]*$::'`
	test -n "${LINKDIR}" && LINKDIR=`cd ${LINKDIR}; ${PWD_CMD}`
fi


#
# Now we test the target.
#

if [ -z "`echo \"${TARGET}\" | grep '/'`" ]; then
	#
	# If the target is just a filename, then do nothing.
	#

	:
elif [ -z "`echo \"${TARGET}\" | grep '^/'`" ]; then
	#
	# If the target doesn't begin with a '/', then prepend the
	# linkname directory and find the full pathname of that.
	#

	TARGETDIR=`echo "${TARGET}" | sed -e 's:/[^/]*$::'`
	TARGETDIR="${LINKDIR}/${TARGETDIR}"
	LINKDIR=`cd ${TARGETDIR}; ${PWD_CMD}`
	TARGET=`echo "${TARGET}" | sed -e 's:^.*/\([^/]*\)$:\1:'`
else
	#
	# If the target begins with a '/', then extract the directory
	# and get the full pathname of that.
	#

	LINKDIR=`echo "${TARGET}" | sed -e 's:/[^/]*$::'`
	test -n "${LINKDIR}" && LINKDIR=`cd ${LINKDIR}; ${PWD_CMD}`
	TARGET=`echo "${TARGET}" | sed -e 's:^.*/\([^/]*\)$:\1:'`
fi

echo "${LINKDIR}/${TARGET}"

exit
