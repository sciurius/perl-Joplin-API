#! perl

use strict;
use warnings;
use Test::More tests => 3;
use Joplin::API;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";
ok( $init{token}, "We have a token" );

my $jj = Joplin::API->new( %init, debug => 0 );
ok( $jj, "Got API instance" );

diag("Testing Joplin server " . $jj->get_server . "\n");

SKIP: {
    skip "Server is not running", 1 unless $jj->ping;
    pass("Server is running");
}


