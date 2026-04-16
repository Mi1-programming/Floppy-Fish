#!/bin/bash
set -e

for F in *.vert *.frag *.comp *.geom *.tesc *.tese; do
    echo "Compiling $F..."
    "binary/glslc" "$F" -o "$F.spv"
done

echo "Done!"
exit 0
