#!/usr/bin/perl -w
use File::stat qw/:FIELDS/;
#=head1 NAME
#stat - display information about a file
#=head1 SYNOPSIS
#stat [--follow] [--octal] [--raw] [--<key>] file
#=head1 DESCRIPTION
#stat prints information about a file:
#         dev      device number of filesystem
#         ino      inode number
#         mode     file mode  (type and permissions)
#         nlink    number of (hard) links to the file
#         uid      numeric user ID of file's owner
#         gid      numeric group ID of file's owner
#         rdev     the device identifier (special files only)
#         size     total size of file, in bytes
#         atime    last access time since the epoch
#         mtime    last modify time since the epoch
#         ctime    inode change time (NOT creation time!) since the epoch
#         Atime    last access time in YYYYMMDDhhmmss format
#         Mtime    last modify time in YYYYMMDDhhmmss format
#         Ctime    inode change time in YYYYMMDDhhmmss format
#         blksize  preferred block size for file system I/O
#         blocks   actual number of blocks allocated
#
#Each of the keys in the first column above may be used as an option. Only that
#information will then be printed for the file. More than one key option can be
#used. If no key options are used, all information will be printed, one line
#per key, in the format key<tab>value.
#
#For links the --follow option may be used to follow the link, i.e. to print the
#information for the file at the end of the link.
#The --octal prints numbers (excluding the time keys) in octal.
#The --raw option just prints out the value, and not the key name. If more than
# one key is used, they are space separated.
#=head1 AUTHOR
#wybo@servalys.nl
#=cut
use Getopt::Long;
use vars qw /$opt_octal $opt_follow $opt_raw/;

@h=qw/ dev ino mode nlink
       uid gid rdev size
       atime mtime ctime 
       Atime Mtime Ctime
       blksize blocks
/;
@h2=();
Getopt::Long::Configure(no_ignore_case);
GetOptions(@h,'follow','octal','raw');

for (@h) {
  $o="opt_$_";
  $$o and push @h2,$_;
}

@h2=@h if (@h2 < 1);

$file=shift or die "Usage: stat file\n";
-e $file or die "File $file does not exist\n";
if ($opt_follow) { stat $file } else { lstat $file }
for (@h2) {
  if (/^[AMC]/) {
    $v="st_\l$_";
    $v=conv($$v);
  } else {
    $v="st_$_";
    $v=$$v;
  }
  $opt_octal && ! /time/ and ($v=sprintf("0%o",$v))=~s/^00/0/;
  if (@h2>1 && ! $opt_raw) { write } else { print "$v " }
}

print "\n" if ($opt_raw);

format = 
@>>>>> @<<<<<<<<<<<<<  @<<<<<<<<<<<<<
$_,      $v,            '' # $link ? $y : ''    
.

sub conv {
  my $t=shift;
  my @s=(localtime($t))[0..5];
  $s[4]++;
  $s[5]+=1900;
  sprintf("%04d%02d%02d%02d%02d%02d",reverse @s);
}
