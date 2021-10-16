# git-meta

Wanna git preserve your file dates?

git-meta stores all files' metadata into '.gitmeta'!

Based on a gist: https://gist.github.com/andris9/1978266
Also includes this fork gist: https://gist.github.com/Cojad/9205547/revisions

## Instructions

source:

    git-meta --store      Cache all meta include numeric uid/gid/permission in .gitmeta
    git-meta -f           Alias of --store

    git-meta --stdout     Same as --store but output in console
    git-meta -c           Alias of --stdout

    

destination:

    git-meta --apply      Apply/Restore meta saved in .gitmeta
    git-meta -r           Alias of --apply
    