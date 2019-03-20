range(0; .count; $ENV.PER|tonumber)
| {
  "query": {
    "match_all": {}
  },
  "from": .,
  "size": $ENV.PER|tonumber
}

