#!/bin/bash -e

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
#2015-04-17 - time zone offset fallback; fix leading-dash-name error; avoid deeper find;
#              better quote file names; better directory listing; merge short opts; by Danny Lin (@danny0838)
#2015-05-07 - for Mac OS X, `brew install findutils gawk coreutils`, by @bizonix

: ${GIT_CACHE_META_FILE=.gitmeta}

if [[ "$OSTYPE" == "darwin"* ]]; then
    GNU='g'
fi
for bin in find touch awk ; do
    BIN=$( echo $bin | tr '[:lower:]' '[:upper:]')
    eval ': ${'$BIN':=$(which $GNU$bin)}'
    if [ "$GNU" == 'g' ] && ! [[ "${!BIN}" =~ /$GNU$bin ]]  ; then
        echo "gnu version of '$bin' file not found." >&2
        exit 1
    fi
done

: ${Tz:=$($FIND -prune -printf '%Tz')}
: ${Tz:=$(date +%z)}
if ! [ "$Tz" ]; then
    echo "%z not supported in 'strftime' in C library." >&2
    exit 1
fi

if [ ! -f .gitmeta ]
   then # if the flag hasn't been placed, this is the first use
      echo "Its your first time using git-meta on this repository!"
      case $@ in
          --store|--stdout)
          case $1 in --store) exec > $GIT_CACHE_META_FILE; esac
          { git ls-tree --name-only -rdz $(git write-tree) | xargs -0 -I NAME $FIND ./NAME -maxdepth 0 \
              \( -printf 'chown -h %U:%G \0%p\n' \) , \
              \( \! -type l -printf 'chmod %#m \0%p\n' \) , \
              \( -printf $TOUCH' -hcmd "%TY-%Tm-%Td %TH:%TM:%TS '$Tz'" \0%p\n' \) , \
              \( -printf $TOUCH' -hcad "%AY-%Am-%Ad %AH:%AM:%AS '$Tz'" \0%p\n' \)
            git ls-files -z | xargs -0 -I NAME $FIND ./NAME -maxdepth 0 \
              \( -printf 'chown -h %U:%G \0%p\n' \) , \
              \( \! -type l -printf 'chmod %#m \0%p\n' \) , \
              \( -printf $TOUCH' -hcmd "%TY-%Tm-%Td %TH:%TM:%TS '$Tz'" \0%p\n' \) , \
              \( -printf $TOUCH' -hcad "%AY-%Am-%Ad %AH:%AM:%AS '$Tz'" \0%p\n' \)
          } | $AWK 'BEGIN {FS="\0"}; {print $1 "'\''" gensub(/'\''/, "'\''\\\\'\'''\''", "g", $2) "'\''" }' ;;
          --apply) sh -e $GIT_CACHE_META_FILE;;
          *) 1>&2 echo "Usage:"
                  echo "  $0 --store|--stdout|--apply";
                  echo "        --store   -f  store meta in file";
                  echo "        --stdout  -c  output to cosole";
                  echo "        --apply   -r  restore meta"; exit 1;;
esac
#Would you like to add all files that are on the working tree (even the not versioned ones)?
#https://www.google.com/search?q=ls+all+files+recursively+except+some&client=ubuntu&hs=fhV&channel=fs&ei=HzWUYffIDKbN1sQPsu6n-AM&oq=ls+all+files+recursively+except+some&gs_lcp=Cgdnd3Mtd2l6EAM6BwgAEEcQsANKBAhBGABQFlgWYJUEaAFwAngAgAG0AYgBtAGSAQMwLjGYAQCgAQHIAQjAAQE&sclient=gws-wiz&ved=0ahUKEwi31M28-530AhWmppUCHTL3CT8Q4dUDCA0&uact=5
   else
      case $@ in
          --store|--stdout)
          case $1 in --store) exec > $GIT_CACHE_META_FILE; esac
          { git diff --name-only -z HEAD | xargs -0 -I NAME $FIND ./NAME -maxdepth 0 \
              \( -printf 'chown -h %U:%G \0%p\n' \) , \
              \( \! -type l -printf 'chmod %#m \0%p\n' \) , \
              \( -printf $TOUCH' -hcmd "%TY-%Tm-%Td %TH:%TM:%TS '$Tz'" \0%p\n' \) , \
              \( -printf $TOUCH' -hcad "%AY-%Am-%Ad %AH:%AM:%AS '$Tz'" \0%p\n' \)
#            git ls-files -mz | xargs -0 -I NAME $FIND ./NAME -maxdepth 0 \
#              \( -printf 'chown -h %U:%G \0%p\n' \) , \
#              \( \! -type l -printf 'chmod %#m \0%p\n' \) , \
#              \( -printf $TOUCH' -hcmd "%TY-%Tm-%Td %TH:%TM:%TS '$Tz'" \0%p\n' \) , \
#              \( -printf $TOUCH' -hcad "%AY-%Am-%Ad %AH:%AM:%AS '$Tz'" \0%p\n' \)
          } | $AWK 'BEGIN {FS="\0"}; {print $1 "'\''" gensub(/'\''/, "'\''\\\\'\'''\''", "g", $2) "'\''" }' ;;
          --apply) sh -e $GIT_CACHE_META_FILE;;
          *) 1>&2 echo "Usage:"
                  echo "  $0 --store|--stdout|--apply";
                  echo "        --store   -f  store meta in file";
                  echo "        --stdout  -c  output to cosole";
                  echo "        --apply   -r  restore meta"; exit 1;;
esac
fi
