#! perl

# Testing folder creation and deletion.

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

    $res = $api->get_folders;
    my $nfolders = scalar(@$res);
    ok( $res, "Got $nfolders folders" );

    my $fname = "TestFolder$$";
    my $fid = $api->create_folder($fname);
    ok( $fid, "Create folder $fname" );
    $fid = $fid->{id};

    $res = $api->get_folders;
    is( scalar(@$res), 1+$nfolders, "Got " . scalar(@$res) . " folders" );

    $res = $api->get_folder($fid);
    is( $res->{id}, $fid, "Found folder" );

    $res = $api->find_folders($fname);
    ok( $res, "Found " . scalar(@$res) . " folders" );
    is( $res->[0]->{id}, $fid, "Found folder $fname" );
    ok( $api->delete_folder($fid), "Delete folder $fname" );

    $res = $api->get_folders;
    is( scalar(@$res), $nfolders, "Got " . scalar(@$res) . " folders" );
}

done_testing();
