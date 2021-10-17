#!/bin/bash

if [ ! -e .git/hooks/git-meta.sh ]
    then
        echo ""
        echo "It looks like its your first time using this! 🤗"
        echo "- Initializing git-meta on your repo... 🧚"
        cp -r -f --preserve=all git-meta.sh .git/hooks
        if [ -e .git/hooks/git-meta.sh ]; then
                echo "git-meta.sh has been placed!"
                echo ""
                echo "Initializing as git hook..."
fi
        if [ -e .git/hooks/pre-commit ]
            then
                echo ".git/hooks/pre-commit exists. Appending to it..."
                cat >> .git/hooks/pre-commit <<EOF
#!/bin/bash

echo "Storing files' timestamp and other metadata..." && bash .git/hooks/git-meta.sh --store && git add .gitmeta && echo "Done. Meta has been preserved!"
EOF
                echo "Done!"
            else
                echo ".git/hooks/pre-commit doesn't exist. Creating it..."
                cat > .git/hooks/pre-commit <<EOF
#!/bin/bash

echo "Storing files' timestamp and other metadata..." && bash .git/hooks/git-meta.sh --store && git add .gitmeta && echo "Done. Meta has been preserved!"
EOF
                echo "Done!"
fi
        echo "Done! git-meta has been initiated in your repo!"
    else
        echo "git-meta is already initiated in your repo."
fi