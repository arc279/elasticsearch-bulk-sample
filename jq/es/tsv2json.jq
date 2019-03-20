split("\n")[:-1]
| map(split("\t"))
| .[]
| {
  "value": .[0],
  "@timestamp": .[1]
}

