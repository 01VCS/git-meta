# git-meta

Wanna git preserve your file dates?

git-meta stores all files' metadata into '.gitmeta'! On every commit!

Based on a gist: https://gist.github.com/andris9/1978266
Also includes this fork gist: https://gist.github.com/Cojad/9205547/revisions

**Update 20/10/2023**: in the 1st place: don't worry, you can still install git-meta standalone as you used to. In the 2nd place: git-meta now's part of a bigger project: [01](https://github.com/01VCS/01), a VCS layer2/aggregator. By installing 01, you're installing git-meta ready to come built-in every time you create an new repo!

## Instructions

### Initializing

Copy git-meta.sh and init.sh into your repo, then type the following command:

```bash
bash init.sh
```

And done, it will be initiated!

### Updating

Copy an up-to-date version of git-meta.sh and update.sh into your repo, then type the following command:

```bash
bash update.sh
```

Done!

### Others

source:

    git-meta --store      Cache all meta include numeric uid/gid/permission in .gitmeta
    git-meta -f           Alias of --store

    git-meta --stdout     Same as --store but output in console
    git-meta -c           Alias of --stdout

    

destination:

    git-meta --apply      Apply/Restore meta saved in .gitmeta
    git-meta -r           Alias of --apply
    

## ✨️ Contributors

<!--[![Contributors](https://contrib.rocks/image?repo=01VCS/git-meta)](https://github.com/01VCS/git-meta/graphs/contributors)-->

<a href="https://github.com/01VCS/git-meta/graphs/contributors">
  <img src="https://contributors-img.web.app/image?repo=01VCS/git-meta&max=500" />
</a>

## Announcement

@DaniMesq:

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
