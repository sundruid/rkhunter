%define name rkhunter
%define ver 1.2.9
%define rel 1
%define epoch 0
%define _prefix /usr/local

# We can't let RPM do the dependencies automatic because it'll then pick up
# a correct but undesirable perl dependency, which rkhunter does not require
# in order to function properly.
AutoReqProv: no

Name: %{name}
Summary: %{name} scans for rootkits, backdoors and local exploits.
Version: %{ver}
Release: %{rel}
Epoch: %{epoch}
Copyright: GPL
Group: Applications/System
Source0: %{name}-%{version}.tar.gz
Requires: filesystem, bash, grep, findutils, net-tools, coreutils, e2fsprogs, modutils, procps, binutils, wget
Provides: %{name}
URL: http://rkhunter.sourceforge.net/
BuildRoot: %{_tmppath}/%{name}-%{version}

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
%setup -q

%build

%install
sh ./installer.sh --install --layout RPM


# make a cron.daily file to mail us the reports
%{__mkdir} -p "${RPM_BUILD_ROOT}/%{_sysconfdir}/cron.daily"
%{__cat} > "${RPM_BUILD_ROOT}/%{_sysconfdir}/cron.daily/01-rkhunter" <<EOF
#!/bin/sh
%{_bindir}/rkhunter --cronjob | /bin/mail -s 'rkhunter Daily Run' root
EOF
%{__chmod} a+rwx,g-w,o-rwx ${RPM_BUILD_ROOT}%{_sysconfdir}/cron.daily/01-rkhunter


						
%clean
case "$RPM_BUILD_ROOT" in
	/home/*) rm -rf $RPM_BUILD_ROOT
	;;
	*)
	echo Invalid Build root \'"$RPM_BUILD_ROOT"\'
	;;
esac


%define docdir %{_prefix}/share/doc/%{name}-%{version}
%files
%defattr(-,root,root)
%attr(640,root,root) %config(noreplace) %verify(not mtime) %{_sysconfdir}/%{name}.conf
%attr(750,root,root) %{_prefix}/bin/%{name}
%attr(750,root,root) %dir %{_var}/%{name}
%attr(750,root,root) %dir %{_var}/%{name}/db
%attr(640,root,root) %verify(not mtime) %{_var}/%{name}/db/*.dat
%attr(750,root,root) %dir %{_var}/%{name}/tmp
%attr(750,root,root) %dir %{_libdir}/%{name}/scripts
%attr(750,root,root) %{_libdir}/%{name}/scripts/*.pl
%attr(750,root,root) %{_libdir}/%{name}/scripts/*.sh
%attr(644,root,root) %{_mandir}/man8/%{name}.8
%attr(750,root,root) %{docdir}
%{_sysconfdir}/cron.daily/01-rkhunter


%changelog
* Sun Nov 12 2006 unSpawn - 1.2.9
- Re-spec, new installer

* Fri Sep 29 2006 unSpawn - 1.2.9
- Updated for release 1.2.9

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


