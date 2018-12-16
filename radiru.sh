#!/bin/bash

function usage {
  cat << EOF
Usage: radiru <command> [argument...]

 Commands:
    info  shows on-demand program details. 

Usage: radiru info <id>
  \`id\` is query parameter `p` of url
  (http://www.nhk.or.jp/radio/ondemand/detail.html?p=4320_01 --> `4320_01`)

Examples:
  radiru info 4320_01 | jq '.main.detail_list[].file_list[] | {open_time, file_name}'

  radiru info 4320_01 | jq -c '.main.detail_list[].file_list[] | {file_name, open_time, seq, file_title}' | sed -E 's|^.*"file_name":"(.+?)","open_time":"(....)\-(..)\-(..)[^ ]+".*"seq":(.+?),.*"file_title":"(.+?)".*}|ffmpeg -i "\1" "pva.\2\3\4.\5.\6.mp3"|g'

EOF
}

function ondemandUrl {
  local id="$1"
  local filepath="$2"

  local id1=${id%_*}

  local url="http://www.nhk.or.jp/radioondemand/json/${id1}/bangumi_${id}.json"
  echo $url
}

# info <id>
function info {
  local url=$(ondemandUrl $1)

  curl "$url" 
}

subcommand="$1"
shift

case "$subcommand" in
  info)
    [ "$1" = "" ] && {
      exit 1
    }
    info "$1"
    ;;
  *)
    usage
    ;;
esac
