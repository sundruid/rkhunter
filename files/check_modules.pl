#!/usr/bin/perl -w

#################################################################################
#
# Perl module checker 0.0.2
#
#################################################################################
#
# This Perl script checks for installed modules, by try
# to use the module. If the check fails, the module is not installed.
#
# If you want to install additional modules, use:
# > perl -MCPAN -e shell
# > install [module name]
#
# If the first one fails, please install the perl-CPAN package first
#
# Upgrade CPAN if possible:
# > install Bundle::CPAN
# > reload cpan
#
# Digest modules:
# > install Digest::MD5
# > install Digest::SHA1
#

#################################################################################

use strict;

my $check = "0";

# Modules to check
my @modCheck = qw(
Digest::MD5
Digest::SHA1
);

for (@modCheck)
  {
    if (installed("$_"))
      {
        print "$_ installed (version ",$check,").\n"
      }
     else
      {
        print "$_ NOT installed.\n"
      }
  }

#########################################
#
# SUB: Installed modules
#
#########################################

sub installed
  {

    my $module = $_;

    # Try to use the Perl module
    eval "use $module";

    # Check eval response
    if ($@)
      {
        # Module is NOT installed
        $check = 0;
      }
     else
      {
        # Module is installed (reset module version to '1')
	$check = 1;
	
        my $version = 0;
	# Try to retrieve version number (by using eval again)
        eval "\$version = \$$module\::VERSION";
	
	# Set version number if no problem occured
        $check = $version if (!$@);
      }
      
    # Return version number
    return $check;
}


exit();

# The end
