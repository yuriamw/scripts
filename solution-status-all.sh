#! /bin/bash -e

export LC_ALL=C

DIR=.
if [ 0 -lt $# ]; then
    DIR="$@"
fi

for folder in $DIR; do
  pushd "$folder" > /dev/null
    for app in `find . -maxdepth 1 -type d ! -name '.*'`; do
      repo=0
      type=""
      status=""
      lastrev=""
      lastdate=""
      appmsg=$(printf "=== Status of %-32s " "$app")
      if [ -d $app/.svn ]; then
        pushd $app > /dev/null
          type="SVN"
          status="$(svn status)"
          lastrev="$(svn info | sed -n -e 's/Last Changed Rev: //p')"
          lastdate="$(svn info | sed -n -e 's/Last Changed Date: //p')"
        popd > /dev/null
        repo=1
      elif [ -d $app/.git ]; then
        pushd $app > /dev/null
          type="GIT"
          status="$(git status --porcelain)"
          lastrev="$(git log -1 --pretty='%h')"
          lastdate="$(git log -1 --pretty='%ad' --date=iso)"
        popd > /dev/null
        repo=1
      fi
      if [ $repo -eq 1 ]; then
        [ -n "$type" ] && if [ "$type" == "SVN" ]; then x="10"; c="revision"; else x="-10"; c="commit  "; fi; printf "%s %s ${c}: %${x}s Date: %s\n" "$appmsg" "$type" "$lastrev" "$lastdate"
        [ -n "$status" ] && echo "$status"
      fi
    done
  popd > /dev/null
done
