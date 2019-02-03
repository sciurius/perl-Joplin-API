#! perl

# Testing API setup and server connection.

use strict;
use warnings;
use Test::More;
use Joplin;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";

# Connect to server.
my $root = Joplin->connect( %init );

SKIP: {
    my $res = $root->ping;
    skip "Server is not running" unless $res;

    my $sf = $root->create_folder("TestFolder$$");
    ok( $sf, "Create test folder" );

    my $ssf = $sf->create_folder("TestSubFolder$$");
    ok( $sf, "Create test subfolder" );

    $ssf->title("TestXXSubFolder$$");
    $res = $ssf->update;
    ok( $res && $res->{title} eq "TestXXSubFolder$$",
	"Renamed subfolder" );

    my $fn = $ssf->create_note( "TestNote$$", "Some *markdown* content.");
    ok( $fn, "Create test note in subfolder" );

    ok( $fn->delete, "Delete test note" );

    my $n = folders();
    ok( $ssf->delete, "Delete test subfolder" );
    is( $n-1, folders(), "One down, one to go" );
    ok( $sf->delete, "Delete test folder" );
    is( $n-2, folders(), "Two down" );
}

done_testing();

sub folders {
    scalar( @{ $root->find_folders(qr/./) } );
}
