TODO
====

`encrypt.sh` and `decrypt.sh`
-----------------------------

 - Remove .enc extension of encrypted files, if present.
 - Allow multiple inputs to `encrypt.sh` (and `decrypt.sh`?) and maybe tar them up and encrypt the tar

Others
------

 - Fix up encrypt.sh / decrypt.sh for OS X: make sure after encryption that decryption works
 + Fix `gacp` to check for the last commit message, and if it's the same as the current one, it should not commit nor push.
 + Write a script that renames "Bad Linux File Name" into "better-linux-file-name"
 + [DONE] Write a `hashdir` script that recursively hashes a directory with SHA256
