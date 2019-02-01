#! perl

# Testing CRUD on tags.

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

    my $tname = "TestTag$$";
    my $tid = $api->create_tag($tname);
    ok( $tid, "Create tag $tname" );
    $tid = $tid->{id};

    $res = $api->find_tags( qr/^$tname$/i );
    ok( $res, "Found " . scalar(@$res) . " tags" );
    is( $res->[0]->{id}, $tid, "Found tag $tname" );
    is( $res->[0]->{title}, lc($tname), "It's $tname" );

    $res = $api->update_tag( $tid, "XX$tname" );
    ok( $res, "Updated tag" );
    is( $res->{id}, $tid, "Found tag" );

    $tname = "XX$tname";
    $res = $api->find_tags( qr/^$tname$/i ) // [];
    ok( $res, "Found " . scalar(@$res) . " tags" );
    is( $res->[0]->{id}, $tid, "Found tag $tname" );
    is( $res->[0]->{title}, lc($tname), "It's $tname" );

    ok( $api->delete_tag($tid), "Delete tag" );
}

done_testing();
