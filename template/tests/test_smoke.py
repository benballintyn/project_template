"""Smoke test: the package imports cleanly.

This exists so a freshly scaffolded project has green CI from the first
commit — pytest exits non-zero when zero tests are collected. Replace or
extend with real tests as the project grows.
"""

import importlib


def test_package_imports() -> None:
    """The top-level package imports without error."""
    assert importlib.import_module("__PACKAGE_NAME__") is not None
