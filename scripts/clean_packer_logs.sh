#!/bin/bash

set -euo pipefail

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

# Remove *.gz and *.1, zero out the rest that are not cloud.init
find /var/log/ -type f -name "*.gz" | xargs rm -f
find /var/log/ -type f -name "*.1" | xargs rm -f
find /var/log/ -type f | grep -v cloud.init | while read f; do
  echo "" > $f
done
