# Copyright (c) 2026, solvcon team <contact@solvcon.net>
# BSD 3-Clause License, see COPYING

"""Style rules for the oblique-shock reflection controls."""

from ... import pilot

__all__ = [
    'Rules',
]


class Rules(pilot.RuleCatalog):
    """Style roles used by the reflection controls."""

    @staticmethod
    def message(shades):
        return f"""
            QFrame#message {{
                border: 1px solid {shades.bright_text.name()};
                border-radius: 6px;
            }}
            QLabel#messageIcon {{
                background-color: {shades.bright_text.name()};
                border-radius: 9px;
                color: {shades.on_base.name()};
                font-weight: bold;
            }}
            QLabel#messageTitle {{
                color: {shades.bright_text.name()};
                font-weight: bold;
            }}
            QLabel#messageDetail {{
                color: {shades.text.name()};
            }}
        """

    @staticmethod
    def error_outline(shades):
        return f"""
            QFrame#errorOutline {{
                border: 1px solid {shades.bright_text.name()};
                border-radius: 4px;
            }}
        """

# vim: set ff=unix fenc=utf8 et sw=4 ts=4 sts=4 tw=79:
