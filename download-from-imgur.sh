#!/bin/bash

set -u
set -e

USERNAME="${1}"
ACCESS_TOKEN="${2}"

if [[ -z "${USERNAME}" ]]; then
	echo "Undefined USERNAME"
	exit 1
fi

if [[ -z "${ACCESS_TOKEN}" ]]; then
	echo "Undefined ACCESS_TOKEN"
	exit 1
fi

for PAGE in $(seq 1 1000); do
    echo "PAGE $PAGE"
    curl -s --location --request GET https://api.imgur.com/3/account/${USERNAME}/images/${PAGE} --header "Authorization: Bearer ${ACCESS_TOKEN}" > /tmp/result.json
    count=$(cat /tmp/result.json | jq '.data|length')
    if [[ $count -eq 0 ]]; then
        break
    fi
    jq -r '.data[]|.title+" "+.id' < /tmp/result.json | while read title id; do
        DEST="now/${title}"
	if [[ -f "${DEST}" ]]; then
	   continue
        fi
        echo -n "$title..."
	curl -s https://i.imgur.com/${id}.jpg -o "${DEST}"
    done 
    echo " "
done
