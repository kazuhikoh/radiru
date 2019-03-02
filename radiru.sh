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

Usage: download <id> <filename-prefix> [directory]
  All programs will be downloaded as `<filename-prefix>.YYYYMMDD.N.<headline>-<title>.mp3`

Examples:
  radiru info 4320_01 | jq '.main.detail_list[].file_list[] | {open_time, file_name}'

  radiru info 4320_01 | jq -c '.main.detail_list[].file_list[] | {file_name, open_time, seq, file_title}' | sed -E 's|^.*"file_name":"(.+?)","open_time":"(....)\-(..)\-(..)[^ ]+".*"seq":(.+?),.*"file_title":"(.+?)".*}|ffmpeg -i "\1" "pva.\2\3\4.\5.\6.mp3"|g'

  radiru download 4320_01 pva ~/Videos/pva/
  - All programs of `4320_01` will be downloaded as `pva.YYYYMMDD.N.XXXX.mp3`.
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

# create_download_command <url> <date> <seq> <headline> <title> <filename-prefix> <directory>
function download_execute {
  local url="$1"
  local filename="$6.$2.$3.$4.$5.mp3"
  local filepath="${7%%/}/$filename"

  [ ! -s $filepath ] && {
    echo "Download: $filename"
    ffmpeg -i "$url" "$filepath" >&2
  } || {
    echo "Skip: $filename"
  }
}
export -f download_execute

# download <id> <filename-prefix> [directory]
function download {
  local id=$1
  local prefix="$2"
  local directory="${3:-.}"

  info $id true \
    | xargs -I{} bash -c "download_execute {} \"$prefix\" \"$directory\""
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
  download)
    [ "$1" = "" ] && {
      exit 1
    }
    download "$1" "$2" "$3"
    ;;
  *)
    usage
    ;;
esac
