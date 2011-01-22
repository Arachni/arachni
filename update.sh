#!/bin/sh
#
# Simple updater script (work in progress)
#

git=`which git | tail -1`

if test -n "$git" ; then
    echo "Updating current branch..."
    echo
    git pull origin `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    echo "Done."
    echo
else
    echo "Could not find 'git' command."
fi
