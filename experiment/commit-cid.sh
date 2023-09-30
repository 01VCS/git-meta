#!/bin/bash

# Create a temporary named pipe
tmp_fifo=$(mktemp -u)
mkfifo $tmp_fifo

# Get the commit author, date and message
commit_author=$(git config user.name)
commit_date=$(git log -1 --pretty=%cd)
commit_message=$(git log -1 --pretty=%B)

# Write the commit metadata to the pipe
echo "Author: $commit_author" > $tmp_fifo &
echo "Date: $commit_date" > $tmp_fifo &
echo "Message: $commit_message" > $tmp_fifo &

# Extract co-authors from the commit message and write them to the pipe
co_authors=$(echo "$commit_message" | grep 'Co-authored-by:' | cut -d':' -f2-)
if [ ! -z "$co_authors" ]; then
    echo "Co-authors: $co_authors" > $tmp_fifo &
fi

# Get a list of all staged files
staged_files=$(git diff --cached --name-only)

# Write the contents of each staged file to the pipe
for file in $staged_files; do
    if [ -f "$file" ]; then
        cat "$file" > $tmp_fifo &
    fi
done

# Calculate the IPFS CID from the data in the pipe
ipfs add --only-hash $tmp_fifo

# Clean up
rm $tmp_fifo
