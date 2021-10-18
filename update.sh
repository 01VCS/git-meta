#!/bin/bash

echo "- Updating git-meta... 🧚"
cp -r -f --preserve=all git-meta.sh .git/hooks
echo "Done! git-meta has been updated in your repo!"
