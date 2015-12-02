#!/usr/bin/env python2.7

import os
import re
import subprocess
from multiprocessing.pool import ThreadPool
from pylibs.colors import *
from pylibs.repodir import REPOS_DIRS

pool = ThreadPool(16)
procs = []


def create_proc(cmd, d):
    """ This runs in a separate thread. """
    p = subprocess.Popen(
        cmd,
        cwd=d,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    out, err = p.communicate()
    return (out, err, p.returncode)


def git_repo_updated(res, d):
    status = cTxtBoldRed + "(updated successfully)"
    stdout, stderr, errcode = res

    if re.compile("Current branch .* is up to date").match(stdout):
        status = cTxtBoldGreen + "(already up-to-date)"
    elif re.compile("Cannot pull with rebase: You have unstaged changes\.").match(stderr):
        status = cTxtBoldRed + "(cannot pull, please stash changes first)"
    elif errcode != 0:
        status = cTxtBoldRed + "(unknown error, return code " + str(errcode) + ")"
    else:
        pass
    #    status = cTxtBoldRed + "(unknown Git update status)"

    print cTxtBoldBlue + "[Git] " + cTxtDefault + d + " -> " + status + cTxtDefault


def svn_repo_updated(res, d):
    status = cTxtBoldRed + "(updated successfully)"
    stdout, stderr = res

    if len(stdout) == 0:
        status = cTxtBoldGreen + "(already up-to-date)"

    print cTxtGreen + "[SVN] " + cTxtDefault + d + " -> " + status + cTxtDefault


def lambda_factory(d):
    return lambda res: git_repo_updated(res, d)

print "Looking at repos in '%s' ...\n" % REPOS_DIRS

for reposDir in REPOS_DIRS:
    for d in os.listdir(reposDir):
        os.chdir(reposDir + d)
        if os.path.isdir(".git"):
            cmd = ["git", "pull", "--rebase"]
            t = "git"
            repo_updated = lambda_factory(d)
        elif os.path.isdir(".svn"):
            cmd = ["svn", "update"]
            t = "svn"
        else:
            print d + " -> " + cTxtBoldRed + "(not a repo)" + cTxtDefault
            continue
        os.chdir(reposDir)

        procs.append(pool.apply_async(
            func=create_proc,
            args=(cmd, reposDir + d),
            callback=repo_updated
            )
        )

# Close the pool and wait for each running task to complete
pool.close()
pool.join()
