#!/bin/bash

echo "- Updating git-meta... 🧚"
cp -r -f --preserve=all git-meta.sh .git/hooks
chmod +x .git/hooks/git-meta.sh
echo "Done! git-meta has been updated in your repo!"
