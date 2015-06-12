# use 'uniq -d -w 64' to print duplicates by matching on the first 64
# characters only
find . -type f -print0 | xargs -0 sha256sum | sort | uniq $@ -d --check-chars=64
