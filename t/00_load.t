#! perl

use strict;
use warnings;
use Test::More tests => 1;
require_ok( "Joplin::API" );

diag("Testing Joplin::API version $Joplin::API::VERSION with perl $^V\n");
