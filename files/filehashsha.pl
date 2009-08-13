#!/usr/bin/perl

die "Usage: $0 <module number> <SHA size> <filename>" if ($#ARGV != 2);

my $sha = '';

my $mod = $ARGV[0];
my $size = $ARGV[1];
my $file = $ARGV[2];

# Open file in binary mode
open(FILE, $file) or die "Can't open file '$file'";
binmode(FILE);

if ($mod eq '1') {
	use Digest::SHA1;
	$sha = Digest::SHA1 -> new;
}
elsif ($mod eq '256') {
	use Digest::SHA256;
	$sha = Digest::SHA256::new($size);
}
else {
	use Digest::SHA::PurePerl;
	$sha = Digest::SHA::PurePerl -> new($size);
}

# Hash file contents
while (<FILE>) {
	$sha -> add($_);
}

close(FILE);

$_ = $sha -> hexdigest;
s/ //g;
print $_, "\n";
