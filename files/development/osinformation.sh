#!/bin/sh

echo "File locations:"
whereis -b md5
whereis -b md5sum
whereis -b md5sums
whereis -b sha1
whereis -b sha1sum
whereis -b sha1sums

echo "-------------------------------"
echo "Output uname -a:"
uname -a
echo "Output uname -m:"
uname -m
echo "Output uname -n:"
uname -n
echo "Output uname -p:"
uname -p
echo "Output uname -r:"
uname -r
echo "Output uname -s:"
uname -s
echo "Output uname -v:"
uname -v

for I in `ls /etc/*-release`; do
	echo "Found ${I}"
	echo "${I}:"
	cat ${I}
done

for I in `ls /etc/*_version`; do
	echo "Found ${I}"
	echo "${I}:"
	cat ${I}
done
