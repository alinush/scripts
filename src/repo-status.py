#!/usr/bin/env python2.7

import subprocess
import os
import threading
from pylibs.colors import *
from pylibs.repodir import REPO_DIR

lock = threading.Lock()


def repo_get_info(d, t, subproc):
    #subproc.wait()
    stdout, stderr = subproc.communicate()
    with lock:
        if t == "git":
            info = git_get_info(d, stdout)
        elif t == "svn":
            info = svn_get_info(d, stdout)
        else:
            print "ERROR: Did not expect to reach this state: (%s, %s)" % d, t
            os.exit(1)

    print d + " -> " + info + cTxtDefault


def git_get_info(d, status):
    output = cTxtBoldRed + "(has changes)"

    if "nothing to commit, working directory clean" in status:
        output = cTxtBoldGreen + "(no local changes)"

    return cTxtBoldGreen + "Git " + output


def svn_get_info(d, status):
    output = cTxtBoldRed + "(has changes)"

    if len(status) == 0:
        output = cTxtBoldGreen + "(no local changes)"

    return cTxtBoldBlue + "SVN " + output


threads = []

print "Printing status of repositories in '%s'\n" % REPO_DIR

for d in os.listdir(REPO_DIR):
    #print "Looking at '%s' ..." % d
    os.chdir(REPO_DIR + d)
    if os.path.isdir(".git"):
        cmd = ["git", "status"]
        t = "git"
    elif os.path.isdir(".svn"):
        cmd = ["svn", "status"]
        t = "svn"
    else:
        print d + " -> " + cTxtBoldRed + "(not a repo)" + cTxtDefault
        continue
    os.chdir(REPO_DIR)

    sp = subprocess.Popen(
        cmd,
        cwd=REPO_DIR + d,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    thread = threading.Thread(target=repo_get_info, args=[d, t, sp])
    thread.start()
    threads.append(thread)

for th in threads:
    th.join()
