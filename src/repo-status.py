#!/usr/bin/env python2.7

import subprocess
import os
import click
import threading
from pylibs.colors import *
from pylibs.repodir import REPOS_DIRS

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


@click.command()
@click.argument('dir_name', required=False, type=click.STRING)
def main(dir_name):
    if dir_name is None:
        dirs = REPOS_DIRS
    else:
        dirs = [ dir_name ]

    print "Printing status of repositories in '%s'\n" % dirs

    for reposDir in dirs:
        parent = os.path.abspath(reposDir)

        for d in os.listdir(parent):
            if not os.path.isdir(os.path.join(parent, d)):
                continue

            #print "Looking at '%s' in %s ..." % (d, parent)
            os.chdir(os.path.join(parent, d))
            if os.path.isdir(".git"):
                cmd = ["git", "status"]
                t = "git"
            elif os.path.isdir(".svn"):
                cmd = ["svn", "status"]
                t = "svn"
            else:
                with lock:
                    print d + " -> " + cTxtBoldRed + "(not a repo)" + cTxtDefault

                continue

            #print "CWD: %s" % os.getcwd()

            sp = subprocess.Popen(
                cmd,
                cwd=os.path.join(parent, d),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            thread = threading.Thread(target=repo_get_info, args=[d, t, sp])
            thread.start()
            threads.append(thread)

    for th in threads:
        th.join()

if __name__ == '__main__':
    main()

