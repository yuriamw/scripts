function __dv_svn_ps1
{
  local url res root rev
  readonly local repo_str="Repository Root: "
  readonly local url_str="URL: "
  readonly local rev_str="Revision: "

  while read line; do
    case "$line" in
      "$repo_str"*)
        root=${line%%REP}
        root=${root##*/}
        ;;
      "$url_str"*)
        url=${line##$url_str}
        ;;
      "$rev_str"*)
        rev=${line##$rev_str}
        ;;
    esac
  done <<EOF
$(svn info 2>/dev/null)
EOF

  [ -z "$root" -o -z "$url" -o -z "${rev}" ] && return

  case "$url" in
    *branches*)
      res=${url##*branches/}
      res="${res%% *}"
      res="${res%%/*}*"
      ;;
    *tags*)
      res=${url##*tags/}
      res="${res%% *}"
      res="${res%% *}#"
      ;;
    trunk|*)
      res="trunk"
      ;;
  esac

  [ -z "$res" ] && return

  echo " (${root} ${res} r${rev})"
}
