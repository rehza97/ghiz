#!/bin/bash
# Helper script to get current Firebase project ID (macOS compatible)

# Try to get project from firebase use output
PROJECT_OUTPUT=$(firebase use 2>&1)

# Extract project ID from output (works on both macOS and Linux)
# Format: "Now using project spyware-7bfe6" or "* spyware-7bfe6"
if echo "$PROJECT_OUTPUT" | grep -q "Now using project"; then
    echo "$PROJECT_OUTPUT" | grep -oE "Now using project [^ ]+" | awk '{print $4}'
elif echo "$PROJECT_OUTPUT" | grep -qE "^\s+\*"; then
    echo "$PROJECT_OUTPUT" | grep -E "^\s+\*" | head -n1 | sed -E 's/.*\* ([^ ]+).*/\1/'
else
    echo "spyware-7bfe6"  # Default fallback
fi

