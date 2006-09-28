#!/bin/sh

#################################################################################
#
#  Rootkit Hunter installer
# --------------------------
#
# Copyright Michael Boelen ( michael AT rootkit DOT nl )
# See LICENSE file for use of this software
#
#################################################################################

INSTALLER_NAME="Rootkit Hunter installer"
INSTALLER_VERSION="1.2.4"
INSTALLER_COPYRIGHT="Copyright 2003-2005, Michael Boelen"
INSTALLER_LICENSE="
Rootkit Hunter comes with ABSOLUTELY NO WARRANTY. This is free
software, and you are welcome to redistribute it under the terms
of the GNU General Public License. See LICENSE for details.
"

# rootmgu: modified for solaris
case `uname` in
        AIX|OpenBSD|SunOS)
	# rootmgu:
        # What is the default shell
        if print >/dev/null 2>&1
          then
            alias echo='print'
            N="-n"
            E=""
            ECHOOPT="--"
          else
            E="-e"
            ECHOOPT=""
        fi
        ;;
        *) E="-e" ; N="-n" ; ECHOOPT="" ;;
esac

# rootmgu: some lines added for solaris...
case `uname` in
	SunOS)
		# We need /usr/xpg4/bin before other commands on solaris 
		PATH="/usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" 
		#export PATH
		;;
	*)
		;;
esac

# Default installation dir (you can change this with the --installdir option)
INSTALLDIR="/usr/local/rkhunter"
INSTALLPREFIX="./files/"

SHOWUSAGE=0
SHOWVERSION=0

while [ $# -ge 1 ]; do
  case $1 in
      -h | --help | --usage)
          SHOWUSAGE=1
          ;;
      -v | --version)
          SHOWVERSION=1
          ;;
      --installdir)
          shift
          INSTALLDIR="$1"
          ;;
      *)
          echo "Wrong parameter"
	  ;;
  esac
  shift
done

#################################################################################
#
# Show help / version
#
#################################################################################

if [ $SHOWUSAGE -eq 1 ]; then
  echo "${INSTALLER_NAME}"
  echo "${INSTALL_LICENSE}"
  echo "Usage: $0 <parameters>"
  echo ""
  echo "Valid parameters:"
  echo $ECHOOPT "--help (-h)              : Show help"
  echo $ECHOOPT "--installdir <dir>       : Installation directory (default: ${INSTALLDIR})"
  exit 1
fi

if [ $SHOWVERSION -eq 1 ]; then
  echo "${INSTALLER_NAME} ${INSTALL_VERSION}"
  exit 1
fi

#################################################################################
#
# Installation & configuration
#
#################################################################################

# Install files

# Prefix: <INSTALLDIR>/lib/rkhunter
INSTALLFILES="
overwrite:check_modules.pl:/scripts/check_modules.pl:Perl%%module%%checker
overwrite:check_update.sh:/scripts/check_update.sh:Database%%updater
overwrite:check_port.pl:/scripts/check_port.pl:Portscanner
overwrite:filehashmd5.pl:/scripts/filehashmd5.pl:MD5%%Digest%%generator
overwrite:filehashsha1.pl:/scripts/filehashsha1.pl:SHA1%%Digest%%generator
overwrite:showfiles.pl:/scripts/showfiles.pl:Directory%%viewer
overwrite:backdoorports.dat:/db/backdoorports.dat:Database%%Backdoor%%ports
overwrite:mirrors.dat:/db/mirrors.dat:Database%%Update%%mirrors
overwrite:os.dat:/db/os.dat:Database%%Operating%%Systems
overwrite:programs_bad.dat:/db/programs_bad.dat:Database%%Program%%versions
overwrite:programs_good.dat:/db/programs_good.dat:Database%%Program%%versions
overwrite:defaulthashes.dat:/db/defaulthashes.dat:Database%%Default%%file%%hashes
overwrite:md5blacklist.dat:/db/md5blacklist.dat:Database%%MD5%%blacklisted%%files
overwrite:CHANGELOG:/docs/CHANGELOG:Changelog
overwrite:README:/docs/README:Readme%%and%%FAQ
overwrite:WISHLIST:/docs/WISHLIST:Wishlist%%and%%TODO
"

# Prefix: INSTALLDIR
INSTALLFILES2="
nooverwrite:rkhunter.conf:/usr/local/etc/rkhunter.conf:RK%%Hunter%%configuration%%file
overwrite:rkhunter:/usr/local/bin/rkhunter:RK%%Hunter%%binary
"

# Create directories (only if they do not exist)
CREATEDIRS="
${INSTALLDIR}
${INSTALLDIR}/etc
${INSTALLDIR}/bin
${INSTALLDIR}/lib/rkhunter/db
${INSTALLDIR}/lib/rkhunter/docs
${INSTALLDIR}/lib/rkhunter/scripts
${INSTALLDIR}/lib/rkhunter/tmp
/usr/local/etc
/usr/local/bin
"

