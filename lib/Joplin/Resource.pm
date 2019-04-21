#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Resource;

use parent qw(Joplin::Base);

# To attach a resource to a note, first create the resource with POST
# /resources, then get the ID from there and simply add the resource
# to the body of the note with the syntax
# [](:/12345678123456781234567812345678).

################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
