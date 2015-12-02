TODO
====

`repo-update.py`
----------------

 - Handle repositories with submodules (update submodules as well)
 - Add `<repo_name>` argument to specify repo (just updates that repo)
 - Add `--stash` parameter to stash changes and pull (for Git repos)

`encrypt.sh` and `decrypt.sh`
-----------------------------
 - Remove .enc extension of encrypted files, if present.
 - Allow multiple inputs to `encrypt.sh` (and `decrypt.sh`?) and maybe tar them up and encrypt the tar

Others
------
 + Write a `hashdir` script that recursively hashes a directory with SHA256
 + Fix `gacp` to check for the last commit message, and if it's the same as the current one, it should not commit nor push.
 + Write a script that renames "Bad Linux File Name" into "better-linux-file-name"
 + Figure out how to handle ambiguities in `clone.sh`

