import os

HOME =  os.path.expanduser("~")
REPO_DIR = HOME + '/repos/' # TODO: Remove me
REPOS_DIRS = [ HOME + '/repos/' ]

with open("repos.conf") as f:
    extraDirs = [line.strip('\n') for line in f.readlines()]

for i in range(0, len(extraDirs)):
    length = len(extraDirs[i])
    if extraDirs[i][length-1] != '/':
        extraDirs[i] += '/'

REPOS_DIRS.extend(extraDirs)
