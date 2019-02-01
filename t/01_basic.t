#! perl

# Testing API setup and server connection.

use strict;
use warnings;
use Test::More tests => 4;
use Joplin::API;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";
ok( $init{token}, "We have a token" );

my $api = Joplin::API->new( %init, debug => 0 );
ok( $api, "Got API instance" );

diag("Testing Joplin server " . $api->get_server . "\n");

SKIP: {
    my $res = $api->ping;
    skip "Server is not running", 2 unless $res;
    pass("Server is running");
    is( $res, "JoplinClipperServer", "It's Joplin, jay!" );
}


