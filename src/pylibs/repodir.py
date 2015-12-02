import os

HOME =  os.path.expanduser("~")
REPOS_DIRS = [ HOME + '/repos/' ]
REPOS_CONF_DIR = os.path.dirname(os.path.realpath(__file__)) + "/.."
REPOS_CONF = REPOS_CONF_DIR + "/repos.conf"

#print REPOS_CONF

if os.path.isfile(REPOS_CONF):
    with open(REPOS_CONF) as f:
        extraDirs = [line.strip('\n') for line in f.readlines()]

    for i in range(0, len(extraDirs)):
        length = len(extraDirs[i])
        if extraDirs[i][length-1] != '/':
            extraDirs[i] += '/'

    REPOS_DIRS.extend(extraDirs)
