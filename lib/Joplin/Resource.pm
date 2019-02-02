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

BEGIN {
    @PROPERTIES =
      qw( id title mime filename created_time updated_time
	  user_created_time user_updated_time
	  file_extension encryption_cipher_text
	  encryption_applied encryption_blob_encrypted );

    __PACKAGE__->_set_property_handlers(\@PROPERTIES);
}

1;
