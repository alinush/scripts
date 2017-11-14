#!/usr/bin/env python2.7

import subprocess
import os
import re
import click
import threading
from pylibs.colors import *
from pylibs.repodir import REPOS_DIRS

lock = threading.Lock()
verbosity = 0

def repo_get_info(d, t, subproc, display_only_changed):
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

        has_changes = info[0]
        if (not display_only_changed) or has_changes == True:
            print d + " -> " + info[1] + cTxtDefault


def git_get_info(d, status):
    output = cTxtBoldRed + "(has changes)"
    global verbosity
    has_changes = True

    # TODO: why don't regexes work?
    #if re.compile("Your branch is ahead of '.*' by [0-9]* commits\.").match(status):
    if "git push" in status and "branch is ahead of" in status:
        output = cTxtBoldRed + "(has unpushed commits)"
    elif "nothing to commit, working directory clean" in status or "nothing to commit, working tree clean" in status:
        output = cTxtBoldGreen + "(no local changes)"
        has_changes = False

    if verbosity != 0:
        print d + " -> extra Git output: " + cTxtRed + "[" + status + "]" + cTxtDefault

    return (has_changes, cTxtBoldGreen + "Git " + output)


def svn_get_info(d, status):
    output = cTxtBoldRed + "(has changes)"
    global verbosity

    if len(status) == 0:
        output = cTxtBoldGreen + "(no local changes)"
    elif verbosity != 0:
        print "Extra SVN output: [" + status + "]"

    return cTxtBoldBlue + "SVN " + output


threads = []


@click.command()
@click.argument('dir_name', required=False, type=click.STRING)
@click.option('-v', '--verbose', count=True, help='Displays more detailed information.')
@click.option('--only-changed/--display-all', default=True, help='Only displays repositories that have changes in them.')
def main(dir_name, verbose, only_changed):
    global verbosity
    verbosity = verbose
    if verbosity > 0:
        print "Verbosity:", verbosity
    #print "Only display repositories with changes:", only_changed

    if dir_name is None:
        dirs = REPOS_DIRS
    else:
        dirs = [ dir_name ]

    #print "Printing status of repositories in '%s'" % dirs

    for reposDir in dirs:
        parent = os.path.abspath(reposDir)
        print
        print "Looking at repos in " + cTxtGreen + parent + cTxtDefault + "..."

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

            # TODO: race condition between print call above and print calls in the subprocess
            sp = subprocess.Popen(
                cmd,
                cwd=os.path.join(parent, d),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            thread = threading.Thread(target=repo_get_info, args=[d, t, sp, only_changed])
            thread.start()
            threads.append(thread)

    for th in threads:
        th.join()
    print

if __name__ == '__main__':
    main()

