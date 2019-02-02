#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Tag;

use parent qw(Joplin::Base);

our $TYPE = 5;			# node type
our @PROPERTIES;		# node properties



################ Initialisation ################

BEGIN {
    @PROPERTIES =
      qw( id title created_time updated_time
	  user_created_time user_updated_time
	  encryption_cipher_text encryption_applied );

    __PACKAGE__->_set_property_handlers(\@PROPERTIES);
}

1;
