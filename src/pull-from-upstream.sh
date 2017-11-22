# See https://help.github.com/articles/syncing-a-fork/

num_args=0

# If there's no upstream remote configured in the repo, ask for an argument!
if [ -z "`git remote | grep upstream`" ]; then
    num_args=1
fi

if [ $# -lt $num_args ]; then
    name=`basename $0`
    echo "Usage: $name [<git-repository-remote>]"
    echo 
    echo "If there's already an 'upstream' remote configured in the repo, just uses that and ignores argument"
    echo 
    echo "Example: $name https://github.com/scipr-lab/libfqfft.git"
    echo
    exit 1
fi


remote=$1

# If we were given a remote, try adding it!
if [ -n "$remote" ]; then
    if ! git remote add upstream "$remote"; then
        echo "NOTE: 'upstream' remote already exists. Proceeding..."
    fi
fi

git fetch upstream

git merge upstream/master
