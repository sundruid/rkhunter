#!/usr/bin/perl -w
use strict;

use IO::Socket;

my ( $peer, $port );

$peer = $ARGV[0];

my $i = 0;
my $sock = 0;
my $sock2 = 0;


for ($i=0; $i<5000; $i++)
  {
    $port = $i;
    $sock = IO::Socket::INET->new("$peer:$port");
#    $sock2 = 'Net::UDP'->new($peer,$port);
    
    if ($sock)
      {
        print "Port ",$port,"\n";
        # Close socket 
#	close($sock);
      }
     

    
#    if ($sock2)
#      {
#        print "UDPPort ",$port,"\n";
#      }

  }
exit;

