#!/bin/sh

# Copyright 2016 Bugsee, Inc. All rights reserved.
#
# This script copy all dSYMs and bcsymbolmaps into your archive
#
# Usage:
#  * Select target that you need to archive
#  * Open Edit scheme menu for this target
#  * Go to Archive expand dropdown list
#  * Select Post-actions
#  * Press + New Run Script Action
#  * Make sure that you set /bin/sh inside Sell field
#  * Provide build settings from <Check target than you need to archve>
#  * Uncomment and paste the following script.

# --- INVOCATION SCRIPT BEGIN ---
#ARCHIVE_SCRIPT_SRC=$(find "$PROJECT_DIR" -name 'Bugsee_archive_phase.sh' | head -1)
#if [ ! "${ARCHIVE_SCRIPT_SRC}" ]; then
#    echo "Error: Bugsee archive phase script not found. Make sure that you're including Bugsee.framework in your project directory"
#    exit 1
#fi
# --- INVOCATION SCRIPT END ---


echo "Bugsee: Start copy dSYM and bcsymbolmap files inside project archive."

find "${PROJECT_DIR}" -name "*.bcsymbolmap" | (while read -r file
do
cp -r "${file}" "${ARCHIVE_DSYMS_PATH}/../BCSymbolMaps"
done
)

find "${PROJECT_DIR}" -name "*.dSYM" | (while read -r file
do
cp -r "${file}" "${ARCHIVE_DSYMS_PATH}"
done
)

echo "Bugsee: Copy completed."
