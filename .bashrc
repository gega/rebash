# .bashrc

# This is standard part of .bashrc-s, just make sure it's present
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# [...]

# rebash functonality, shell id and save function
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"
export ENV_ID=$(echo $$$RANDOM$(date +%s)|sha1sum|awk '{print $1}')
export HISTFILE=$HOME/.SHELL_history_${ENV_ID}
function wt()
{
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
  export SHELL_NAME="$@"
}
wt "bash$$"
# env_save
function env_save()
{
  F=~/._SHELL_${ENV_ID}.sh
  touch $F
  echo "# $(xtitle) @ $(basename $(pwd))" >$F
  echo "T2_ENV_SAVE=\$(mktemp)" >>$F
  echo "echo \$XAUTHORITY >\${T2_ENV_SAVE}" >>$F
  declare -p|grep -v " -[a-zA-Z]*[r][a-zA-Z]* "|grep -v XAUTHORITY|grep -v DBUS|grep -v T2_ENV_SAVE >>$F
  echo "T1_ENV_SAVE=\$(mktemp)" >>$F
  echo "cat <<\"HISTORY_OVER\" >\${T1_ENV_SAVE}" >>$F
  history | cut -c 8- >>$F
  echo "HISTORY_OVER" >>$F
  echo "history -r \${T1_ENV_SAVE}" >>$F
  echo "export XAUTHORITY=\$(cat \${T2_ENV_SAVE})" >>$F
  echo "rm -f \${T1_ENV_SAVE} \${T2_ENV_SAVE}" >>$F
  echo "dirs -c" >>$F
  dirs -p -l|tac|tail +2|awk '{print "pushd " $1}' >>$F
  echo "cd $(pwd)" >>$F
  echo "export HISTFILE=\$HOME/.SHELL_history_\${ENV_ID}" >>$F
  echo "N=\"${SHELL_NAME}\"" >>$F
  echo 'echo -ne "\\033]30;'\${N}'\\007"' >>$F
  echo "trap 'env_save' SIGURG" >>$F
  F2=~/.SHELL_${ENV_ID}.sh
  trap 'env_save' SIGURG
  mv -f "$F" "$F2"
  touch /tmp/_SHELL_${ENV_ID}.loc
}
for n in $(find ~ -maxdepth 1 -name ".SHELL*sh" -printf "%T@ %p\n"|sort -nr|cut -d' ' -f2|sed -e 's/.*SHELL_//g' -e 's/[.].*$//g')
do
  tt=/tmp/_SHELL_${n}.loc
  if [ ! -f ${tt} ]; then
    source ~/.SHELL_${n}.sh
    env_save
    break
  fi
done


# Optionally, set the history size according to personal preference
# (of course this will affect the saved state of the shells)
HISTFILESIZE=100000
HISTSIZE=100000
