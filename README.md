# radiru
radiru CLI

:radio: [NHKラジオ らじる★らじる 聴き逃し](http://www.nhk.or.jp/radio/ondemand/detail.html)

# Requirements
- curl

# Features

## On-demand Program Details

`./radiru.sh info <id>` shows all programs in available (as json).
- `id`: query parameter `p` of url (http://www.nhk.or.jp/radio/ondemand/detail.html?p=4320_01 --> `4320_01`)

```
% ./radiru.sh info 4320_01 | jq .
```

example) shows streaming urls & downloads mp3.
```
% ./radiru.sh info 4320_01 | jq '.main.detail_list[].file_list[] | {open_time, file_name}'
{
  "open_time": "2018-09-12T18:00:00+09:00",
  "file_name": "https://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.m3u8"
}
...

% ffmpeg -i 'https://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.m3u8' out.mp3
```
