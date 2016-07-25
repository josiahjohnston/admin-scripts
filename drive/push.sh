#!/bin/bash

# SYNOPSIS:
#  # cd drive_dir
#  drive init # Enter url into browser, copy & pasted authorization code into command line
#  push.sh [upload_subdir] [dir_to_resume_from]
#
# The first argument is optional and will default to '.'
# The second argument is optional. If specified, uploads will skip everything before dir_to_resume_from.
# You may use the second param to resume interrupted uploads, starting after the last successfully uploaded directory.
#
# The unofficial google drive client for linux, https://github.com/odeke-em/drive was unreliable and buggy
# when I told it to recursively process a large complex directory several terabytes large.
# My workaround was to break the task into small pieces of each individual directory, plus the files
# in it (not in its subdirectories).
#
# I found I sometimes needed checkpointing capabilities .. restart the upload from its last completed
# edirectory. I have been uploading for over a month now, and sometimes the backup snapshot directories
# I am uploading from are deleted by the backup rotation script.

if [ -z "$1" ]; then
    upload_subdir="."
else
    upload_subdir="$1"
fi
resume_from=$2

find $upload_subdir -type d | while read d; do
    echo "Uploading $d";
    if [ -n "$resume_from" ] && [ "$d" \< "$resume_from" ]; then
        continue;
    fi;
    drive push -no-prompt -ignore-name-clashes --depth 2 "$d";
done

