# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# [...]

# env_save
export ENV_ID=$(echo $$$RANDOM$(date +%s)|sha1sum|awk '{print $1}')
function env_save()
{
  F=~/._SHELL_${ENV_ID}.sh
  truncate -s0 $F
  declare -p|grep -v " -[a-zA-Z]*[r][a-zA-Z]* " >>$F
  echo "T=\$(mktemp)" >>$F
  echo "cat <<\"HISTORY_OVER\" >\${T}" >>$F
  history | cut -c 8- >>$F
  echo "HISTORY_OVER" >>$F
  echo "history -r \${T}" >>$F
  echo "rm -f \${T}" >>$F
  echo "cd "$(pwd) >>$F
  echo "N=\"$(xtitle)\"" >>$F
  echo 'echo -ne "\\033]30;'\${N}'\\007"' >>$F
  echo "trap 'env_save' SIGURG" >>$F
  F2=~/.SHELL_${ENV_ID}.sh
  trap 'env_save' SIGURG
  mv -f "$F" "$F2"
}

HISTFILESIZE=100000
HISTSIZE=100000
