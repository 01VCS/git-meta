# git-meta

Easy solution to:

 - maintain correct git file dates and times (and zones and microseconds),
 - keep the correct file owner and group (by name, not number), and
 - keep file permissions correct

## Synopsis

1. install it:

       git clone https://github.com/gitcnd/git-meta.git
       sudo cp -a git-meta/git-meta.pl /usr/local/bin/

2. set up to use it:

       cd my_existing_repo
       git-meta.pl -setup -l /usr/local/bin/git-meta.pl

## How it works

Installation (above) automatically creates 2 symlinks for you, using these commands:-

    ln -s /usr/local/bin/git-meta.pl .git/hooks/pre-commit
    ln -s /usr/local/bin/git-meta.pl .git/hooks/post-merge

when you commit new files, the .git/hooks/pre-commit snapshots their metadata into a new file named .git-meta which is added to your project.

Anytime later, when you pull from your project, .git/hooks/post-merge runs, which restores the correct file metadata.

You can also manually save and restore by running `git-meta.pl -save somefile` or `git-meta.pl -restore somefile` (use . for all files recursively)


# Bonus Feature

This script also includes a -newgit option, which sets up and auto-configures your environment so that multiple people can work on a project, and an expanded version of it is kept up-to-date at all times: this would be ideal, for example, if you're editing websites.  The web-server's "html" folder automatically stays up-to-date anytime anyone does a push.

Full details are here: https://www.instructables.com/How-to-Use-git-on-Your-Own-Machines-to-Manage-Web-/


