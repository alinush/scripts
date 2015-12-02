TODO
====

 + Fix `gacp` to check for the last commit message, and if it's the same as the current one, it should not commit nor push.
 + Write a script that renames "Bad Linux File Name" into "better-linux-file-name"
 + Write a `gclo` script that takes a repository name and clones it from your GitLab/GitHub
    - Figure out how to handle ambiguities
 + `repo-update.py`:
    - Handle repositories with submodules (update submodules as well)
    - Add `<repo_name>` argument to specify repo (just updates that repo)
    - Add `--stash` parameter to stash changes and pull (for Git repos)
 + `encrypt.sh` and `decrypt.sh`
    - Remove .enc extension of encrypted files, if present.
    - Allow multiple inputs to `encrypt.sh` (and `decrypt.sh`?) and maybe tar them up and encrypt the tar
