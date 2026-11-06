#!/bin/bash
#
# Copyright (c) 2026, solvcon team <contact@solvcon.net>
# BSD 3-Clause License, see COPYING

set -euo pipefail

report_dir="${RUNNER_TEMP:?}/solvcon-native"
mkdir -p "$report_dir"

shopt -s nullglob
core_files=("$report_dir"/core.*)
if [ "${#core_files[@]}" -eq 0 ]; then
    printf '%s\n' "No core dump was found." > "$report_dir/no-core.txt"
    exit 0
fi

if ! command -v gdb >/dev/null 2>&1; then
    sudo apt-get -qy install gdb > "$report_dir/gdb-install.txt" 2>&1
fi

python_executable="$(readlink -f "$(command -v python3)")"
collect_status=0
for core_file in "${core_files[@]}"; do
    report_file="$report_dir/$(basename "$core_file").stack.txt"
    if timeout --kill-after=10s 180s env DEBUGINFOD_URLS= gdb \
        -q -nx -batch \
        -ex 'set pagination off' \
        -ex 'set debuginfod enabled off' \
        -ex 'info threads' \
        -ex 'thread apply all bt 80' \
        -ex 'info sharedlibrary' \
        "$python_executable" "$core_file" \
        > "$report_file" 2>&1; then
        printf '%s\n' "Created $report_file"
    else
        printf '%s\n' "GDB did not complete successfully." >> "$report_file"
        collect_status=1
    fi
done
exit "$collect_status"

# vim: set ff=unix fenc=utf8 et sw=4 ts=4 sts=4:
