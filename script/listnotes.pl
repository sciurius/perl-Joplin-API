#!/usr/bin/perl -w

# List notes, hierarchically.

# Author          : Johan Vromans
# Created On      : Fri Mar  8 09:39:46 2019
# Last Modified By: Johan Vromans
# Last Modified On: Sun Mar 10 20:43:58 2019
# Update Count    : 44
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
my ($my_name, $my_version) = qw( listnotes 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $title;
my $server = "http://127.0.0.1:41184";
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

################ The Process ################

my $root = Joplin->connect( server => $server, apikey => $token );

my $top = [ $root ];

if ( $title ) {
    if ( $title =~ m;^/(.?)/?$; ) {
	$title = qr/$1/i;
    }
    else {
	$title = qr/^$title$/;
    }
    $top = $root->find_folders($title);
    die("No folders found\n") unless @$top;
}

listnotes($_) for @$top;

################ Subroutines ################

sub listnotes {
    my ( $top, $indent ) = @_;
    die unless $top->isa('Joplin::Folder');
    $indent //= "";

    my ( @all ) =
      sort
      { $a->title cmp $b->title }
      ( @{$top->find_folders},
	@{$top->find_notes} );

    foreach my $item ( @all ) {
	my $t = "";
	$t = $item->id . " " if $verbose > 1;
	if ( ref($item) eq 'Joplin::Folder' ) {
	    print( $indent, $t, $item, "\n" );
	    listnotes( $item, $indent . "  " );
	}
	elsif ( ref($item) eq 'Joplin::Note' ) {
	    print( $indent, $t, $item,
		   " (" . $item->iso8601date($item->updated_time) . ")\n" );
	}
	else {
	    print("??? $item\n");
	    use DDumper; DDumper($item); exit;
	}
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
   --title=XXX		select starting folder(s) by title
   --server=XXX		the host running the Joplin server
   --token=XXX		Joplin server access token
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

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item B<--quiet>

Runs quietly.

=back

=head1 DESCRIPTION

B<This program> will list titles of Joplin notes hierarchically.

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