CHECKDIR="/usr/local"


# Functions
searchfile()
  {
    if [ "${PATH}" = "" ]
      then
        PATH="$PATH:/usr/bin:/usr/local/bin"
    fi
    
#    PATH=`echo ${PATH} | tr ':' ' '`
        
  }

language() {

case $1 in 
	fr)
	t1="Vérification "
	t2="Erreur fatale: "
	t2b="n'existe pas"
	t3="Vérification des outils..."
	t4="Erreur"
	t5="Erreur fatale: Impossible de trouver 'wget' ou 'fetch'"
	t6="Vérification des repertoires d'installation"
	t7="OK. (Utiliser "
	t8="- Vérification "
	t9="Existe"
	t10="Crée"
	t11="Vérification de la configuration système"
	t12="Echoué"
	t13="est introuvable. Créez un lien symbolique vers votre binaire perl"
	t14="Installation des fichiers"
	t15="Installation "
	t16="Echoué (impossible de trouver "
	t17="Installation terminée"
	t18="Voir ${INSTALLDIR}/lib/rkhunter/docs pour plus d'information. Lancez 'rkhunter'"
	t19="Installation echouée"
	;;


	de)
	t1="Prüfe "
	t2="Schwerer Fehler: "
	t2b="existiert nicht"
	t3="Suche Download-Tools..."
	t4="Fehler"
	t5="Schwerer Fehler: Kann 'wget' oder 'fetch' nicht finden"
	t6="Prüfe Installations-Verzeichnisse..."
	t7="OK. (Benutze "
	t8="- Prüfe "
	t9="Existiert"
	t10="Erzeugt"
	t11="Prüfe System-Einstellungen..."
	t12="Fehlgeschlagen"
	t13="nicht gefunden. Bitte erzeuge einen symbolic link zu deinem Perl Interpreter"
	t14="Installiere Dateien..."
	t15="Installiere "
	t16="Fehlgeschlagen (nicht auffindbar: "
	t17="Installation beendet."
	t18="Siehe ${INSTALLDIR}/lib/rkhunter/docs für weitere Informationen. Führe jetzt 'rkhunter' aus"
	t19="Installation fehlgeschlagen"
	;;

	en)
	t1="Checking "
	t2="Fatal error: "
	t2b="doesn't exists"
	t3="Checking file retrieval tools..."
	t4="Error"
	t5="Fatal error: Cannot find 'wget' or 'fetch'"
	t6="Checking installation directories..."
	t7="OK. (Using "
	t8="- Checking "
	t9="Exists"
	t10="Created"
	t11="Checking system settings..."
	t12="Failed"
	t13="cannot be found. Please create a symbolic link to your Perl binary"
	t14="Installing files..."
	t15="Installing "
	t16="Failed (cannot find "
	t17="Installation ready."
	t18="See ${INSTALLDIR}/lib/rkhunter/docs for more information. Run 'rkhunter'"
	t19="Install Failed"
	;;

	nl)
	t1="Bezig met controleren "
	t2="Fatale fout: "
	t2b="bestaat niet"
	t3="Bezig met controleren van download-hulpmiddelen..."
	t4="Fout"
	t5="Fatale fout: can 'wget' of 'fetch' niet vinden"
	t6="Bezig met het controleren van de installatiedirectories..."
	t7="OK. (Gebruiken van "
	t8="- Bezig met controleren "
	t9="Bestaat"
	t10="Aangemaakt"
	t11="Bezig met controleren van de systeeminstellingen..."
	t12="Faalde"
	t13="kan niet gevonden worden. Maak een symbolische link naar de Perl binary"
	t14="Bezig met het installeren van bestanden..."
	t15="Bezig met installeren "
	t16="Faalde (kan bestand niet vinden: "
	t17="Installatie afgerond."
	t18="Bekijk ${INSTALLDIR}/lib/rkhunter/docs voor meer informatie. Start 'rkhunter'"
	t19="Installatie faalde"
	;;

	sp)
	t1="Comprobación " 
 	t2="Error fatal: "
	t2b="no exista" 
  	t3="Comprobación de las herramientas ..." 
   	t4="Error" 
        t5="Error fatal: Imposible de encontrar 'wget' ou 'fetch'" 
        t6="Comprobación directorios  de instalación " 
        t7="OK. (Utilisar " 
        t8="- Comprobación " 
        t9="Exista" 
       t10="Crea" 
       t11="Comprobación de la configuración sistema" 
       t12="Fallado" 
       t13="no encontrado. Crear un vínculo simbólico hacia vuestro binario perl" 
       t14="Instalación de los ficheros " 
       t15="Instalación " 
       t16="Fallado (imposible de encontrar " 
       t17="Instalación terminada" 
       t18="Ver ${INSTALLDIR}/lib/rkhunter/docs para más información . Lanzar 'rkhunter'"
       t19="Instalación Fallado"
       ;;

       se)
        t1="kollar "
        t2="allvarligt fel: "
        t2b="finns inte"
        t3="undersöker fil hämtnings verktyg ..."
        t4="fel"
        t5="Allvarligt fel: kan inte hitta 'wget' eller 'fetch'"
        t6="kollar installations katalogen..."
        t7="OK. (använder "
        t8="- kollar "
        t9="finns"
        t10="skapad"
        t11="kollar system inställningar..."
        t12="avbruten"
        t13="kan inte hittas. skapa en symlänk till Perl binären"
        t14="Installerar filer..."
        t15="Installerar "
        t16="Misslyckades (kan inte hitta "
        t17="Installation är klar."
        t18="kolla på ${INSTALLDIR}/lib/rkhunter/docs för mer information. kör 'rkhunter'"
        t19="Installtionen misslyckades"
        ;;

	# Portugues Brazilian
        ptbr)
        t1="Checando "
        t2="Fatal error: "
        t2b="nÃ£o existe"
        t3="Verificando arquivos de ferramentas"
        t4="Erro!"
        t5="Fatal error: Impossivel encontrar 'wget' ou 'fetch'"
        t6="Verificando diretorios da instalaÃ§Ã£o..."
        t7="OK. (Usando "
        t8="- Checando "
        t9="Existe"
        t10="Criado"
        t11="Verificando configuraÃ§Ã£o do sistema..."
        t12="Falhou"
        t13="impossivel encontrar. Por favor, crie um link simbolico para seus arquivos Perl binario"
        t14="Instalando arquivos..."
        t15="Instalando "
        t16="Falhou (impossivel encontrar "
        t17="InstalaÃ§Ã£o Concluida."
        t18="Leia a documentaÃ§Ã£o em /usr/local/rkhunter/docs para maiores informaÃ§Ãµes. Digite 'rkhunter' para executar o rootkit"
        t19="Falha na InstalaÃ§Ã£o"
        ;;

	# Turkish
	tr)
	t1="inceleniyor "
	t2="Fatal error: "
	t2b="mevcut degil"
	t3="Dosya yukleme araci kontrol ediliyor..."
	t4="Hata"
	t5="Fatal error: 'wget' veya 'fetch' araclarindan biri bulunamadi"
	t6="Kurulum dizinleri kontrol ediliyor..."
	t7="OK. (Kullaniliyor "
	t8="- inceleniyor "
	t9="Mevcut"
	t10="Olusturuldu"
	t11="Sistem ayarlari kontrol ediliyor..."
	t12="Basarisiz"
	t13="Bulunamadi. Lutfen Perl icin sembolink baglanti olusturun."
	t14="Dosyalar kuruluyor..."
	t15="Kuruluyor "
	t16="Basarisiz (bulunamadi "
	t17="Kurulum hazir."
	t18="Daha fazla bilgi icin ${INSTALLDIR}/lib/rkhunter/docs . Sistemde Rootkit taramasi yapmak icin 'rkhunter' yazin"
	t19="Kurulum basarisiz"
	;;
