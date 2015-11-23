#!/usr/bin/env python2.7

import subprocess
import os
import threading

lock = threading.Lock()
repoDir = os.path.expanduser("~") + '/repos/'


def wait_for_git(d, t, subproc):
    subproc.wait()
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
cTxtGreen       = '\033[32m'
cTxtBoldGreen   = '\033[1;32m'
cTxtRed         = '\033[31m'
cTxtBoldRed     = '\033[1;31m'
cTxtBlue        = '\033[34m'
cTxtBoldBlue    = '\033[1;34m'
cTxtDefault     = '\033[0m'

print "Printing status of repositories in '%s'\n" % repoDir

for d in os.listdir(repoDir):
    #print "Looking at '%s' ..." % d
    os.chdir(repoDir + d)

    if os.path.isdir(".git"):
        cmd = ["git", "status"]
        t = "git"
    elif os.path.isdir(".svn"):
        cmd = ["svn", "status"]
        t = "svn"
    else:
        print d + " -> " + cTxtBoldRed + "(not a repo)" + cTxtDefault
        continue

    sp = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    os.chdir(repoDir)

    thread = threading.Thread(target=wait_for_git, args=[d, t, sp])
    thread.start()
    threads.append(thread)

for th in threads:
    th.join()
