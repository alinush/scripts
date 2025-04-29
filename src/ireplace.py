#!/usr/bin/env python3
import os
import sys
import re


def highlight_matches(text, pattern):
    # ANSI escape sequences: Bold and red text
    highlight_start = "\033[1;31m"  # Bold red text
    highlight_end = "\033[0m"       # Reset formatting

    # This replacement function wraps each match in the highlight codes.
    def repl(match):
        return f"{highlight_start}{match.group(0)}{highlight_end}"
    
    # Substitute all occurrences of the pattern with the highlighted version.
    return re.sub(pattern, repl, text)

def process_file(file_path, search_str, replace_str):
    """
    Process a single file: read its lines, and for each line that contains the search_str,
    display the line number and content, then ask the user if they want to replace all occurrences.
    If any replacements are made, the file is overwritten with the new content.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"\nFile: {file_path}")
        print(f"====================================================")
        print(f"Could not read: {e}")
        return

    printed = False
    modified = False
    for i, line in enumerate(lines):
        if search_str in line:
            if not printed:
                print(f"\nFile: {file_path}")
                print(f"====================================================")
                printed = True

            highlighted = highlight_matches(line.rstrip(), search_str)

            print(f"\n{i+1}: {highlighted}\n")
            answer = input("Do you want to replace on this line? (y/n): ").strip().lower()
            #answer = "y";
            if answer == "y":
                # Replace all occurrences of search_str in the line
                new_line = line.replace(search_str, replace_str)
                print(f"Replaced: {new_line.rstrip()}\n")
                lines[i] = new_line
                modified = True

    if modified:
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.writelines(lines)
            print(f"Updated file: {file_path}\n")
        except Exception as e:
            print(f"Could not write to {file_path}: {e}")

def main():
    # Check for proper command-line arguments
    if len(sys.argv) < 4:
        print("Usage: python interactive_replace.py <search_str> <replace_str> <directory>")
        sys.exit(1)
    
    search_str = sys.argv[1]
    replace_str = sys.argv[2]
    directory = sys.argv[3]

    # Walk through the directory recursively
    for root, dirs, files in os.walk(directory):
        for filename in files:
            file_path = os.path.join(root, filename)
            process_file(file_path, search_str, replace_str)

if __name__ == "__main__":
    main()

