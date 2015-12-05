import os

HOME = os.path.expanduser("~")
REPOS_CONF_DIR = os.path.dirname(os.path.realpath(__file__)) + "/.."
REPOS_REMOTES_CONF = REPOS_CONF_DIR + "/remotes.conf"

REMOTES = []

if os.path.isfile(REPOS_REMOTES_CONF):
    with open(REPOS_REMOTES_CONF) as f:
        remotes = [line.strip('\n') for line in f.readlines()]
        # remove whitespace
        remotes = [r.lstrip() for r in remotes]
        # Filter out comments and empty lines
        remotes = [r for r in remotes if len(r) > 0 and r[0] != '#']

    for i in range(0, len(remotes)):
        length = len(remotes[i])
        if remotes[i][length-1] != '/':
            remotes[i] += '/'

    REMOTES.extend(remotes)
