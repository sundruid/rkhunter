#!/usr/bin/perl

use Digest::MD5;
use Digest::SHA1;

my $i=0;
# Open file in binary mode
my $file = $ARGV[0];
open(FILE, $file) or die "Sorry. Can't open '$file'";
binmode(FILE);

$sha1 = Digest::SHA1->new;
$md5 = Digest::MD5->new;

# File size
my $filesize = -s $file;

# Hash file contents
while (<FILE>) {
   $sha1->add($_);
   $md5->add($_);   
   $i++;
}
close(FILE);

print "OSNUMBER:",$file,":",$md5->hexdigest,":",$sha1->hexdigest,":",$filesize,":-:\n";

