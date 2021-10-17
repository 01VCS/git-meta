# git-meta

Wanna git preserve your file dates?

git-meta stores all files' metadata into '.gitmeta'!

Based on a gist: https://gist.github.com/andris9/1978266
Also includes this fork gist: https://gist.github.com/Cojad/9205547/revisions

## Instructions

### Initializing

Copy git-meta.sh and init.sh into your repo, then type the following command:

```bash
bash init.sh
```

And done, it will be initiated!

### Others

source:

    git-meta --store      Cache all meta include numeric uid/gid/permission in .gitmeta
    git-meta -f           Alias of --store

    git-meta --stdout     Same as --store but output in console
    git-meta -c           Alias of --stdout

    

destination:

    git-meta --apply      Apply/Restore meta saved in .gitmeta
    git-meta -r           Alias of --apply
    

## Announcement

@DaniellMesquita:

> It is wonderful the collaboration level the humans can naturally organize 🥰

> andris9 have started this and y'all started appending into it, respecting/including the previous contributions

> All of that not on a git repository, but providing a frugal way into a gist!

> 
> In case of any interest/need (and personally this script've helped me as I have a compulsion for preserving dates), [here is a unified repository](https://github.com/Floflis/git-meta) with all of your contributions! 🎉🥳 (🎊 look like a beach bikini)
> 

> https://github.com/Floflis/git-meta
> 

> AntonioMeireles brayrobert201 stefanbj Explorer09 Cojad the-mars mkortleven-emg danny0838 bizonix
> 

> Sorry arno01 for not including yours, as it seemed very incomplete and cmw reported it didn't worked.

https://gist.github.com/andris9/1978266#gistcomment-3929036