esac
}

if [ -f ~/.rkhunterlng ]
  then
    lng=`cat ~/.rkhunterlng`
    case $lng in
        "en") rep="ok";;
        "fr") rep="ok";;
	"nl") rep="ok";;
	"se") rep="ok";;
        "sp") rep="ok";;
	*) echo "Language not supported"
              rm -f ~/.rkhunterlng
              exit 1 ;;
    esac
  else
    lng="en"
fi     

#     rep="nok"
#     while [ "$rep" = "nok" ]
#     do
#     	echo $N "Language file not detected, which language do you want to use (de/en/fr/nl/se/sp/ptbr/tr) ?"
#     	read lng
#             case $lng in
#	            "de") rep="ok";;
#	            "en") rep="ok";;
#                   "fr") rep="ok";;
#		    "nl") rep="ok";;
#		    "se") rep="ok";;
#	            "sp") rep="ok";;   
#	            "ptbr") rep="ok";;   
#	            "tr") rep="ok";;   
#		       *) echo "Language not supported";;
#	     esac
#     done
#  	touch ~/.rkhunterlng
#   	echo $lng > ~/.rkhunterlng


language $lng
																	
#################################################################################
#
# Start installation
#
#################################################################################


# Clean active window
clear

echo "${INSTALLER_NAME} ${INSTALLER_VERSION} (${INSTALLER_COPYRIGHT})"
echo $ECHOOPT "---------------"
echo "Starting installation/update"
echo ""

