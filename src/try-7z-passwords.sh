cat passwords.txt | while read p; do
    len=${#p}
    echo "Trying: '$p', len $len"

    if 7z t archive.7z -p"$p" >/tmp/try-passwords.out; then
        echo "Success! Password is $p"
        exit 0
    else
        if ! grep "Data Error in encrypted file" /tmp/try-passwords.out >/dev/null; then
            echo "ERROR: Expected an error in output of 7z command for password $p"
            exit 1
        fi
    fi
done

echo
echo "No luck!"
