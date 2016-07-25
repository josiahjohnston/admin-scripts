#!/usr/bin/env python

import glob, os, pprint

PSQL_BACKUP = "/data1/psql_backups"
KEEP = 7 # Rotate weekly

# If the change in size is less than this amount, complain loudly
targets = ["switch_gis-*.pg_dump", "switch_gis_globals-*.sql"]

alert_message = "The latest backup ({last_filename}) is {percent_delta} smaller than the last backup ({second_to_last_filename}), which was {old_size} bytes."

to_delete = []

for target in targets:
	files = glob.glob(os.path.join(PSQL_BACKUP, target))
	files.sort(key = lambda el: os.path.getmtime(el), reverse = True)
	to_delete.extend(files[7:])

# Always spam. I want to know when files are deleted
print "Will delete:"
print "\n".join(to_delete)
map(os.unlink, to_delete)
