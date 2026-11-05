# Copyright (c) 2026, solvcon team <contact@solvcon.net>
# BSD 3-Clause License, see COPYING

"""Compare message-test isolation and GC protection for theme crashes."""

import gc
import os
from pathlib import Path
import subprocess
import sys

import pytest


RUNS = 3
MESSAGE_TEST = (
    'tests/apps/obsrefl/test_panel.py::StatusReadoutTC::'
    'test_messages_share_the_banner_and_clear_error_outlines')


def pytest_addoption(parser):
    parser.addoption('--theme-gc-probe', default='protect',
                     choices=('skip-message', 'protect'))


def pytest_collection_finish(session):
    mode = session.config.getoption('theme_gc_probe')
    if mode == 'skip-message':
        for item in session.items:
            if item.nodeid == MESSAGE_TEST:
                item.add_marker(pytest.mark.skip(
                    reason='temporary message-test isolation probe'))
        print('Theme probe: message-test isolation.', flush=True)
        return

    from solvcon import pilot
    pilot.require("the theme GC probe")
    original = pilot.RManager.set_theme

    def protected(self, mode):
        enabled = gc.isenabled()
        gc.disable()
        try:
            return original(self, mode)
        finally:
            if enabled:
                gc.enable()

    pilot.RManager.set_theme = protected
    print('Theme probe: GC protection enabled.', flush=True)


def main():
    root = Path(__file__).resolve().parents[2]
    plugin_dir = Path(__file__).resolve().parent
    command = [
        'make', 'pytest', 'BUILD_QT=ON', 'PYTEST_JOBS=4', 'VERBOSE=1',
        f'RUNENV=PYTHONPATH={root}{os.pathsep}{plugin_dir}',
    ]
    codes = []
    modes = ('skip-message', 'protect', 'protect')
    for attempt, mode in enumerate(modes, 1):
        print(f"::group::Theme probe {attempt}/{RUNS} ({mode})", flush=True)
        options = ('PYTEST_OPTS=-v -s -p probe_theme_gc '
                   f'--theme-gc-probe={mode}')
        result = subprocess.run(command + [options], cwd=root, check=False)
        codes.append(result.returncode)
        print(f"Probe {mode} exit code: {result.returncode}", flush=True)
        print("::endgroup::", flush=True)

    passed = codes.count(0)
    print(f"Theme GC probe: {passed}/{RUNS} runs passed.", flush=True)
    return 0 if passed == RUNS else 1


if __name__ == '__main__':
    sys.exit(main())

# vim: set ff=unix fenc=utf8 et sw=4 ts=4 sts=4 tw=79:
