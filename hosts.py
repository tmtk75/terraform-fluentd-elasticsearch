#!/usr/bin/env python
import json
import sys
import re

inventory = {}
for e in sys.stdin.readlines():
    m = re.compile("private_dns\.(.*?)=(.*)$").search(e)
    if not m:
        continue

    key = m.group(1).strip()
    vals = m.group(2).strip().split(",")
    inventory[key] = {"hosts": vals}

    if key == "jump":
        inventory[key]["hosts"] = ["jump"]

    if key == "elasticsearch":
        hostvars = {}
        for i, h in enumerate(vals):
            hostvars[h] = {"service_id": i}
        inventory["_meta"] = {"hostvars": hostvars}

print json.dumps(inventory, indent=4)
