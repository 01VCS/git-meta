source:

    git-cache-time              Works like git-cache-meta but only store file timestamp

    git-cache-meta --store      Cache all meta include numeric uid/gid/permission in .git_cache_meta
    git-cache-meta -f           Alias of --store

    git-cache-meta --stdout     Same as --store but output in console
    git-cache-meta -c           Alias of --stdout

    

destination:

    git-cache-meta              Works like git-cache-meta but only store file timestamp
                                but restore "all" the meta in .git_cache_meta
                                
    git-cache-meta --apply      Apply/Restore meta saved in .git_cache_meta
    git-cache-meta -r           Alias of --apply
    