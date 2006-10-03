#!/bin/sh

DIRS="/sbin /bin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin"
for I in ${DIRS}; do
	FILES=`ls ${I}/*`
	for J in ${FILES}; do
		./createfilehashes.pl ${J}
	done
done
