#! perl

# Testing API setup and server connection.

use strict;
use warnings;
use Test::More tests => 4;
use Joplin;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";
ok( $init{token}, "We have a token" );

my $root = Joplin->connect( %init );
ok( $root, "Got Root Folder instance" );

diag("Testing Joplin server " . $root->api->get_server . "\n");

SKIP: {
    my $res = $root->ping;
    skip "Server is not running", 2 unless $res;
    pass("Server is running");
    is( $res, "JoplinClipperServer", "It's Joplin, jay!" );
}


