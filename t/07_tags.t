#! perl

# Testing adding and removing tags from notes.

use strict;
use warnings;
use Test::More;
use Joplin::API;

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
    my $nid = $api->create_note( $nname, "Hi from testing", $fid,);
    $nid = $nid->{id};

    my $tname = "TestTag$$";
    my $tid = $api->create_tag($tname);
    ok( $tid, "Create tag $tname" );
    $tid = $tid->{id};

    $res = $api->create_tag_note( $tid, $nid );
    ok( $res, "Link tag to note" );

    $res = $api->get_tag_notes($tid);
    ok( $res, "Got note for tag" );
    is( $res->[0]->{id}, $nid, "Got the right note for tag" );

    $res = $api->get_note_tags($nid);
    ok( $res, "Found " . scalar(@$res) . " tags" );
    is( $res->[0]->{id}, $tid, "Found tag $tname" );
    is( $res->[0]->{title}, lc($tname), "It's $tname" );

    ok( $api->delete_tag_note($tid, $nid), "Unlink tag" );
    ok( $api->delete_tag($tid), "Delete tag" );

    # These have been tested before.
    $api->delete_note($nid);
    $api->delete_folder($fid);
}

done_testing();
