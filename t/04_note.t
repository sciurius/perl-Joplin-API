#! perl

# Testing note creation with tags, and deletion of tags and note.

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
    diag("Created folder $fname");

    my $nid = $api->create_note( "TestNote$$",
				 "Hi from testing",
				 $fid,
				 tags => "ttag2,ttag1",
			       );
    $nid = $nid->{id};
    ok( $nid, "Create note" );

    my $tags = $api->get_note_tags($nid);
    is( @$tags, 2, "Got " . scalar(@$tags) . " tags" );

    for ( @$tags ) {
	ok( $api->delete_tag($_->{id}), "Delete tag $_->{title}" );
    }

    ok( $api->delete_note($nid),   "Delete note" );

    $api->delete_folder($fid);
    diag("Deleted folder $fname");
}

done_testing();
