#!/bin/sh

  NORMAL="[0;39m" 
  WARNING="[33;55;1m" # yellow WARNING
  YELLOW="[1;33m" # yellow
  WHITE="[1;37m"
  OK="[1;32m" # green OK
  DARKGRAY="[1;30m" # green OK
  test="[1;36m" # green OK
  green="[1;32m" # green
  red="[1;31m" # red
  BAD="[1;31m" # red BAD

SHOWHELP=0
SCANNED=0
INFECTED=0
DEBUG=1
SHOWWARNINGSONLY=1

if [ "$2" = "verbose" ]
  then
    VERBOSE=1
  else
    VERBOSE=0
fi


# hidm_func: Synapsys LKM

# MD5 hash fixers
EVILSTRINGS1="Can't%%fix%%checksum fixer:"

#################################################################################

# Misc (common cracker strings)
EVILSTRINGS2="0wn3d
31337
gives%%all%%users%%root
r00tkit
backdoor
BACKDOOR
fuck%%off
bullshit
bitch
Parasite
FUCK%%OFF"

# Gives all users root: local exploit
# r00tkit: used in a FreeBSD to use KLDload/KLDunload (even if you're not root...)
# bitch, Parasite: parasite/4553 Invader (ELF infector)
# FUCK OFF: ASMD (Admins Suck My Dick -un infector)
# 0wn3d

#################################################################################

# (D)DoS
EVILSTRINGS3="
targa3
MStreaming
smurf%%attack
flood%%network
Flood%%Network%%Denial%%of%%Service
acking%%attacker
ack%%attacker
Apache-Chunk
smurf.c
flood.c"

# targa3: DDoS-tool, to penetrate hosts/networks
# MStreaming: Master/Slave DDoS
# DoS tool: DRDoS
# zombie: misc DDoS tools
# acking attacker, ack attacker: ldaa, ack attacker
# Apache-Chunk: Apache remote DoS attacker
# smurf.c: smurf attack tool (like smurf and papasmurf)
# flood.c: flooder

#################################################################################

# Spoofers
EVILSTRINGS4="spoofs spoofer"

# LKM's with maybe nasty purposes (like sniffers)
EVILSTRINGS5="
sebek%%initialing
sebek.c
Sebek%%Sniffer
termlog
dsniff
Anti%%Anti%%Sniffer
set%%promisc%%flag
name%%sniffer
gork.conf
CAPLEN%%Exceeded
Linux%%Key%%Logger
vlog%%<logfile>
"

# sebek initialing: Sebek LKM (Honeypot Project), version 2
# sebek.c: Sebek LKM (Honeypot Project), version 2
# termlog: terminal logger
# ipex: IPEX sniffer (forensic packet sniffer)
# pcap: sniffer
# dsniff: sniffer
# Anti Anti Sniffer: patch for Anti-sniffers (so... an evil one)
# piove: kernel sniffer (FreeBSD)
# set promisc sniffer, name sniffer: SNMP community scanner, name sniffer (SPJscns)
# gork.conf: tcp/ip/udp/icmp dumper
# CAPLEN Exceeded: linsniffer
# Linux Key Logger: Linux keylogger (lkl)
# vlog <logfile>: slog (simple keylogger)

# Backdoors
EVILSTRINGS6="Found%%adore Tried%%to%%authorized%%myself you_make_me_real thc_bck OpenBSD%%backdoor WALLA%%WALLA vru%%vruk Sysback .pwsx00 to%%hack%%today /tmp/pass_ssh.log ptscene.org \"/bin/sh
flkm:%%successfully%%installed
"
# Found adore: Adore (ava component)
# Tried to authorized myself
# you_make_me_real_args,you_make_me_real_sysent,thc_bck,OpenBSD backdoor: THC Backdoor (Linux and OpenBSD)
# Sysback, .pwsx00, to hack today: backdoor (FreeBSD RootKit)
# /tmp/pass_ssh.log, ptscene.org: SSH backdoor
# "/bin/sh: backdoor shell
# flkm: successfully installed: THC flkm (solaris LKM)

