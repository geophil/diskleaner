#!/bin/bash
# Build and launch DiskLeaner
set -e
cd "$(dirname "$0")"
swift build -c release 2>&1 | grep -v "^warning:"
echo "Launching DiskLeaner…"
.build/release/DiskLeaner
