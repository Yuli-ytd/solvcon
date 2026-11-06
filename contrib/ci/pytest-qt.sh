#!/bin/bash
#
# Copyright (c) 2026, solvcon team <contact@solvcon.net>
# BSD 3-Clause License, see COPYING

set -eo pipefail

test_target="${1:?A pytest make target is required}"

echo "::group::make pytest BUILD_QT=ON"
if [ "${RUNNER_OS:-}" = "Linux" ]; then
    report_dir="${RUNNER_TEMP:?}/solvcon-native"
    mkdir -p "$report_dir"
    git rev-parse HEAD > "$report_dir/commit.txt"
    python3 --version > "$report_dir/python-version.txt"
    cat /proc/sys/kernel/core_pattern > "$report_dir/original-core-pattern.txt"
    printf '%s/core.%%p\n' "$report_dir" \
        | sudo tee /proc/sys/kernel/core_pattern
    ulimit -c unlimited
    ulimit -c > "$report_dir/core-limit.txt"
fi

python3 -c "import solvcon; assert solvcon.HAS_PILOT == True"
JOB_MAKE_ARGS="${JOB_MAKE_ARGS:-} VERBOSE=1"
if [ "${RUNNER_OS:-}" = "macOS" ]; then
    # Use the installed Qt instead of PySide6's duplicate frameworks.
    pyside6_path=$(python3 -c "import sys, os, PySide6; sys.stdout.write(os.path.dirname(PySide6.__file__))")
    echo "pyside6 path: ${pyside6_path}"
    rm -rf "$pyside6_path"/Qt/lib/*.framework
    install_name_tool -add_rpath "$(qtpaths --install-prefix)/lib" "$pyside6_path/QtWidgets.abi3.so"
    install_name_tool -add_rpath "$(qtpaths --install-prefix)/lib" "$pyside6_path/QtGui.abi3.so"
    install_name_tool -add_rpath "$(qtpaths --install-prefix)/lib" "$pyside6_path/QtCore.abi3.so"
fi
# Without the pilot every pilot test skips, so fail here instead.
python3 -c "from solvcon import pilot; pilot.require('the Qt test step')"
make "$test_target" ${JOB_MAKE_ARGS}
echo "::endgroup::"

# vim: set ff=unix fenc=utf8 et sw=4 ts=4 sts=4:
