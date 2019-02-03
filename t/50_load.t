#! perl

use strict;
use warnings;

my @mods;

BEGIN { @mods = qw( Base Folder Note Resource Tag ) }

use Test::More tests => 1 + @mods;

require_ok( "Joplin" );

require_ok( "Joplin::$_" ) for @mods;

diag("Testing Joplin version $Joplin::VERSION with perl $^V\n");
