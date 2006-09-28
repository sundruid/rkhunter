#!/usr/bin/perl

use Digest::SHA1;

# Open file in binary mode
my $file = $ARGV[0];
open(FILE, $file) or die "Sorry. Can't open '$file'";
binmode(FILE);


$sha1 = Digest::SHA1->new;

# Hash file contents
while (<FILE>) {
   $sha1->add($_);
}
close(FILE);

print $sha1->hexdigest,"\n";
