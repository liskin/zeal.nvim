#!/usr/bin/env bash

set -eu -o pipefail

if [[ $1 == *.htm?(l)#* ]]; then
	file=${1%%#*}
	fragment=${1#*#}
	marker=____PREVIEW_START____

	# find the fragment, insert a marker before it, render HTML as text,
	# and then drop everything up to and including the marker
	"${BASH_SOURCE[0]%/*}"/fragment_marker.py --marker "$marker" --fragment "$fragment" "$file" 2>/dev/null \
		| w3m -T text/html ${FZF_PREVIEW_COLUMNS+-cols "$FZF_PREVIEW_COLUMNS"} -dump 2>/dev/null \
		| sed "1,/$marker/d" \
	&& exit 0
fi

exec w3m ${FZF_PREVIEW_COLUMNS+-cols "$FZF_PREVIEW_COLUMNS"} -dump "$1"
