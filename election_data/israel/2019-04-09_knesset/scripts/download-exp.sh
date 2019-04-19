#!/bin/bash

##############################################################################
# download-exp.sh
# ------------------------------------------
# Download exported election data in CSV format.
#
# Usage:
#       download-exp.sh
#
# :authors: Omer Sne, @omersne, 0x65A9D22B299BA9B5
# :date: 2019-04-10
# :version: 0.0.1
##############################################################################

set -ex
shopt -s extglob
shopt -s nullglob

URLS=( https://media21.bechirot.gov.il/files/exp{b,c}.csv )

exists_in_path()
{
    which "$1" > /dev/null 2>&1
}

get_file_digest()
{
    local filename="$1"

    local sha512sum="sha512sum"
    if ! exists_in_path "$sha512sum"; then
        sha512sum="g$sha512sum"
    fi

    "$sha512sum" "$filename" | awk '{print $1}'
}

cleanup()
{
    rm -f "$tmp_filename"
}

tmp_filename="$(mktemp /tmp/election_data_XXXXXXXX)"
[ -n "$tmp_filename" ]
trap cleanup EXIT

for url in "${URLS[@]}"; do
    basename="$(basename "$url")"
    base_filename="${basename%.*}"
    extension="${basename##*.}"
    # XXX: Define $new_filename before the `wget' command so the date will be more accurate.
    new_filename="${base_filename}_$(date-for-filename.sh).$extension"
    wget -O "$tmp_filename" "$url"

    new_file_digest="$(get_file_digest "$tmp_filename")"
    for csv_file in ${base_filename}_20*; do
        if [ "$(get_file_digest "$csv_file")" == "$new_file_digest" ]; then
            echo "--- The version of ${basename} with the digest $new_file_digest already exists ---"
            continue 2
        fi
    done

    mv "$tmp_filename" "$new_filename"
done
