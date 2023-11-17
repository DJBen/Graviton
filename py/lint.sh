#!/bin/bash
set -eux

MAX_LINE_LENGTH=120

for file in *.py; do
    echo "Processing $file..."
    isort $file
    black --line-length $MAX_LINE_LENGTH --preview $file
done
