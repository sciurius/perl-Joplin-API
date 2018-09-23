#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Mon Sep 17 10:45:33 2018
# Last Modified By: Johan Vromans
# Last Modified On: Sun Sep 23 17:22:31 2018
# Update Count    : 51
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Encode;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( picklist 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $dir = "/home/jv/Cloud/ownCloud/Notes/Joplin";
my $title;
my $output;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

my $id;
if ( $output ) {
    ( $id ) = $output =~ m;(?:^|/)([0-9a-f]{32})\.md$;;
    die("Invalid output name: $output\n") unless $id;
}
else {
    $id = uuid();
}

my @tm = gmtime;
my $ts = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );

my $data = do { local $/; <> };
$data = decode_utf8($data);

$data =~ s/^(id: ).*/$1$id/m;
$data =~ s/^(source: ).*/${1}joplin-$my_name/m;
$data =~ s/^(source_application: ).*/${1}nl.squirrel.joplin-$my_name/m;
$data =~ s/^((?:user_)?updated_time: ).*/$1$ts/mg;
$data =~ s/^- \[ \].*\n//mg;
$data =~ s/^- \[\S\] (.*\n)/- $1/mg;
$data =~ s/^##.*\n\n//mg;

if ( $title ) {
    $data =~ s/^(.*)/$title/;
}
else {
    @tm = localtime;
    $ts = sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
		   1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
    $data =~ s/^(.*)/$1 $ts/;
}

my $fd;
open( $fd, '>:utf8', "$id.md" );
print $fd ( $data );
close($fd);

print STDOUT ($id, "\n") if $verbose;

################ Subroutines ################

sub uuid {
    my $uuid = "";
    $uuid .= sprintf("%04x", rand() * 0xffff) for 1..8;
    return $uuid;
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
	GetOptions('output=s'	=> \$output,
		   'title=s'	=> \$title,
		   'dir=s'	=> \$dir,
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

picklist - make a picklist out of a Joplin note

=head1 SYNOPSIS

makenote [options] [file ...]

 Options:
   --title=XXX		title (optional)
   --output=XXX		output file (optional)
   --dir=XXX		where the joplin notes reside
   --ident		shows identification
   --quiet		runs quietly
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information

=head1 OPTIONS

=over 8

=item B<--output=>I<XXX>

Specifies the output file for the new note.

If used, the final (or only) component of the file name must be a 32
character hex string, followed by C<.md>.

By default the new content is written to a new note file B<in the
current folder>, even if B<--dir> is used.

=item B<--dir=>I<XXX>

The location where the Joplin notes reside. This is currently not used.

=item B<--title=>I<XXX>

Specifies a title for the note. If this is not used, a timestamp is
appended to the current title of the note.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item B<--quiet>

Runs quietly. It suppresses the writing of the uid of the new note 
to standard output.

=item I<file>

The input file(s) to process, if any. The contents will be
concatenated to form the content of the new note.

=back

=head1 DESCRIPTION

B<This program> will read Joplin note and create a new new that has
all unchecked list items, and possible section titles, removed.

=cut