# Temporarily disabled
#echo $N "Checking UID... "
#if [ `id -u` = "0" ]
#  then
#    echo "OK"
#  else
#    echo "Sorry, you have to be 'root'. Please su(do) and try again"
#    exit 1
#fi

echo $N "$t1 ${CHECKDIR}..."
if [ -d ${CHECKDIR} ]
  then
    echo $E " OK"
  else
    echo "$t2 ${CHECKDIR} $t2b"
    exit 1
fi

echo $N "$t3 "
SEARCH=`which wget 2>/dev/null`

if [ "${SEARCH}" = "" ]
  then
    SEARCH=`which fetch 2>/dev/null`
    if [ "${SEARCH}" = "" ]
      then
	SEARCH=`which curl 2>/dev/null`
          if [ "${SEARCH}" = "" ]	
	    then
	      echo $E "${t4}"
	      echo "$t5"
	    else
    	      RETRTOOL=${SEARCH}
	  fi
      else
        RETRTOOL=${SEARCH}
    fi
else
    RETRTOOL=${SEARCH}
fi


echo ${RETRTOOL}

echo $ECHOOPT "$t6"
for I in ${CREATEDIRS}; do
  echo $N $ECHOOPT "$t8${I}..."
  if [ -d ${I} ]
    then
      echo $E "$t9"
    else
      echo $E "$t10"
      # Create directory
      mkdir -p ${I}
  fi
done

echo $ECHOOPT "$t11"
echo $N "    - Perl... "
if [ ! -f /usr/bin/perl ]
  then
    echo $E  "$t12"
    echo ""
    echo $ECHOOPT "----------------------------------------------------------------------------------"
    echo "/usr/bin/perl $t13"
    echo "ie. ln -s <path_to>/perl /usr/bin/perl"
    echo $ECHOOPT "----------------------------------------------------------------------------------"
  else
    echo $E "OK"
fi


echo "$t14 "

# Install with prefix and /lib/rkhunter
for I in ${INSTALLFILES}; do
  
  INSTALLTYPE=`echo ${I} | cut -d ':' -f1`
  CURFILE=`echo ${I} | cut -d ':' -f2`
  NEWFILE=`echo ${I} | cut -d ':' -f3`
  DESCRIPTION=`echo ${I} | cut -d ':' -f4 | tr -s '%%' ' '`

  echo $N "$t15${DESCRIPTION}... "

      #error redirection in .rkhunter it's just for a clear display if user run not as root
      cp -f ${INSTALLPREFIX}${CURFILE} "${INSTALLDIR}/lib/rkhunter${NEWFILE}"
      # Redirect logging to logfile: 2> ./rkhunter.log
      if [ $? -eq 0 ]
        then
	  echo $E "OK"
	  INSTALL="ok"
	else
	  echo $E "$t12 "
	  INSTALL="nok"
      fi
 
done

# Install just with prefix
for I in ${INSTALLFILES2}; do
  
  INSTALLTYPE=`echo ${I} | cut -d ':' -f1`
  CURFILE=`echo ${I} | cut -d ':' -f2`
  NEWFILE=`echo ${I} | cut -d ':' -f3`
  DESCRIPTION=`echo ${I} | cut -d ':' -f4 | tr -s '%%' ' '`

  echo $N "$t15${DESCRIPTION}... "
  # Does the file already exists and are we using the no-overwrite mode?
  if [ -f ${NEWFILE} -a ${INSTALLTYPE} = "nooverwrite" ]
    then
      echo "Skipped (no overwrite)"
    else
      #error redirection in .rkhunter it's just for a clear display if user run not as root
      cp -f ${INSTALLPREFIX}${CURFILE} ${NEWFILE}
      # Redirect logging to logfile: 2> ./rkhunter.log
      if [ $? -eq 0 ]
        then
	  echo $E "OK"
	  INSTALL="ok"
	else
	  echo $E "$t12 "
	  INSTALL="nok"
      fi
  fi
 
done

# Installation dir to configuration file
INSTALLDIRCHECK=`cat /usr/local/etc/rkhunter.conf | grep "INSTALLDIR="`
if [ "${INSTALLDIRCHECK}" = "" ]
  then
    echo "" >> /usr/local/etc/rkhunter.conf
    echo "INSTALLDIR=${INSTALLDIR}" >> /usr/local/etc/rkhunter.conf
    echo "Configuration updated with installation path (${INSTALLDIR})"
  else
    echo "Configuration already updated."
fi

if [ ! ${INSTALL} = "nok" ]
then
	echo ""
	echo $E "$t17"
	echo "$t18 (/usr/local/bin/rkhunter)"
else
	echo ""
	echo $E "$t19"
	echo "Check ./.rkhunter.log"
fi

# The End
