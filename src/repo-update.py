#!/usr/bin/env python2.7

import os
import re
import click    # command line arguments
import subprocess
from multiprocessing.pool import ThreadPool
from pylibs.colors import *
from pylibs.repodir import REPOS_DIRS

threadPool = ThreadPool(16)
verbosity = 0;

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

    if verbosity > 0:
        print d + " -> Git stdout: " + "[" + stdout + "]"
        print d + " -> Git stderr: " + "[" + stderr + "]"

    # NOTE: For some reason adding the ^ character to match at the beginning of the line breaks this.
    # NOTE: For some other reason, "current branch" pattern does not match on Linux, unless multiline is disabled.
    if re.compile("Current branch .* is up to date\.").search(stdout) or re.compile("Already up-to-date\.").search(stdout, re.MULTILINE):
        status = cTxtBoldGreen + "(already up-to-date)"
    # NOTE: For some other reason, adding re.MULTILINE to search prevents this from working.
    elif re.compile("[cC]annot pull with rebase: You have unstaged changes\.").search(stderr):
        status = cTxtBoldRed + "(cannot pull, please stash changes first)"
    elif "You are not currently on a branch." in stderr:
        status = cTxtBoldRed + "(cannot pull, HEAD detached)"
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
        d = os.path.join(reposDir, d)
        if not os.path.isdir(d):
            continue
        update_repo(pool, d)


@click.command()
@click.argument('repo_or_dir_name', required=False, type=click.STRING)
@click.option('-v', '--verbose', count=True, help='Displays more detailed information.')
def main(repo_or_dir_name, verbose):
    global verbosity
    verbosity = verbose
    print "Verbosity:", verbosity

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
