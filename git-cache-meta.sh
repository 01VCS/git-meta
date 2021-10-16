#!/bin/sh -e

#git-cache-meta -- simple file meta data caching and applying.
#Simpler than etckeeper, metastore, setgitperms, etc.
#from http://www.kerneltrap.org/mailarchive/git/2009/1/9/4654694
#modified by n1k
#modified by the-mars
# - save all files metadata not only from other users
# - save numeric uid and gid
#2012-03-05 - added filetime, by @andris9
#2012-05-22 - added fix for non ASCII characters and list size, merge chgrp into chown command
#2013-11-29 - fix bug at failing on files with spaces, by @AntonioMeireles and reported by @kickiss
#2014-02-20 - fix bugs of previous update and touch command as the LAST, by @brayrobert201 and reported by @Explorer09
#2014-02-23 - fix bugs of previous updates, by @stefanbj
#2014-02-24 - important modifications/fixes by @Explorer09:
# - 'touch' commands are moved to the bottom.
# - File modification time and access time are stored separately.
# - Timezone offsets are stored. (Strictly, the %Tz and %Az things are not documented in GNU find, but they will work as long as you have a C99-complaint library.)
# - Added '-h' switch to chown and chgrp. This allows the script to handle symlinks.
# - 'chmod' only if the file is not a symlink.
# - All unusual filenames are properly escaped, thanks to '-exec ls --quoting-style=shell'. Notice that '--quoting-style=c' does not work as it seems when there are filenames that contain newlines.
#2014-03-18 - @the-mars: store properties for dirs too

pIFS=$IFS
IFS='
'

: ${GIT_CACHE_META_FILE=.git_cache_meta}

if [ -n "$(find -prune -printf '%Tz %Az\n' | tr -d ' 0-9+-')" ]; then
echo "%z not supported in 'strftime' in C library." >&2
exit 1
fi

case $@ in
    --store|--stdout)
    case $1 in --store) exec > $GIT_CACHE_META_FILE; esac
    git ls-files -z | sed -z -r 's~/[^/]+$~~' | uniq -z | xargs -0 -I NAME find NAME \
        \( -printf 'chown -h %U:%G ' -exec ls -d --quoting-style=shell '{}' \; \) , \
        \( \! -type l -printf 'chmod %#m ' -exec ls -d --quoting-style=shell '{}' \; \) , \
        \( -printf 'touch -c -h -m -d "%TY-%Tm-%Td %TH:%TM:%TS %Tz" ' -exec ls -d --quoting-style=shell '{}' \; \) , \
        \( -printf 'touch -c -h -a -d "%AY-%Am-%Ad %AH:%AM:%AS %Az" ' -exec ls -d --quoting-style=shell '{}' \; \)
    git ls-files -z | xargs -0 -I NAME find NAME \
        \( -printf 'chown -h %U:%G ' -exec ls --quoting-style=shell '{}' \; \) , \
        \( \! -type l -printf 'chmod %#m ' -exec ls --quoting-style=shell '{}' \; \) , \
        \( -printf 'touch -c -h -m -d "%TY-%Tm-%Td %TH:%TM:%TS %Tz" ' -exec ls --quoting-style=shell '{}' \; \) , \
        \( -printf 'touch -c -h -a -d "%AY-%Am-%Ad %AH:%AM:%AS %Az" ' -exec ls --quoting-style=shell '{}' \; \) ;;
    --apply) sh -e $GIT_CACHE_META_FILE;;
    *) 1>&2 echo "Usage: $0 --store|--stdout|--apply"; exit 1;;
esac

IFS=$pIFS