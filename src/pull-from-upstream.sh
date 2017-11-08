# See https://help.github.com/articles/syncing-a-fork/

remote=$1

if [ $# -lt 1 ]; then
    name=`basename $0`
    echo "Usage: $name <git-repository-remote>"
    echo 
    echo "Example: $name https://github.com/scipr-lab/libfqfft.git"
    echo
    exit 1
fi

if ! git remote add upstream "$remote"; then
    echo "NOTE: 'upstream' remote already exists. Proceeding..."
fi

git fetch upstream

git merge upstream/master
