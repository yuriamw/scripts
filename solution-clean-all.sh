#! /bin/bash -e

DIR=.
if [ 0 -lt $# ]; then
    DIR="$@"
fi

for folder in $DIR; do
  pushd "$folder" > /dev/null
    if [ -f XX_git_clean.sh ]; then
      ./XX_git_clean.sh
    else
      for app in `find . -maxdepth 1 -type d ! -name '.*'`; do
        if [ -d $app/.svn ]; then
          echo "=== Cleaning (svn) $app ..."
          pushd $app > /dev/null
            rm -rf ./*
            svn revert -R .
          popd > /dev/null
        elif [ -d $app/.git ]; then
          echo "=== Cleaning (git) $app ..."
          pushd $app > /dev/null
            git clean -fdx
          popd > /dev/null
        fi
      done
    fi
  popd > /dev/null
done
