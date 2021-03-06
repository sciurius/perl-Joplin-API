#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Mon Sep  3 10:45:33 2018
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jan  6 20:24:37 2019
# Update Count    : 92
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Encode;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( addnote_cloud 0.04 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $dir = "/home/jv/Cloud/ownCloud/Notes/Joplin";
my $folder;
my $title;
my $parent;
my @tags;
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

my @tm = gmtime;
my $ts = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d.000Z",
		  1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
my $author = (getpwuid($<))[6];

if ( $folder ) {
    make_folder( $parent, $title );
}
else {
    my $file = $ARGV[0];

    my $id;
    if ( $file =~ /\.(jpe?g|gif|png)$/ ) {			# image
	$id = make_resource( $parent, $title );
    }
    else {
	$id = make_note( $parent, $title );
    }

    if ( $id && @tags ) {
	foreach my $tag ( @tags ) {
	    my $tag_id = make_tag( $tag );
	    add_tag( $id, $tag_id );
	}
    }
}

################ Subroutines ################

sub make_folder {
    my ( $parent, $title ) = @_;
    $parent = find_folder( $parent );
    $parent //= "";
    my $id = uuid();

    die("Folder needs title id!\n") unless $title;
    my $content = { id     => $id,
		    type   => 2,
		    data   => $title,
		    meta   => <<EOD };
id: $id
parent_id: 
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
EOD

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;
    $id;
}

sub make_note {
    my ( $parent, $title ) = @_;
    $parent = find_folder( $parent );
    my $id = uuid();

    my $content = { id => $id, type => 1 };
    if ( @ARGV && !$title ) {
	( $title = $ARGV[0] ) =~ s;^.*/;;
    }
    my $data = do { local $/; <> };
    if ( $title ) {
	$data = $title . "\n\n". $data;
    }
    $content->{data} = $data;
    $content->{meta} = <<EOD;
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

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;
    $id;
}

sub make_resource {
    my ( $parent, $title ) = @_;
    $parent = find_folder( $parent );
    my $id = uuid();

    die("Resource needs parent id!\n") unless $parent;

    my $mime = "jpeg";
    my $rsc = shift(@ARGV);

    if ( $rsc =~ /\.jpe?g/$ ) {
	$mime = "jpeg";
    }
    elsif ( $rsc =~ /\.png/$ ) {
	$mime = "png";
    }
    elsif ( $rsc =~ /\.gif/$ ) {
	$mime = "gif";
    }
    else {
	die("Unhandled resource type, must be jpg, png or gif\n");
    }

    my $content = { id   => $id,
		    type => 4,
		    data => $rsc,
		    meta => <<EOD };
id: $id
mime: image/$mime
filename:
file_extension: $mime
parent_id: $parent
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
encryption_blob_encrypted: 0
EOD

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;

    # Copy the resource into the .resource folder.

    my $rscdir = "$dir/.resource";
    mkdir($rscdir) unless -d $rscdir;

    use Fcntl;
    sysopen( my $src, $rsc, O_RDONLY )
      or die( $content->{data}, ": $!\n");
    sysopen( my $dst, "$rscdir/$id", O_WRONLY|O_CREAT )
      or die( "$rscdir/$id: $!\n" );

    my $buf = "";
    while ( ( my $n = sysread( $src, $buf, 10240 ) ) > 0 ) {
	syswrite( $dst, $buf, $n );
    }

    close($src);
    close($dst);

    $id
}

sub make_tag {
    my ( $tag ) = @_;

    my $id = find_tag($tag);
    return $id if $id;

    $id = uuid();
    my $content = { id   => $id,
		    type => 5,
		    data => $tag,
		    meta => <<EOD };
id: $id
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
EOD

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;
    $id
}

sub add_tag {
    my ( $note_id, $tag_id ) = @_;
    my $id = uuid();

    my $content = { id   => $id,
		    type => 6,
		    meta => <<EOD };
id: $id
note_id: $note_id
tag_id: $tag_id
created_time: $ts
updated_time: $ts
user_created_time: $ts
user_updated_time: $ts
encryption_cipher_text: 
encryption_applied: 0
EOD

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;
    $id
}

sub make_key {
    my ( $title ) = @_;
    my $id = uuid();

    my $content = { id   => $id,
		    type => 9,
		    meta => <<EOD };
id: $id
created_time: $ts
updated_time: $ts
source_application: net.cozic.joplin-desktop
encryption_method: 2
checksum: ...64 hex chars ...
content: { ... }
EOD

    store( $content );
    print STDOUT ( $id, "\n" ) if $verbose;
    $id
}

sub store {
    my ( $content ) = @_;
    my $fd;
    open( $fd, '>:raw', "$dir/" . $content->{id} . ".md" );
    print $fd ( $content->{data}, "\n\n" ) if defined $content->{data};
    print $fd ( encode_utf8($content->{meta}),
		"type_: ", $content->{type} );
    close($fd);

}

sub find_folder {
    my ( $pat ) = @_;

    my @files = glob("$dir/????????????????????????????????.md");

    if ( defined($pat) ) {
	if ( $pat =~ m;^/(.*); ) {
	    $pat = $1;
	}
	else {
	    $pat = qr/^.*$pat/i;	# case insens substr
	}
	$folder = _find_folder( $pat, \@files );
    }

    return $folder || _find_folder( "Imported Notes", \@files );
}

sub _find_folder {
    my ( $pat, $files ) = @_;

    foreach ( @$files ) {
	open( my $fd, '<', "$_" ) or die("$_: $!\n");
	my $data = do { local $/; <$fd> };
	close($fd);

	if ( $data =~ /^type_: 2\z/m
	     && $data =~ $pat
	     && $data =~ /^id:\s*(.{32})$/m
	   ) {
	    return $1
	}
    }
    return;
}

sub find_tag {
    my ( $pat ) = @_;

    my @files = glob("$dir/????????????????????????????????.md");
    my $id;

    if ( $pat =~ m;^/(.*); ) {
	$pat = $1;
    }
    else {
	$pat = qr/^.*$pat/i;	# case insens substr
    }
    return _find_tag( $pat, \@files );
}

sub _find_tag {
    my ( $pat, $files ) = @_;

    foreach ( @$files ) {
	open( my $fd, '<', "$_" ) or die("$_: $!\n");
	my $data = do { local $/; <$fd> };
	close($fd);

	if ( $data =~ /^type_: 5\z/m
	     && $data =~ $pat
	     && $data =~ /^id:\s*(.{32})$/m
	   ) {
	    return $1
	}
    }
    return;
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
    my @t;			# tags

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
		   'tags=s@'	=> \@t,
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
    die("Folders cannot have tags\n") if $folder && @t;
    foreach ( @t ) {
	push( @tags, split(/,\s*/, $_) );
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
   --tag=YYY		tags or tag ids
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

=item B<--tag=>I<XXX>    B<--tags=>I<XXX,YYY>

Specifies one or more tags to be associated with this note. Multiple
options may be used to specify multiple tags.

The tag is either an existing tag, a new tag, or the id of an existing tag.

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

=head1 AUTHOR

Johan Vromans C<< <sciurius at github dot com > >>

=head1 SUPPORT

Joplin-Tools development is hosted on GitHub, repository
L<https://github.com/sciurius/Joplin-Tools>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/sciurius/Joplin-Tools/issues>.

=head1 LICENSE

Copyright (C) 2018 Johan Vromans,

This program is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
