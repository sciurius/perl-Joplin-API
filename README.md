## Joplin Tools

This is a collection tools that perform some handy operations on Joplin notes.

See [Joplin Home](https://joplin.cozic.net/) for more information on Joplin.

**NOTE** This is WIP/WFM. YMMV.

### Joplin::API

This is the [Joplin Web Clipper API](https://discourse.joplin.cozic.net/t/web-clipper-is-now-available-beta-feature/154/37) implemented in perl.

### script/addnote.pl

This is a simple script that can be used to add notes to Joplin.

Supported are text documents and images (jpg, gif, png).

Usage:

    perl addnote.pl [ options ] document

Relevant options:

    --parent=XXX    note parent (defaults to "Imported Notes")

    --title=XXX     title (optional)

The document will be added to the notes collection into the parent folder.

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

