#! perl

# Testing note creation and deletion.

use strict;
use warnings;
use Test::More;
use Joplin::API;
use utf8;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";

my $api = Joplin::API->new( %init, debug => 0 );
my $res;

SKIP: {
    skip "Server is not running" unless $api->ping;

    my $fname = "TestFolder$$";
    my $fid = $api->create_folder($fname);
    $fid = $fid->{id};

    my $nname = "TestNote$$";
    my $nid = $api->create_note( $nname,
				 "♫ Hi from testing ♬",
				 $fid,
			       );
    $nid = $nid->{id};
    ok( $nid, "Created note $nname" );

    $res = $api->find_notes( qr/^$nname$/ );
    is( $res->[0]->{id}, $nid, "Found the note" );

    $res = $api->get_folder_notes($fid);
    is( $res->[0]->{id}, $nid, "Found the note" );

    ok( $api->delete_note($nid),   "Delete note $nname" );

    $api->delete_folder($fid);
}

done_testing();
