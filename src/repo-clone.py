#!/usr/bin/env python2.7

import os
import subprocess
from multiprocessing.pool import ThreadPool
from pylibs.reporemotes import REMOTES

import click    # command line arguments

cloned = 0
clonedno = -1

def create_proc(cmd, i):
    """ This runs in a separate thread. """
    #print "Popening %s ..." % cmd
    p = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    out, err = p.communicate()
    return (out, err, p.returncode, cmd, i)


def repo_cloned(ret):
    global cloned, clonedno

    stdout, stderr, errcode, cmd, i = ret
    if errcode == 0:
        print "Cloned from " + cmd[2] + " successfully"
        cloned = cloned + 1
        clonedno = i
    else:
        print "INFO: Could not clone from " + cmd[2]
        #print "Error:\n"
        #print "Stdout: %s\n", stdout
        #print "Stderr: %s\n", stderr
        #print "Code:   %s\n", errcode
        pass


@click.command()
@click.argument('repo_name', required=True, type=click.STRING)#, help="The name of the repository to search for.")
@click.argument('dir_name', required=False, type=click.STRING)#, help="Directory where repository will be cloned in.")
def main(repo_name, dir_name):
    print "Looking for repos remotely at '%s' ...\n" % REMOTES

    if dir_name == None:
        dir_name = repo_name

    pool = ThreadPool(16)
    procs = []
    i = 1

    if len(REMOTES) == 0:
        print "ERROR: Please configure remotes in remotes.conf"
        return

    if os.path.isdir(dir_name):
        print "ERROR: Target directory '%s' already exist. Please specify another one (see --help).\n" % dir_name
        return
    else:
        os.mkdir(dir_name)

    for remote in REMOTES:
        while os.path.isdir(repo_name + str(i)):
            i = i+1
        cmd = ["git", "clone", remote + repo_name + ".git", dir_name + str(i)]

        #print "Running %s ..." % cmd
        procs.append(pool.apply_async(
            func=create_proc,
            args=(cmd, i),
            callback=repo_cloned
            )
        )

        i = i+1

    # Close the pool and wait for each running task to complete
    pool.close()
    pool.join()

    print
    if cloned == 1:
        os.rename(dir_name + str(clonedno), dir_name)
        print "Found repository successfully! Stored in '%s' directory." % dir_name
    elif cloned == 0:
        print "No '%s' repository was found!" % repo_name
    else:
        print "WARNING: Found multiple repositories remotely! Cloned all of them in '%s[1-9]*', so please take a look at ALL the directories." % dir_name
    print


if __name__ == '__main__':
    main()
