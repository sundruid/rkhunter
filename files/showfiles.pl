#!/usr/bin/perl

# List all files in a directory

my $viewdir = $ARGV[0];

if ($viewdir ne "")
  {
    opendir(DIR,$viewdir) || die "Can't open directory";
    @filenames = readdir(DIR);
    closedir(DIR);

    foreach $file (@filenames)
      {
	if ($file ne "." && $file ne "..")
	  {
	    if(substr($file,0,1) eq ".")
	      {
	        print $viewdir,"/",$file,"\n";
	      }
	  }
      }
  }
