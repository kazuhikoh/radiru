# radiru
radiru CLI :radio:

# Requirements
- curl

# Features

## Program Details

show all programs in available.
```
% ./radiru.sh info 4320_01 | jq .
```

show streaming urls.
```
% ./radiru.sh info 4320_01 | jq '.main.detail_list[] | .headline_id, .headline, .file_list[].file_name'
```
