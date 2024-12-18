#!/bin/bash

# calculate the percentage of allowed graylog-journal disk-space usage

set -e

JOURNAL_FILE='/usr/share/graylog/data/journal/'
CONFIG_FILE='/etc/graylog/server/graylog.conf'
DEFAULT_MAX_SIZE_GB=5

size="$(du -s $JOURNAL_FILE | cut -d$'\t' -f1)"
cnf="$(grep '^message_journal_max_size' < "$CONFIG_FILE" | cut -d '=' -f2 | sed 's|[gG ]||g')"

if [ -z "$cnf" ]
then
  cnf=$DEFAULT_MAX_SIZE_GB
fi
cnf=$(( cnf * 1024000 ))

python3 -c "print(round(($size / $cnf) * 100))"
