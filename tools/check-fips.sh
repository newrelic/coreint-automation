#!/usr/bin/env bash

set -euo pipefail

# Check if a binary file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-binary>"
    exit 1
fi

BINARY_PATH="$1"

# Check if the file exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: File '$BINARY_PATH' not found!"
    exit 1
fi

# Search for FIPS-related strings in the binary
FIPS_STRINGS=$(strings "$BINARY_PATH" | grep -i -e fips -e "FIPS_mode_set" -e "FIPS 140-2")

# Check if any FIPS-related strings were found
if [ -n "$FIPS_STRINGS" ]; then
    echo "The binary '$BINARY_PATH' may be built with FIPS mode. Found the following indicators:"
    echo "$FIPS_STRINGS"
else
    echo "No FIPS-related indicators found in the binary '$BINARY_PATH'."
    exit 1
fi

echo "FIPS compliance check passed."
