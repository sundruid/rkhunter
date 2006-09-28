# We can't let RPM do the dependencies automatic because it'll then pick up
# a correct but undesirable perl dependency, which rkhunter does not require
# in order to function properly.
AutoReqProv: no

Summary:	Rootkit scans for rootkits, backdoors and local exploits.
Name:		rkhunter
Version:	1.2.8
Release:	1
Epoch:		0
License:	GPL
Group:          Applications/System
URL:		http://www.rootkit.nl/
Source0:	http://downloads.rootkit.nl/%{name}-%{version}.tar.gz
BuildArch:	noarch
Requires:	/bin/sh, /bin/ps, /bin/ls, /bin/cat, /bin/egrep
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
Rootkit scanner is scanning tool to ensure you for about 99.9%% you're
clean of nasty tools. This tool scans for rootkits, backdoors and local
exploits by running tests like:
	- MD5 hash compare
	- Look for default files used by rootkits
	- Wrong file permissions for binaries
	- Look for suspected strings in LKM and KLD modules
	- Look for hidden files
	- Optional scan within plaintext and binary files
	- Software version checks
	- Application tests

Rootkit Hunter is released as a GPL licensed project and free for everyone to use.


%prep
%setup -q -n %name

%build
#%%configure ...
# We have nothing to configure... yet...

%install
# Well... This could be a bit smaller if the install
# script was able to handle DSTDIR for example...

# (cjo) remove old version of build root, if it exists
%{__rm} -rf ${RPM_BUILD_ROOT}

%{__mkdir} -p ${RPM_BUILD_ROOT}%{_bindir}
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_sysconfdir}
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_libdir}
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_docdir}/rkhunter-%{version}
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_mandir}/man8
%{__mkdir} -p ${RPM_BUILD_ROOT}%{_var}/rkhunter/{db,tmp}
%{__chmod} ug+rwx,o-rwx ${RPM_BUILD_ROOT}%{_var}/rkhunter/tmp

%{__install} -m750 -p files/rkhunter		${RPM_BUILD_ROOT}%{_bindir}/

%{__install} -m640 -p files/backdoorports.dat	${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/defaulthashes.dat	${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/mirrors.dat		${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/os.dat		${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/md5blacklist.dat	${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/programs_bad.dat	${RPM_BUILD_ROOT}%{_var}/rkhunter/db/
%{__install} -m640 -p files/programs_good.dat	${RPM_BUILD_ROOT}%{_var}/rkhunter/db/

%{__install} -m644 -p files/CHANGELOG		${RPM_BUILD_ROOT}%{_docdir}/rkhunter-%{version}/
%{__install} -m644 -p files/LICENSE		${RPM_BUILD_ROOT}%{_docdir}/rkhunter-%{version}/
%{__install} -m644 -p files/README		${RPM_BUILD_ROOT}%{_docdir}/rkhunter-%{version}/
%{__install} -m644 -p files/WISHLIST		${RPM_BUILD_ROOT}%{_docdir}/rkhunter-%{version}/
%{__install} -m644 -p files/development/*.8	${RPM_BUILD_ROOT}%{_mandir}/man8/

%{__install} -m750 -p files/check_modules.pl	${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/
%{__install} -m750 -p files/check_port.pl	${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/
%{__install} -m750 -p files/filehashmd5.pl	${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/
%{__install} -m750 -p files/filehashsha1.pl	${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/
%{__install} -m750 -p files/showfiles.pl	${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/
%{__install} -m750 -p files/check_update.sh     ${RPM_BUILD_ROOT}%{_libdir}/rkhunter/scripts/

# (cjo) Put installation root in configuration file, then copy the rest
#       of the file from the original.
cat >> ${RPM_BUILD_ROOT}%{_sysconfdir}/rkhunter.conf << EOF
## Next three lines installed automatically by RPM. Do not change
## unless you know what you're doing...
INSTALLDIR=%{_prefix}
DBDIR=%{_var}/rkhunter/db
TMPDIR=%{_var}/rkhunter/tmp

EOF

cat files/rkhunter.conf >> ${RPM_BUILD_ROOT}%{_sysconfdir}/rkhunter.conf
%{__chmod} 640 ${RPM_BUILD_ROOT}%{_sysconfdir}/rkhunter.conf

# Only root should use rkhunter (at least for now)
%{__chmod} o-rwx -R ${RPM_BUILD_ROOT}%{_libdir}/rkhunter
%{__chmod} o-rwx -R ${RPM_BUILD_ROOT}%{_var}/rkhunter/db

# make a cron.daily file to mail us the reports
%{__mkdir} -p "${RPM_BUILD_ROOT}/%{_sysconfdir}/cron.daily"
%{__cat} > "${RPM_BUILD_ROOT}/%{_sysconfdir}/cron.daily/01-rkhunter" <<EOF
#!/bin/sh
%{_bindir}/rkhunter --cronjob | /bin/mail -s 'rkhunter Daily Run' root
EOF
%{__chmod} a+rwx,g-w,o-rwx ${RPM_BUILD_ROOT}%{_sysconfdir}/cron.daily/01-rkhunter

%clean
%{__rm} -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root,-)
%{_bindir}/rkhunter
%dir %{_libdir}/rkhunter
%doc %{_docdir}/rkhunter-%{version}
%{_mandir}/man8/*
%{_libdir}/rkhunter/scripts
%dir %{_var}/rkhunter/tmp
%{_var}/rkhunter/db
%config(noreplace) %verify(not mtime) %{_sysconfdir}/rkhunter.conf
%{_sysconfdir}/cron.daily/01-rkhunter


%changelog
* Tue Aug 10 2004 Michael Boelen - 1.1.5
- Added update script
- Extended description

* Sun Aug 08 2004 Greg Houlette - 1.1.5
- Changed the install procedure eliminating the specification of
  destination filenames (only needed if you are renaming during install)
- Changed the permissions for documentation files (root only overkill)
- Added the installation of the rkhunter Man Page
- Added the installation of the programs_{bad, good}.dat database files
- Added the installation of the LICENSE documentation file
- Added the chmod for root only to the /var/rkhunter/db directory

* Sun May 23 2004 Craig Orsinger (cjo) <cjorsinger@earthlink.net>
- version 1.1.0-1.cjo
- changed installation in accordance with new rootkit installation
  procedure
- changed installation root to conform to LSB. Use standard macros.
- added recursive remove of old build root as prep for install phase

* Wed Apr 28 2004 Doncho N. Gunchev - 1.0.9-0.mr700
- dropped Requires: perl - rkhunter works without it 
- dropped the bash alignpatch (check the source or contact me)
- various file mode fixes (.../tmp/, *.db)
- optimized the %%files section - any new files in the
  current dirs will be fine - just %%{__install} them.

* Mon Apr 26 2004 Michael Boelen - 1.0.8-0
- Fixed missing md5blacklist.dat

* Mon Apr 19 2004 Doncho N. Gunchev - 1.0.6-1.mr700
- added missing /usr/local/rkhunter/db/md5blacklist.dat
- patched to align results in --cronjob, I think rpm based
  distros have symlink /bin/sh -> /bin/bash
- added --with/--without alignpatch for conditional builds
  (in case previous patch breaks something)

* Sat Apr 03 2004 Michael Boelen / Joe Klemmer - 1.0.6-0
- Update to 1.0.6

* Mon Mar 29 2004 Doncho N. Gunchev - 1.0.0-0
- initial .spec file

