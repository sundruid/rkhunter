#!/usr/bin/perl
#
#  Hashes files (MD5)
#

use Digest::MD5;

# Open file in binary mode
my $file = $ARGV[0];
open(FILE, $file) or die "Sorry. Can't open '$file'";
binmode(FILE);

$md5  = Digest::MD5->new;

# Hash file contents
while (<FILE>) {
   $md5->add($_);
}
close(FILE);

print $md5->hexdigest,"\n";
