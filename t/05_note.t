#! perl

# Testing note update.

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
    my $nid = $api->create_note( $nname,
				 "Hi from testing",
				 $fid,
			       );
    $nid = $nid->{id};

    $res = $api->update_note( $nid,
			      title => "♫ ♫ ♫",
			      body => "Updated content",
			    );
    ok( $res, "Update note" );
    is( $res->{body}, "Updated content", "Update note contents" );

    $res = $api->find_notes( qr/^♫ ♫ ♫$/ );
    is( $res->[0]->{id}, $nid, "Found the note" );

    $res = $api->get_note($nid);
    is( $res->{body}, "Updated content", "Updated note contents" );

    $api->delete_note($nid);
    $api->delete_folder($fid);
}

done_testing();