# Cleaners (evil cleaners...) and anti-tools
EVILSTRINGS7="
Getting%%outta%%here
No%%StMichael%%found
Bender%%called
/var/log/wtmp%%/var/log/lastlog
"
# Getting outta here: cleans our valuable logfiles...
# 'No StMichael found' / 'Bender called': Bender (anti-StMichael tool)
# /var/log/wtmp /var/log/lastlog: log wiper

# Logfiles
EVILSTRINGS8="HISTFILE=/dev/null HISTSIZE=0"

# Zombies
EVILSTRINGS9="flooder lamer"
# flooder, lamer: mh (mech, part of Dica rootkit)

EVILSTRINGS="${EVILSTRINGS1} ${EVILSTRINGS2} ${EVILSTRINGS3} ${EVILSTRINGS4} ${EVILSTRINGS5} ${EVILSTRINGS6} ${EVILSTRINGS7} ${EVILSTRINGS8}"
EVILSTRINGS=`echo ${EVILSTRINGS} | sed 's/ /|/g'`
EVILSTRINGS="'${EVILSTRINGS}'"

GOODSTRINGS="test bitchars"
GOODSTRINGS=`echo ${GOODSTRINGS} | sed 's/ /|/g'`

BEGINTIME=`date +%s`


if [ $# -lt 1 ]; then
  echo "Fatal error: Not enough parameters"
  exit 1
fi

SCANDIRS=$1

waitonkeypress()
  {
    read a
  }

for I in ${SCANDIRS}; do
  if [ $VERBOSE -eq 1 ]; then
    echo -n "Checking directory '${I}'... "
  fi
  if [ -d $I ]
    then
      if [ $VERBOSE -eq 1 ]; then
        echo "Exists"
      fi
      for J in `ls -A ${I}/*`; do

        ALLSTRINGS=`strings ${J}`
        SCANNED=`expr ${SCANNED} + 1`
        FOUNDSTRING=""
        EREG=`strings $J | egrep $EVILSTRINGS | egrep -v $GOODSTRINGS`
        SIZE=`echo \'${J}\' | wc -c | tr -s ' ' | tr -d ' '`
	FILETYPE=`file -b ${J}`
        JUMP=`expr 60 - ${SIZE}`
        if [ ! "${EREG}" = "" ]; then
          FOUNDSTRING="${FOUNDSTRING} ${EREG} "
        fi

        if [ ! "${FOUNDSTRING}" = "" ]
          then


	    if [ ${VERBOSE} -eq 1 ]; then	  
	      echo -n "  - Checking $J... "
  	      echo -e "\033[${jump}C[ ${BAD}Found strings${NORMAL} ]"
echo "
--------------------------------------------------------------------------
  ${WARNING}String(s):${NORMAL}"
  for K in "${FOUNDSTRING}"; do
  echo "${K}"
  done 
echo "
Filetype: ${FILETYPE}
--------------------------------------------------------------------------
"
              echo "(press [ENTER])"
  	      waitonkeypress
	    fi
            INFECTED=`expr ${INFECTED} + 1`
          else
	    if [ ${SHOWWARNINGSONLY} -eq 0 ]; then
    	      echo -n "  - Checking $J... "  
	      echo -e "\033[${JUMP}C[ ${OK}OK${NORMAL} ]"
	    fi
        fi
      done
      
    else
      if [ $VERBOSE -eq 1 ]; then
        echo "${J} Skipped. Doesn't exists"
      fi
    fi

done


ENDTIME=`date +%s`
TOTALTIME=`expr ${ENDTIME} - ${BEGINTIME}`

if [ ! ${INFECTED} -eq 0 ]; then
  echo "Warning! Found some suspicious strings in one or more files"
fi



# The End
