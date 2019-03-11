#!/usr/bin/perl -w

# List tags.

# Author          : Johan Vromans
# Created On      : Mon Mar 11 13:38:34 2019
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar 11 14:23:08 2019
# Update Count    : 20
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Encode;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Joplin;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( listtags 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $title;
my $server = "http://127.0.0.1:41184";
my $weed = 0;			# remove unused tags
my $showid = 0;
my $verbose = 1;		# verbose processing

# Run Joplin and copy the token from the Web Clipper options page.
my $token = $ENV{JOPLIN_APIKEY} // "YOUR TOKEN GOES HERE";

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

binmode( STDOUT, ":utf8" );

if ( $title ) {
    if ( $title =~ m;^/(.?)/?$; ) {
	$title = qr/$1/i;
    }
    else {
	$title = qr/^$title$/;
    }
}

################ The Process ################

my $root = Joplin->connect( server => $server, apikey => $token );

$root->api->set_debug(1) if $debug;

my @tags = sort { $a->title cmp $b->title } @{ $root->find_tags($title) };

listtags($_) for @tags;

################ Subroutines ################

sub listtags {
    my ( $tag ) = @_;
    die unless $tag->isa('Joplin::Tag');

    my @notes = @{ $tag->find_notes };
    print( $tag->id, "  " ) if $showid;
    print( $tag->title );
    if ( @notes ) {
	print( " (", scalar(@notes), " note", @notes == 1 ? "" : "s", ")");
    }
    elsif ( $weed ) {
	eval { $tag->delete; print( " (deleted)\n") }
	  and return;
	my $msg = $@;
	$msg =~ s/Joplin::API/delete/;
	$msg =~ s/ at .*$//s;
	print( "  ($msg)");
    }
    else {
	print( " (unused)");
    }
    print("\n");

    return unless $verbose > 1;

    @notes =  sort { $a->title cmp $b->title } @notes;
    foreach my $n ( @notes ) {
	print( $n->id, "  " ) if $showid;
	print( "  ", $n->title, "\n" );
    }
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions('title=s'	=> sub { $title  = decode_utf8($_[1]) },
		   'server=s'	=> sub { $server = decode_utf8($_[1]) },
		   'token=s'	=> \$token,
		   'weed'	=> \$weed,
		   'showid'	=> \$showid,
		   'ident'	=> \$ident,
		   'verbose+'	=> \$verbose,
		   'quiet'	=> sub { $verbose = 0 },
		   'trace'	=> \$trace,
		   'help|?'	=> \$help,
		   'man'	=> \$man,
		   'debug'	=> \$debug)
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

__END__

################ Documentation ################

=head1 NAME

listnotes - list note titles hierarchically

=head1 SYNOPSIS

exportnote [options]

 Options:
   --title=XXX		selects tags by title
   --server=XXX		the host running the Joplin server
   --token=XXX		Joplin server access token
   --weed		removes unused tags
   --ident		shows identification
   --quiet		runs quietly
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information

=head1 OPTIONS

=over 8

=item B<--server=>I<NNN>

The host where the Joplin server is running.
Default is C<http://127.0.0.1:41184>.

=item B<--token=>I<XXX>

Access token for Joplin. You can find it on the Web Clipper options page.

=item B<--title=>I<XXX>

If specified, selects one or more folders to start listing.

=item B<--weed>

Removes unused tags.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information. In particular, show note titles for
each tag with notes.

=item B<--quiet>

Runs quietly.

=back

=head1 DESCRIPTION

B<This program> will list titles of all Joplin tags, and the number of
notes associated with each tag.

Optionally, removes unused tags.

=head1 AUTHOR

Johan Vromans C<< <sciurius at github dot com > >>

=head1 SUPPORT

Joplin-Tools development is hosted on GitHub, repository
L<https://github.com/sciurius/Joplin-Tools>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/sciurius/Joplin-Tools/issues>.

=head1 LICENSE

Copyright (C) 2019 Johan Vromans,

This program is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
