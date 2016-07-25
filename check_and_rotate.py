#!/usr/bin/env python

import glob, os, sys, re
from pprint import pprint as p

PSQL_BACKUP = "/data1/psql_backups"

# If the change in size is less than this amount, complain loudly
MAX_CHANGE = -0.1
# Keep this many days worth of backups
KEEP_DAYS = 7

target = "switch_gis-*.pg_dump"
additional_globspecs = ["switch_gis-{date}_0100.log", "switch_gis-{date}_0100.err_log", "switch_gis_globals-{date}_0030.sql"]

alert_message = "The latest backup ({last_filename}) is {percent_delta} smaller than the last backup ({second_to_last_filename}), which was {old_size} bytes. Because of this, older dumps were not deleted."

files = glob.glob(os.path.join(PSQL_BACKUP, target))
files.sort(key = lambda file: os.path.getmtime(file), reverse = True)

dates, file_groups = ([], [])

for dump_file in files:
  m = re.search("\d{4}_\d{2}_\d{2}", dump_file)
  dates.append(m.group(0))
  
for file, date in zip(files, dates):
  group = map(lambda spec: os.path.join(PSQL_BACKUP, spec.format(date = date)), additional_globspecs)
  group.append(file)
  file_groups.append(group)

last_two = file_groups[0:2]

# We compare only the last sizes of the pg_dumps, which are the last element of the list because we manually added them.
last_sizes = map(lambda file_group: os.path.getsize(file_group[-1]), last_two)

delta = last_sizes[0] - last_sizes[1]

try:
  delta = float(delta) / last_sizes[1]
except ZeroDivisionError: # Backup was 0 bytes, we're totally shot
  delta = -sys.float_info.max / 100

if delta < MAX_CHANGE:
  print alert_message.format(last_filename = last_two[0], second_to_last_filename = last_two[1], percent_delta = str(-round(delta * 100, 1)) + "%", old_size = last_sizes[1])

else: # Rotate!
  to_delete = file_groups[KEEP_DAYS:]
  to_delete.sort()
  if len(to_delete) > 0:
    print "Will delete:"
    for group in to_delete:
      print "\n".join(group)
      map(os.unlink, group)
