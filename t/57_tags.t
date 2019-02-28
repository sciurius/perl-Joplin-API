#! perl

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
    my $fn = $sf->create_note( "TestNote$$", "Some *markdown* content.");

    my @res = $root->find_tags("TestTag$$");
    is( scalar(@res), 0, "No test tag" );

    my $t = $fn->add_tag("TestTag$$");
    ok( $t, "Added tag" );
    @res = $root->find_tags("TestTag$$");
    is( scalar(@res), 1, "Got test tag" );
    is( $res[0]->id, $t->id, "Verified tag" );
    ok( $fn->delete_tag($t), "Delete tag from note" );
    ok( $fn->delete, "Delete test note" );
    ok( $sf->delete, "Delete test folder" );
}

done_testing();
