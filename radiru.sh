#!/bin/bash

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
esac
