#!/bin/sh -e

#git-cache-meta -- simple file meta data caching and applying.
#Simpler than etckeeper, metastore, setgitperms, etc.
# 2014-02-25 change filetime from accessed time to modifpeied time by cojad
# 2012-03-05 - added filetime, andris9
#modified by n1k
# - save all files metadata not only from other users
# - save numeric uid and gid
#from http://www.kerneltrap.org/mailarchive/git/2009/1/9/4654694

: ${GIT_CACHE_META_FILE=.git_cache_meta}
case $@ in
    --store|-f|--stdout|-c)
    case $1 in --store|-f) exec > $GIT_CACHE_META_FILE; esac
    find $(git ls-files)\
        \( -printf 'chown %U "%p"\n' \) \
        \( -printf 'chgrp %G "%p"\n' \) \
        \( -printf 'touch -c -d "%AY-%Am-%Ad %AH:%AM:%AS" "%p"\n' \) \
        \( -printf 'stat -c -d "%AY-%Am-%Ad %AH:%AM:%AS" "%p"\n' \) \
        \( -printf 'stat -c -d "%y" "%p"\n' \) \
        \( -printf 'touch -c -d "%y" "%p"\n' \) \
        \( -printf 'stat -c -d %y "%p"\n' \) \
        \( -printf 'touch -c -d %y "%p"\n' \) \
        \( -printf 'date -d "$(stat -c "%y" "%p" )" "+%Y-%m-%d:%H:%M:%S"\n' \) \
        \( -printf 'stat -c "%y" "%p"\n' \) \
        \( -printf 'touch -m "%AY-%Am-%Ad %AH:%AM:%AS" "%p"\n' \) \
        \( -printf 'stat -c -d "%p"\n' \) \
        \( -printf 'chmod %#m "%p"\n' \) ;;
    --apply|-r) sh -e $GIT_CACHE_META_FILE;;
    *) 1>&2 echo "Usage:"
            echo "  $0 --store|--stdout|--apply";
            echo "        --store   -f  store meta in file";
            echo "        --stdout  -c  output to cosole";
            echo "        --apply   -r  restore meta"; exit 1;;
esac