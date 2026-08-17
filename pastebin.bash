#!/bin/bash

# Configuration
API_DEV_KEY="G3WcwMchol-Qu9PtwG57KwJCZDBqykPO"

# Check if a file argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Check if the file actually exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found."
    exit 1
fi

FILE_PATH="$1"
FILE_NAME=$(basename "$FILE_PATH")

echo "Uploading '$FILE_NAME' to Pastebin..."

# Upload using Pastebin API
# -s suppresses the curl progress bar
PASTE_URL=$(curl -s -X POST \
    -d "api_dev_key=${API_DEV_KEY}" \
    -d "api_option=paste" \
    -d "api_paste_name=${FILE_NAME}" \
    --data-urlencode "api_paste_code@${FILE_PATH}" \
    "https://pastebin.com/api/api_post.php")

# Check if the response looks like a valid Pastebin URL
if [[ "$PASTE_URL" == *"pastebin.com"* ]]; then
    echo "Upload successful!"
    echo "Link: $PASTE_URL"

    PASTE_URL="pastebin run $PASTE_URL"

    # Copy to clipboard based on the Operating System
    if command -v xclip &> /dev/null; then
        echo -n "$PASTE_URL" | xclip -selection clipboard
        echo "Link copied to Linux clipboard."
    elif command -v pbcopy &> /dev/null; then
        echo -n "$PASTE_URL" | pbcopy
        echo "Link copied to macOS clipboard."
    else
        echo "Warning: Clipboard tool (xclip/pbcopy) not found. Could not copy automatically."
    fi
else
    echo "Upload failed. Error response from Pastebin:"
    echo "$PASTE_URL"
    exit 1
fi
