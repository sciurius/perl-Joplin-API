#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Mon Sep 17 10:45:33 2018
# Last Modified By: Johan Vromans
# Last Modified On: Tue Sep 18 19:27:57 2018
# Update Count    : 35
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Encode;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( makenote 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $dir = "/home/jv/Cloud/ownCloud/Notes/Joplin";
my $folder;
my $title;
my $parent;
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

my $id = uuid();
my @tm = gmtime;
my $ts = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
my $author = (getpwuid($<))[6];
my $data;
my $meta;
my $type;

if ( $parent && $parent !~ /^[0-9a-f]{32}$/ ) {
    $parent = find_folder( $parent, $dir );
}

if ( $folder ) {
    die("Folder needs title id!\n") unless $title;
    $type = 2;
    $data = $title;
    $parent //= "";
    $meta = <<EOD;
id: $id
parent_id: 
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
EOD
}
elsif ( 0 ) {			# image
    die("Note needs parent id!\n") unless $parent;

    $type = 4;
    $data = shift(@ARGV);

    $meta = <<EOD;
id: $id
mime: image/jpeg
filename:
file_extension: jpeg
parent_id: $parent
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
encryption_blob_encrypted: 0
EOD
}
elsif ( 0 ) {			# key
    $type = 9;
    $meta = <<EOD;
id: $id
created_time: $ts
updated_time: $ts
source_application: net.cozic.joplin-desktop
encryption_method: 2
checksum: ...64 hex chars ...
content: { ... }
EOD
}
else {
    die("Note needs parent id!\n") unless $parent;

    $type = 1;
    $data = do { local $/; <> };
    if ( $title ) {
	$data = $title . "\n\n". $data;
    }

    $meta = <<EOD;
id: $id
parent_id: $parent
created_time: $ts
updated_time: $ts
is_conflict: 0
latitude: 0.00000000
longitude: 0.00000000
altitude: 0.0000
author: $author
source_url: 
is_todo: 0
todo_due: 0
todo_completed: 0
source: joplin
source_application: nl.squirrel.joplintools
application_data: 
order: 0
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
EOD
}

my $fd;
open( $fd, '>', "$id.md" );
print $fd ( $data, "\n\n" ) if defined $data;
print $fd ( encode_utf8($meta), "type_: $type" );
close($fd);

if ( $type == 4 ) {
    # TODO: copy data file to .resource
}

print STDOUT ($id, "\n") if $verbose;

################ Subroutines ################

sub find_folder {
    my ( $pat, $dir ) = @_;

    if ( $pat =~ m;^/(.*); ) {
	$pat = $1;
    }
    else {
	$pat = qr/^.*$pat/i;	# case insens substr
    }

    my @files = glob("$dir/????????????????????????????????.md");

    foreach ( @files ) {
	my $fd;
	open( $fd, '<', "$_" ) or die;
	my $data = do { local $/; <$fd> };
	if ( $data =~ /^type_: 2\z/m
	     && $data =~ $pat
	     && $data =~ /^id:\s*(.{32})$/m
	   ) {
	    return $1
	}
    }
}

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
	GetOptions('parent=s'	=> \$parent,
		   'title=s'	=> \$title,
		   'folder'	=> \$folder,
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

makenote - make a Joplin compliant note file

=head1 SYNOPSIS

makenote [options] [file ...]

 Options:
   --parent=XXX		note parent (required)
   --folder		create folder
   --title=XXX		title (optional)
   --dir=XXX		where the joplin notes reside
   --ident		shows identification
   --quiet		runs quietly
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information

=head1 OPTIONS

=over 8

=item B<--folder>

Creates a folder instead of a note. For a folder, the title is mandatory
and no content is needed. A parent is optional.

=item B<--parent=>I<XXX>

Specifies the parent for the note or folder.

The argument must be a 32 character hex string, otherwise it is
interpreted as a search argument.

If a search argument, it is used for case insensitive substring search
on folder titles. If it starts with a C</>, it is interpreted as a
regular expression patter to be matched against the folder titles.
Note that this requires a valid <--dir> location.

=item B<--dir=>I<XXX>

The location where the Joplin notes reside. Note this is only used to
find folder ids when the B<--parent> option specifies a search
argument.

=item B<--title=>I<XXX>

Specifies the title for the note or folder.

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

B<This program> will create Joplin compliant note and folder documents.

=cut
