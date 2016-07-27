#!/bin/bash
#
# Clear duplicated files from google drive that were created by a buggy google drive
# Mac client.
#
# The google drive Mac client running on the xserve had intermittent glitches
# where it created "clashes": two files with identical names in the same directory
# with the same content. Well, on google drive they had the same name, but the local
# copy would have (1) added the end of the file name eg. "foo (1).txt". In all cases
# I examined the file content was identical.
# I wrote this script to search for files matching this pattern, check if their content
# differs, and to delete duplicated content/names.
#
# Copyleft 2016 Josiah Johnston, some rights reserved.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
target=$1
delete_duplicate_in_cloud=1
find $target -regex '.* ([0-9]+).*' | while read p; do
	p_base=$(echo $p | sed -e 's/ ([0-9]*)//')
	if [ ! -f "$p_base" ]; then
		echo mv \"$p\" \"$p_base\"
		mv "$p" "$p_base"
		continue
	fi
	r=$(diff -q "$p" "$p_base")
	if [ -z "$r" ]; then
		if [ $delete_duplicate_in_cloud ]; then 
			last_file_id=$(drive clashes "$p_base" 2>&1 | tail -1 | sed -e 's/^.* //')
			if [ ! -z "$last_file_id" ]; then
				echo "drive trash -quiet -id $last_file_id # $p_base"
				drive trash -quiet -id $last_file_id
			fi
		fi
		echo rm \"$p\"
		rm "$p"
	else
		echo Files differ, keeping files: \"$p\"
	fi
done
