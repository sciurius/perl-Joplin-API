#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Note;

use parent qw(Joplin::Base);

our $TYPE = 1;			# node type
our @PROPERTIES;		# node properties

################ Initialisation ################

BEGIN {
    @PROPERTIES =
      qw( id parent_id title body created_time updated_time is_conflict
	  latitude longitude altitude author source_url is_todo todo_due
	  todo_completed source source_application application_data
	  order user_created_time user_updated_time encryption_cipher_text
	  encryption_applied body_html base_url image_data_url crop_rect );

    __PACKAGE__->_set_property_handlers(\@PROPERTIES);
}

1;
