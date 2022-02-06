#!/usr/bin/env bash

# move to script directory so all relative paths work
cd "$(dirname "$(realpath "$0")")" || exit


pushd .. &> /dev/null

test -d .git || {
    printf "This is not a git repository\n"
    exit 1
}

command -v git &> /dev/null || {
    printf "You must install git in order to pull any changes"
    exit 1
}

if ! git remote -v | grep "https://github.com/OrecX/Oreka.git" &> /dev/null; then
    printf "Adding upstream remote: https://github.com/OrecX/Oreka.git\n"
    git remote add upstream https://github.com/OrecX/Oreka.git
fi

git fetch upstream
git checkout master
# # git merge upstream/master
git rebase upstream/master

popd &> /dev/null