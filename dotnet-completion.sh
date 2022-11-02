# bash parameter completion for the dotnet CLI

# _dotnet_bash_complete()
# {
#   local word=${COMP_WORDS[COMP_CWORD]}
#
#   local completions
#   completions="$(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"
#   if [ $? -ne 0 ]; then
#     completions=""
#   fi
#
#   COMPREPLY=( $(compgen -W "$completions" -- "$word") )
# }
#
# complete -f -F _dotnet_bash_complete dotnet

# bash parameter completion for the dotnet CLI

function _dotnet_bash_complete()
{
  local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n'
  local candidates

  read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)

  read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
}

complete -f -F _dotnet_bash_complete dotnet
