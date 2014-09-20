#!/usr/bin/env python
import yaml
import sys
import re

values = {"private_dns": {}}

for e in sys.stdin.readlines():
    m = re.compile("private_dns.(.*?)=(.*)$").search(e)
    if not m:
        continue
    
    key = m.group(1).strip()
    if key == "":
        continue

    vals = m.group(2).strip().split(",")
    values["private_dns"][key] = vals

print yaml.dump(values, default_flow_style=False)
