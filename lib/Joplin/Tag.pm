#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Tag;

use parent qw(Joplin::Base);

=head1 METHODS

=head2 get_notes

Gets the notes with this tag.

    $res = $folder->get_notes;

Returns an array with Joplin::Note objects.

=cut

sub get_notes {
    my ( $self ) = @_;
    my @res = map { Joplin::Note->_wrap( $_, $self->api ) }
      @{ $self->api->get_tag_notes( $self->id ) };
    wantarray ? @res : \@res;
}

=head2 find_notes

Finds notes by name or pattern having this tag.

    $res = $tag->find_notes($pat);

Returns an array with Joplin::Note objects.

=cut

sub find_notes {
    my ( $self, $pat ) = @_;
    my @res = map { Joplin::Note->_wrap( $_, $self->api ) }
      @{ $self->api->find_selected( "tag_notes", $pat,
				     $self->api->get_tag_noets( $self->id )
				   ) };
    wantarray ? @res : \@res;
}



################ Initialisation ################

BEGIN {
    my $rw =
      [ qw( id title user_created_time user_updated_time ) ];
    my $ro =
      [ qw( created_time updated_time
	    encryption_cipher_text encryption_applied ) ];

    __PACKAGE__->_set_property_handlers($rw, $ro);
}

1;
