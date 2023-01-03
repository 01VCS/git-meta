#!/bin/bash

if [ ! -f .git/hooks/git-meta ]
    then
        echo ""
        echo "It looks like its your first time using this! 🤗"
        echo "- Initializing git-meta on your repo... 🧚"
#        cp -r -f --preserve=all git-meta.sh .git/hooks
        ln -s /usr/bin/git-meta .git/hooks/git-meta
        if [ -f .git/hooks/git-meta ]; then
                chmod +x .git/hooks/git-meta
                echo "git-meta has been placed!"
                echo ""
                echo "Initializing as git hook..."
fi
        if [ -e .git/hooks/pre-commit ]
            then
                echo ".git/hooks/pre-commit exists. Appending to it..."
                cat >> .git/hooks/pre-commit <<EOF
#01VCSHere

echo "Storing files' timestamp and other metadata..." && bash .git/hooks/git-meta --store && git add .gitmeta && echo "Done. Meta has been preserved!"
EOF
                chmod +x .git/hooks/pre-commit
                
                echo "Done!"
            else
                echo ".git/hooks/pre-commit doesn't exist. Creating it..."
                cat > .git/hooks/pre-commit <<EOF
#!/bin/bash

#01VCSHere

echo "Storing files' timestamp and other metadata..." && bash .git/hooks/git-meta --store && git add .gitmeta && echo "Done. Meta has been preserved!"
EOF
                chmod +x .git/hooks/pre-commit
                echo "Done!"
fi
        echo "Done! git-meta has been initiated in your repo!"
    else
        echo "git-meta is already initiated in your repo."
fi
