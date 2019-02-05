#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Resource;

use parent qw(Joplin::Base);

our $TYPE = 4;			# node type
our @PROPERTIES;		# node properties



################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
