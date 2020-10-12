#! /bin/bash

git log -10 --pretty=format:'{%n  "commit":%H%n  "description":"%s"%n  "cmdref":%S%n  "message":"%B"%n}' origin/rel/charter_27.2.2..origin/rel/charter_28.1
