#!/usr/bin/env python2.7

import os
import re
import click    # command line arguments
import subprocess
from multiprocessing.pool import ThreadPool
from pylibs.colors import *
from pylibs.repodir import REPOS_DIRS

threadPool = ThreadPool(16)


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
    r = os.path.basename(d)

    if re.compile("Current branch .* is up to date").match(stdout):
        status = cTxtBoldGreen + "(already up-to-date)"
    elif re.compile("Cannot pull with rebase: You have unstaged changes\.").match(stderr):
        status = cTxtBoldRed + "(cannot pull, please stash changes first)"
    elif errcode != 0:
        status = cTxtBoldRed + "(unknown error, return code " + str(errcode) + ")"
    else:
        pass
    #    status = cTxtBoldRed + "(unknown Git update status)"

    print cTxtBoldBlue + "[Git] " + cTxtDefault + r + " -> " + status + cTxtDefault


def svn_repo_updated(res, d):
    status = cTxtBoldRed + "(updated successfully)"
    stdout, stderr = res
    r = os.path.basename(d)

    if len(stdout) == 0:
        status = cTxtBoldGreen + "(already up-to-date)"

    print cTxtGreen + "[SVN] " + cTxtDefault + r + " -> " + status + cTxtDefault


def lambda_factory(d, func):
    return lambda res: func(res, d)


def is_repo(d):
    isRepo = True
    repo_updated = None
    cmd = None
    t = "unknown"
    r = os.path.basename(d)

    if os.path.isdir(os.path.join(d, ".git")):
        cmd = ["git", "pull", "--rebase"]
        t = "git"
        repo_updated = lambda_factory(d, git_repo_updated)
        #print "'%s' -> Git" % r
    elif os.path.isdir(os.path.join(d, ".svn")):
        cmd = ["svn", "update"]
        t = "svn"
        repo_updated = lambda_factory(d, svn_repo_updated)
        #print "'%s' -> Git" % r
    else:
        isRepo = False
        #print "'%s' -> unknown" % r

    return (isRepo, cmd, t, repo_updated)


def update_repo(pool, d):
    isRepo, cmd, t, repo_updated = is_repo(d)
    r = os.path.basename(d)

    if isRepo:
        #print "Updating repo '%s' ..." % r
        pool.apply_async(
            func=create_proc,
            args=(cmd, d),
            callback=repo_updated
        )
    else:
        print r + " -> " + cTxtBoldRed + "(not a repo)" + cTxtDefault


def update_repos_dir(pool, reposDir):
    #print "Looking at repoDir '%s' ..." % reposDir
    for d in os.listdir(reposDir):
        update_repo(pool, os.path.join(reposDir, d))


@click.command()
@click.argument('repo_or_dir_name', required=False, type=click.STRING)
def main(repo_or_dir_name):
    if repo_or_dir_name is not None:
        isRepo, _, _, _ = is_repo(repo_or_dir_name)
        if isRepo:
            print "Looking at specified repo '%s' ...\n" % repo_or_dir_name
            update_repo(threadPool, repo_or_dir_name)
        else:
            parent = repo_or_dir_name
            while True:
                parent = os.path.abspath(os.path.join(parent, os.pardir))
                isRepo, _, _, _ = is_repo(parent)
                if isRepo:#
                    print "Looking at parent repo in specified directory '%s' ...\n" % repo_or_dir_name
                    update_repo(threadPool, parent)
                    break

                if parent == '/':
                    break

            if parent == '/':
                print "Looking at repos in specified directory '%s' ...\n" % repo_or_dir_name
                update_repos_dir(threadPool, repo_or_dir_name)
    else:
        print "Looking at repos in preconfigured directories '%s' ...\n" % REPOS_DIRS
        for reposDir in REPOS_DIRS:
            update_repos_dir(threadPool, reposDir)

    # Close the pool and wait for each running task to complete
    threadPool.close()
    threadPool.join()

if __name__ == '__main__':
    main()
