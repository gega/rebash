#!/bin/bash
#
# Copyright by Gergely Gati, written by ChatGPT


TSESS_PATH="$HOME/.local/state/tsess/"


function tsess_cleanup()
{
  for f in $(declare -F | awk '{print $3}' | grep '^tsess_'); do
    unset -f "$f"
  done
}

# https://stackoverflow.com/a/28776166
function tsess_is_sourced()
{
  if [ -n "$ZSH_VERSION" ]; then 
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

tsess_is_sourced && sourced=1 || sourced=0

# https://stackoverflow.com/a/29436423
function tsess_yes_or_no
{
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;  
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}

function tsess_save()
{
  SESSION_ID="$1"
  [ -z "$SESSION_ID" ] && { echo "Usage: tsess-save <session-id>"; return 1; }

  TMP_DIR="$(mktemp -d)"
  mkdir -p "$TMP_DIR/tsess"
  
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)

  # Store metadata
  jq -n \
    --arg cwd "$PWD" \
    --arg title "${TSESS_TITLE:-}" \
    --arg id "${SESSION_ID}" \
    --arg timestamp "${TIMESTAMP}" \
    '{cwd: $cwd, title: $title, id: $id, timestamp: $timestamp}' > "$TMP_DIR/tsess/session.json"

  # Save history
  history -w "$TMP_DIR/tsess/history.sh" 2>/dev/null

  # Save dirs
  dirs -p > "$TMP_DIR/tsess/dirs.txt"

  # Save env delta
  env | sort > "$TMP_DIR/env.now"
  env -i bash -c 'env' | sort > "$TMP_DIR/env.clean"
  comm -23 "$TMP_DIR/env.now" "$TMP_DIR/env.clean" > "$TMP_DIR/tsess/env.env"
  rm "$TMP_DIR"/env.{now,clean}

  # Pack it up
  OUT_FILE="$TSESS_PATH/session-$SESSION_ID.tar.gz"
  mkdir -p "$(dirname "$OUT_FILE")"
  tar -czf "$OUT_FILE" -C "$TMP_DIR" tsess

  rm -rf "$TMP_DIR"
}


function tsess_load()
{
  SESSION_ID="$1"
  [ -z "$SESSION_ID" ] && { echo "Usage: tsess-load <session-id>"; return 1; }

  ARCHIVE="$TSESS_PATH/session-$SESSION_ID.tar.gz"
  [ ! -f "$ARCHIVE" ] && { echo "No session file found: $ARCHIVE"; return 1; }

  TMP_DIR="$(mktemp -d)"
  tar -xzf "$ARCHIVE" -C "$TMP_DIR"

  cd "$(jq -r .cwd "$TMP_DIR/tsess/session.json")" || echo "Warning: could not cd"

  export HISTFILE="$TMP_DIR/tsess/history.sh"
  history -r "$HISTFILE" 2>/dev/null

  while read -r d; do pushd "$d" >/dev/null; done < "$TMP_DIR/tsess/dirs.txt"

  while IFS= read -r line; do export "$line"; done < "$TMP_DIR/tsess/env.env"

  TITLE=$(jq -r .title "$TMP_DIR/tsess/session.json")
  [ -n "$TITLE" ] && echo -ne "\033]0;$TITLE\007"

  rm -rf "$TMP_DIR"
}


function tsess_title()
{
  export TSESS_TITLE=$1
  PS1="\s $TSESS_TITLE\$ "
  echo -ne "\033]0;$TSESS_TITLE\007"
}

function tsess_init()
{
  if [ x"$TSESS_TITLE" == x"" ]; then
    TSESS_TITLE="sh-$$"
  fi
  echo -ne "\033]0;$TSESS_TITLE\007"
  if [ x"$TSESS_SESSION_ID" == x"" ]; then
    export TSESS_SESSION_ID="$(date +%Y%m%d)-$(uuidgen |cut -d- -f1)"
  fi
}

function tsess_delete()
{
  SESSION_ID="$1"
  [ -z "$SESSION_ID" ] && { echo "Usage: tsess-delete <session-id>"; return 1; }

  ARCHIVE="$TSESS_PATH/session-$SESSION_ID.tar.gz"

  #rm -f "$ARCHIVE"
}

if [ $sourced -eq 0 ]; then
  echo "Source this script instead of running!"
  exit 1
fi

tsess_init

case "$1" in
  "save")
    tsess_save "$TSESS_SESSION_ID"
    ;;
  "load")
    tsess_load "$2"
    ;;
  "title")
    tsess_title "$2"
    ;;
  "list")
    find $TSESS_PATH -name "session*tar.gz" -exec tar -xO -f {} tsess/session.json \;|jq -r .id,.title,.timestamp|paste - - -
    ;;
  "info")
    echo $TSESS_TITLE
    echo $TSESS_SESSION_ID
    ;;
   "delete")
    if [ -f "$TSESS_PATH/session-$2.tar.gz" ]; then
      tsess_yes_or_no "Delete session '$2'?" && tsess_delete "$2"
    else
      echo "Session '$2' not found"
    fi
    ;;
  *)
    echo "Usage: $0 [save|load|title|list|info|delete] [parmeters]"
    ;;
esac

tsess_cleanup
