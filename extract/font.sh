#!/bin/bash -e
# Extract the main font graphics.

if ! [[ -d extract/ ]]; then
    echo "Error: Must be run from the repo's top level." 1>&2
    exit 1
fi

args=(--format gb_rows_2bpp --layout V11H16V16)
mkdir -p source/graphics

set -x

tools/dazzlie decode "${args[@]}" -a 0x01017E -i base.gbc -o source/graphics/font.png
echo "${args[@]}" > source/graphics/font.args
