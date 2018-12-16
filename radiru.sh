#!/bin/bash

function usage {
  cat << EOF
Usage: radiru <command> [argument...]

 Commands:
    info  shows archived program details. 

Usage: radiru info [-m] <id>
  \`id\` is query parameter `p` of url
  (http://www.nhk.or.jp/radio/ondemand/detail.html?p=4320_01 --> `4320_01`)

  Options:
  -m Minimum output.

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

# format_info_minimum_output <url> <date> <seq> <headline> <title>
function format_info_minimum_output {
  url=$1
  date=$2
  seq=$3
  headline="$(
    echo "$4" \
      | sed 's; ;_;g' \
      | sed 's;/;／;g' \
      | sed 's;*;＊;g' \
  )"
  title="$(
    echo "$5" \
      | sed 's; ;_;g' \
      | sed 's;/;／;g' \
      | sed 's;*;＊;g' \
  )"
 
  echo $url $date $seq $headline $title
}
export -f format_info_minimum_output

# info <id> [minimum]
function info {
  local url=$(ondemandUrl $1)
  local minimum=${2:-false}
 
  if $minimum ; then
    curl "$url" \
      | jq -c '.main.detail_list[] | {headline, file_list:.file_list[] | {file_name, open_time, seq, file_title}}' \
      | sed -E 's|^.*"headline":"(.+?)",.*"file_name":"(.+?)","open_time":"(....)\-(..)\-(..)[^ ]+".*"seq":(.+?),.*"file_title":"(.+?)".*}|\2 \3\4\5 \6 "'\''"\1"'\''" "'\''"\7"'\''"|g' \
      | xargs -I{} bash -c "format_info_minimum_output {}"
  else
    curl "$url"
  fi 
}

subcommand="$1"
shift

while getopts m opts
do
  case $opts in
    m)
      OUTPUT_MINIMUM=true
      ;;
  esac
done
shift $(($OPTIND - 1))

case "$subcommand" in
  info)
    [ "$1" = "" ] && {
      exit 1
    }
    info "$1" "$OUTPUT_MINIMUM"
    ;;
  *)
    usage
    ;;
esac
