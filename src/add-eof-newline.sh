if [ $# -ne 1 ]; then
    echo "Usage: `basename $0` <file>"
    exit 1
fi

tail -n1 $1 | read -r _ || echo >> $1
