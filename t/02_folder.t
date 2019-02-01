#! perl

use strict;
use warnings;
use Test::More;
use Joplin::API;

-d "t" && chdir("t");

# Get credentials.
our %init;
-s "./joplin.dat" && do "./joplin.dat";

my $jj = Joplin::API->new( %init, debug => 0 );
my $res;

SKIP: {
    skip "Server is not running" unless $jj->ping;

    $res = $jj->get_folders;
    my $nfolders = scalar(@$res);
    ok( $res, "Got $nfolders folders" );

    my $fid = $jj->create_folder("TestFolder$$");
    ok( $fid, "Create folder " . $fid->{id} );
    $fid = $fid->{id};

    $res = $jj->get_folders;
    is( scalar(@$res), 1+$nfolders, "Got " . scalar(@$res) . " folders" );

    ok( $jj->delete_folder($fid), "Delete folder $fid" );

    $res = $jj->get_folders;
    is( scalar(@$res), $nfolders, "Got " . scalar(@$res) . " folders" );
}

done_testing();
