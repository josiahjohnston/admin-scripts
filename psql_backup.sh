#/bin/sh
# Backup each psql database into a directory format that is suitable for
# rsnapshot's file-level deduplication.

backupdir=/data1/psql_backups

# Backup global stuff like user accounts
pg_dumpall --file="$backupdir/switch_gis_globals.sql" --host=switch-db2.erg.berkeley.edu \
	--username=postgres --globals-only

# Backup each DB
psql --host=switch-db2.erg.berkeley.edu --username=postgres -c \
    'SELECT datname FROM pg_database WHERE datistemplate = false;' -t \
| while read db_name; do
    # Skip blank lines so we don't delete the whole backup dir
    if [ -z "$db_name" ]; then continue; fi; 
    save_path="$backupdir/${db_name}"
    log_path="$backupdir/${db_name}.log"
    err_log="$backupdir/${db_name}.errlog"
    rm -rf ${save_path}
    # Schema only as sql text file
    pg_dump --host=switch-db2.erg.berkeley.edu --username=postgres --format=plain \
	--file="$save_path".schema.sql --schema-only "$db_name" 1>"$log_path" 2>"$err_log"
    # Schema + data as directory file of "custom" binary format, 1 file per table
    # We have to delete the old backup before writing a new one; pg_dump insists on this.
    rm -rf "$save_path"
    pg_dump --host=switch-db2.erg.berkeley.edu --username=postgres --format=directory \
	--file="$save_path" "$db_name" 1>>"$log_path" 2>>"$err_log"
    # Print any errors that came up; these will be emailed to the admins
    if [ -s "$err_log" ]; then
        cat $err_log;
    fi
done

