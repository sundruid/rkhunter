#!/bin/sh
FILES="/usr/bin/find /usr/sbin/cron /sbin/ifconfig /usr/bin/watch /usr/bin/w /usr/bin/whoami /usr/bin/who /usr/bin/users /usr/bin/stat /usr/bin/sha1sum /usr/bin/kill /usr/bin/find /usr/bin/file /usr/bin/pstree /usr/bin/killall /usr/bin/lsattr /bin/mount /bin/netstat /bin/egrep /bin/fgrep /bin/grep /bin/cat /bin/chmod /bin/chown /bin/env /bin/ls /bin/su /bin/ps /bin/dmesg /bin/kill /bin/login /sbin/chkconfig /sbin/depmod /sbin/insmod /sbin/modinfo /sbin/sysctl /sbin/syslogd /sbin/init /sbin/runlevel /usr/bin/groups /sbin/ip"
OSID="OSNO"

for I in ${FILES}; do
  if [ -f ${I} ]
    then
      FILESIZE=`ls -l ${I} | tr -s ' ' ',' | cut -d ',' -f5`
      RPM=`rpm -qf ${I}`
      MD5=`md5sum ${I} | cut -d ' ' -f1`
      SHA1=`sha1sum ${I} | cut -d ' ' -f1`
      echo "${OSID}:${I}:${MD5}:${SHA1}:${FILESIZE}:${RPM}:"
  fi
done


