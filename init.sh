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

echo "Storing files' timestamp, CID/hash; and other files/commit's metadata..."

commit_author="$(git config user.name)"" <""$(git config user.email)"">" 
commit_message=$(cat $1)
current_branch=$(git rev-parse --abbrev-ref HEAD) #from https://dev.to/anibalardid/how-to-check-commit-message-and-branch-name-with-git-hooks-without-any-new-installation-n34
# https://github.com/typicode/husky/discussions/1171

if [ ! -f ".gitmeta-cid" ]; then touch .gitmeta-cid; fi

echo "Branch: $current_branch" > .gitmeta-cid & #use ">" instead of ">>" as a way of emptying .gitmeta-cid before writing new commit data
# Get a list of all staged files
staged_files="$(git diff --cached --name-only)"
# Hash (IPFS CID) the contents of each staged file, to the pipe
for file in "$staged_files"; do
    if [ -f "$file" ]; then
        file_cid=$(ipfs add -q --only-hash "$file")
        echo "$file"": ""$file_cid" >> .gitmeta-cid &
    fi
done

commit_cid=$(ipfs add -q --only-hash .gitmeta-cid)
echo "commit ""$commit_cid" > .gitmeta #use ">" instead of ">>" as a way of emptying .gitmeta before writing new commit data
echo "Branch: ""$current_branch" >> .gitmeta
echo "" >> .gitmeta && echo "------------------------------" >> .gitmeta && echo "" >> .gitmeta

# If the .eth file exists, sign the commit data with the Ethereum account
if [ -f ".git/hooks/.eth" ]; then
    eth_account=$(cat .git/hooks/.eth)
    signature=$(geth --exec "web3.personal.sign(web3.toHex('$commit_cid'), '$eth_account', null)" attach)
fi

bash .git/hooks/git-meta --store
git add .gitmeta
git add .gitmeta-cid
echo "Done. Meta has been preserved!"
EOF
                chmod +x .git/hooks/pre-commit
                
                echo "Done!"
            else
                echo ".git/hooks/pre-commit doesn't exist. Creating it..."
                cat > .git/hooks/pre-commit <<EOF
#!/bin/bash

#01VCSHere

echo "Storing files' timestamp, CID/hash; and other files/commit's metadata..."

commit_author="$(git config user.name)"" <""$(git config user.email)"">" 
commit_message=$(cat $1)
current_branch=$(git rev-parse --abbrev-ref HEAD) #from https://dev.to/anibalardid/how-to-check-commit-message-and-branch-name-with-git-hooks-without-any-new-installation-n34
# https://github.com/typicode/husky/discussions/1171

if [ ! -f ".gitmeta-cid" ]; then touch .gitmeta-cid; fi

echo "Branch: $current_branch" > .gitmeta-cid & #use ">" instead of ">>" as a way of emptying .gitmeta-cid before writing new commit data
# Get a list of all staged files
staged_files=$(git diff --cached --name-only)
# Hash (IPFS CID) the contents of each staged file, to the pipe
for file in $staged_files; do
    if [ -f "$file" ]; then
        file_cid=$(ipfs add -q --only-hash "$file")
        echo "$file"": ""$file_cid" >> .gitmeta-cid &
    fi
done

commit_cid=$(ipfs add -q --only-hash .gitmeta-cid)
echo "commit ""$commit_cid" > .gitmeta #use ">" instead of ">>" as a way of emptying .gitmeta before writing new commit data
echo "Branch: ""$current_branch" >> .gitmeta
echo "" >> .gitmeta && echo "------------------------------" >> .gitmeta && echo "" >> .gitmeta

# If the .eth file exists, sign the commit data with the Ethereum account
if [ -f ".git/hooks/.eth" ]; then
    eth_account=$(cat .git/hooks/.eth)
    signature=$(geth --exec "web3.personal.sign(web3.toHex('$commit_cid'), '$eth_account', null)" attach)
fi

bash .git/hooks/git-meta --store
git add .gitmeta
git add .gitmeta-cid
echo "Done. Meta has been preserved!"
EOF
                chmod +x .git/hooks/pre-commit
                echo "Done!"
fi
        #if [ ! -f ".gitmeta-cid" ]; then touch .gitmeta-cid; fi
        echo "Done! git-meta has been initiated in your repo!"
    else
        #if [ ! -f ".gitmeta-cid" ]; then touch .gitmeta-cid; fi
        echo "git-meta is already initiated in your repo."
fi
