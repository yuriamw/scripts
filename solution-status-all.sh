#! /bin/bash -e

DIR=.
if [ 0 -lt $# ]; then
    DIR="$@"
fi

for folder in $DIR; do
  pushd "$folder" > /dev/null
    for app in `find . -maxdepth 1 -type d ! -name '.*'`; do
      type=""
      status=""
      lastrev=""
      lastdate=""
      printf "=== Status of %-32s " "$app"
      if [ -d $app/.svn ]; then
        pushd $app > /dev/null
          type="SVN"
          status="$(svn status)"
          lastrev="$(svn info | sed -n -e 's/Last Changed Rev: //p')"
          lastdate="$(svn info | sed -n -e 's/Last Changed Date: //p')"
          popd > /dev/null
      elif [ -d $app/.git ]; then
        pushd $app > /dev/null
          type="GIT"
          status="$(git status --porcelain)"
          lastrev="$(git log -1 --pretty='%h')"
          lastdate="$(git log -1 --pretty='%ad' --date=iso)"
        popd > /dev/null
      else
        echo "Unknown CVS type"
      fi
      [ -n "$lastrev" -a -n "$lastdate" ] && printf "%s Rev: %-10s Date: %s\n" "$type" "$lastrev" "$lastdate"
      [ -n "$status" ] && echo "$status"
    done
  popd > /dev/null
done
