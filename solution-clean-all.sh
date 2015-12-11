#! /bin/bash -e

DIR=.
if [ 0 -lt $# ]; then
    DIR="$@"
fi

for folder in $DIR; do
  pushd "$folder" > /dev/null
    for app in `find . -maxdepth 1 -type d ! -name '.*'`; do
      echo "=== Cleaning $app ..."
      if [ -d $app/.svn ]; then
        pushd $app > /dev/null
          rm -rf ./*
          svn revert -R .
        popd > /dev/null
      elif [ -d $app/.git ]; then
        pushd $app > /dev/null
          git clean -fdx
        popd > /dev/null
      else
        echo "Unknown CVS type"
      fi
    done
  popd > /dev/null
done
