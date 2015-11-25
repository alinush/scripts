#!/usr/bin/env python2.7

import os
import re
import subprocess
from multiprocessing.pool import ThreadPool
from pylibs.colors import *
from pylibs.repodir import REPO_DIR

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
    return (out, err)


def git_repo_updated(res, d):
    status = cTxtBoldRed + "(updated successfully)"
    stdout, stderr = res

    if re.compile("Current branch .* is up to date").match(stdout):
        status = cTxtBoldGreen + "(already up-to-date)"
    elif re.compile("Cannot pull with rebase: You have unstaged changes\.").match(stderr):
        status = cTxtBoldRed + "(cannot pull, please stash changes first)"
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

for d in os.listdir(REPO_DIR):
    #print "Looking at '%s' ..." % d
    os.chdir(REPO_DIR + d)
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
    os.chdir(REPO_DIR)

    procs.append(pool.apply_async(
        func=create_proc,
        args=(cmd, REPO_DIR + d),
        callback=repo_updated
        )
    )

# Close the pool and wait for each running task to complete
pool.close()
pool.join()
