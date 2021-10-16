#!/bin/sh -e

#git-cache-time -- simple file timestamp caching and applying.
#Simple solution to store/restore timestamp from git repository
# - save only file modification timestamp
# 2014-02-25 change filetime from accessed time to modified time by cojad
# 2012-03-05 - added filetime, andris9
#modified by n1k
#from http://www.kerneltrap.org/mailarchive/git/2009/1/9/4654694
: ${GIT_CACHE_META_FILE=.git_cache_meta}
case $@ in
    --store|-f|--stdout|-c)
    case $1 in --store|-f) exec > $GIT_CACHE_META_FILE; esac
    find $(git ls-files)\
        \( -printf 'touch -c -d "%TY-%Tm-%Td %TH:%TM:%TS" "%p"\n' \) ;;
    --apply|-r) sh -e $GIT_CACHE_META_FILE;;
    *) 1>&2 echo "Usage:"
            echo "  $0 --store|--stdout|--apply";
            echo "        --store   -f  store timestamp in file";
            echo "        --stdout  -c  output to cosole";
            echo "        --apply   -r  restore timestamp"; exit 1;;
esac