#!/bin/sh

# Temporary file for sorting the results
if [ -f /tmp/createhashes.tmp ]
  then
    rm -f /tmp/createhashes.tmp
fi

DIRS="/sbin /bin /usr/bin /usr/sbin"
FILES="find
cron
ifconfig
watch
w
whoami
who
users
stat
sha1sum
kill
find
file
pstree
killall
lsattr
mount
netstat
egrep
fgrep
grep
cat
chmod
chown
env
ls
su
ps
dmesg
kill
login
chkconfig
depmod
insmod
modinfo
sysctl
syslogd
init
runlevel
groups
ip"


for I in ${FILES}; do
  for J in ${DIRS}; do
    FILE="${J}/${I}"
    if [ -f ${FILE} ]
      then
        ./createfilehashes.pl ${FILE} >> /tmp/createhashes.tmp
    fi
  done
done

cat /tmp/createhashes.tmp | sort

if [ -f /tmp/createhashes.tmp ]
  then
    rm -f /tmp/createhashes.tmp
fi

