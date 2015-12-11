TODO
====

`repo-update.py`
----------------

 - Handle repositories with submodules (update submodules as well)
 - Add `--stash` parameter to stash changes and pull (for Git repos)
 - [DONE] Add `<repo_name>` argument to specify repo (just updates that repo)
 - [DONE] Add `<dir_name>` argument to specify repository directory (dir where repos are) to update all repos in
 - [DONE] Add config-file that specifies extra repo directories to work with

`encrypt.sh` and `decrypt.sh`
-----------------------------

 - Remove .enc extension of encrypted files, if present.
 - Allow multiple inputs to `encrypt.sh` (and `decrypt.sh`?) and maybe tar them up and encrypt the tar

Others
------

 + [DONE] Write a `hashdir` script that recursively hashes a directory with SHA256
 + Fix `gacp` to check for the last commit message, and if it's the same as the current one, it should not commit nor push.
 + Write a script that renames "Bad Linux File Name" into "better-linux-file-name"
 + [DONE] Figure out how to handle ambiguities in `clone.sh`

