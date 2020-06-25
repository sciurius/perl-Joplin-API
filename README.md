README

## Joplin Tools

This is a collection tools that implements an API to Joplin and can be used to perform some handy operations on Joplin notes.

See [Joplin Home](https://joplin.cozic.net/) for more information on Joplin.

**NOTE** This is WIP/WFM. YMMV.

### Joplin

This module implements an object oriented interface to the Joplin notes system, using the Joplin clipper server as storage backend.

The interface defines four classes:

 - Joplin::Folder - folder objects
 - Joplin::Note - note objects
 - Joplin::Tag - tag objects
 - Joplin::Resource - resource objects

Using folder objects you can find and manipulate subfolders and notes. Notes can find and manipulate tags, and so on.

Note that the Joplin data is considered as a folder on itself. This is
handled by the class `Joplin::Root`. This class is a `Joplin::Folder` in
all relevant aspects.

#### Connecting to the Joplin server

    use Joplin;
	$root = Joplin->connect( server => "http://localhost:41884",
	                         apikey => "YourJoplinClipperAPIKey" );

When the connection is succesfull, a folder object is returned representing the root notebook.
							 
#### Finding folders

For example, find the folder with name "Project". For simplicity, assume there is only one.

    $prj = $root->find_folders("Project")->[0];

All `find_...` methods take an optional argument which is a string or a pattern. If a string, it performs a case insensitive search on the names of the folders. A pattern can be used for more complex matches. If the argument is omitted, all results are returned.

With a second, non-false argument, the search includes subfolders.

#### Finding notes

For example, find all notes in the Project folder that have "january" in the title.

	@notes = $prj->find_notes(qr/january/i);

#### Creating and deleting notes

To create a new note with the given name and markdown content:

    $note = $folder->create_note("Title", "Content goes *here*");

To delete a note:

	$note->delete;

#### Finding tags

	@tags = $note->find_tags;

This yields an array (that may be empty) with all tags associated with this note. Likewise, given a tag, you can find all notes that have this tag associated:

    @notes = $tag->find_notes;

#### Creating and deleting tags

To associate a tag with a note:

    $tag = $note->add_tag("my tag");

To delete the tag from this note:

	$note->delete_tag("my tag");

Alternatively:

	$note->delete_tag($tag);

This deletes the tag from **all** notes **and** from the system:

    $tag->delete;

#### Resources

*To be implemented*

### Joplin::API

This is a low level implementation of the [Joplin Web Clipper API](https://discourse.joplin.cozic.net/t/web-clipper-is-now-available-beta-feature/154/37).

This API deals with JSON data and HTTP calls to the Joplin server. It can be used on itself but its main purpose is to support the higher level Joplin API.

### script/listnotes.pl

This is a simple script that lists the titles of the notes and folders
in hierarchical order. Optionally resources used by the notes can be
listed and unused resources removed.

Usage:

    perl listnotes.pl [ options ]

Relevant options:

    --title=XXX     title (optional)
	--resources     include resources
	
### script/listtags.pl

This is a simple script that lists the titles of the tags, with the
number of notes that use this tag. With `-v`: also shows the title of
the notes.

Usage:

    perl listtags.pl [ options ]

Relevant options:

    --title=XXX     title (optional)
	--weed          removes tags without notes

### script/addnote.pl

This is a simple script that can be used to add notes to Joplin.

Supported are text documents and images (jpg, gif, png).

Usage:

    perl addnote.pl [ options ] document

Relevant options:

    --parent=XXX    note parent (defaults to "Imported Notes")

    --title=XXX     title (optional)

The document will be added to the notes collection into the parent folder.

### script/joplinfs.pl

An experimental (proof-of-concept) implementation of a Joplin filesystem. It works (Linux) with FUSE. It uses the Joplinserver as a back end and provides a filesystem view on the notes. Notes and folders are identified by name.

    $ ls -l tmp/notes/joplin/Scratch/
    -rw-r--r-- 1 jv jv 0 Mar  6 08:35 Checkboxes.md
    -rw-r--r-- 1 jv jv 0 Jan 28  2019 Lorem Ipsum.md
    -rw-r--r-- 1 jv jv 0 Mar  3  2019 README.md
    drwxr-xr-x 1 jv jv 3 Apr 30 11:41 SubScratch/

    % cat tmp/notes/joplin/Scratch/Checkboxes.md 
    - [ ] Seitan
    - [ ] Blanke bonen
    - [ ] Berglinzen
    - [ ] Couscous
    - [ ] Citroensap
    - [ ] Limoensap

Dates are accurate. Size of a folder is the number of subnotes/folders.
You can view, modify, rename, create notes and folders. All changes are immediately reflected in Joplin.

Limitations: No duplicate file/folder names.

### cloud/addnote.pl

This tool is similar to `script/addnote.pl`, but it doesn't use the Web Clipper API and hence does not require a running Joplin instance. Instead, it uses the cloud storage.

In my setup, all Joplin clients synchronize to an ownCloud server. The relevant parts of the ownCloud storage are mirrored, using the native ownCloud client, to a desktop PC. So on the PC I have full access to the folder with Joplin notes.

When `addnote_cloud.pl` adds a new note, it inspects the folder with existing notes, tries to find the parent folder, and creates a new note file that contains the data and Joplin metadata. This file will be synchronized to the cloud server and eventually all clients will receive the new note from the server.

Usage:

    perl cloud/addnote.pl [ options ] document

Relevant options: same as `addnote.pl`, plus:

    --dir=XXX       the location of the Joplin notes on disk

    --folder        create a new notebook

### cloud/shownotes.pl

This program shows the notes and folders that are present in the Cloud
folder.

    perl cloud/shownotes.pl colder

