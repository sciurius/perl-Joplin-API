#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Resource;

use parent qw(Joplin::Base);


################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
