#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <directory> <old_string> <new_string>"
    echo
    echo "Recursively searches for <old_string> and prompts the user if it wants to replace it with <new_string>"
    exit 1
fi

DIRECTORY=$1
OLD=$2
NEW=$3

# Find all files recursively
find "$DIRECTORY" -type f | while read -r file; do
    # Check if file contains the OLD string
    if grep -q "$OLD" "$file"; then
        echo "Processing file: $file"

        # Read file line-by-line
        nl "$file" | while IFS= read -r line; do
            line_number=$(echo "$line" | awk '{print $1}')
            line_content=$(echo "$line" | cut -f2-)

            if echo "$line_content" | grep -q "$OLD"; then
                echo "Line $line_number: $line_content"
                read -p "Replace on this line? (y/n): " answer

                if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                    # Use sed to replace string on the specific line
                    sed -i "${line_number}s/${OLD}/${NEW}/g" "$file"
                    echo "Line $line_number replaced."
                else
                    echo "Skipped line $line_number."
                fi
            fi
        done
    fi
done

