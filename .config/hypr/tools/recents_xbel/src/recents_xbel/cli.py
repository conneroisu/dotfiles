from __future__ import annotations

import argparse
import os
import sys
from typing import Optional

from .xbel import (
    ensure_xbel_tree,
    add_or_update_bookmark,
    write_tree,
    default_xbel_path,
)


def _parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="recents-xbel", description="Edit recently-used.xbel safely")
    sub = p.add_subparsers(dest="cmd", required=True)

    add = sub.add_parser("add", help="Add or update a recent file entry")
    add.add_argument("--file", required=True, help="Absolute or relative file path to add")
    add.add_argument("--mime", default=None, help="Mime type, e.g. image/png")
    add.add_argument("--app", default=None, help="Application name associated with this entry")
    add.add_argument("--exec", dest="exec_cmd", default=None, help="Exec command for the application")
    add.add_argument(
        "--xbel-file",
        default=None,
        help="Path to recently-used.xbel (defaults to XDG_DATA_HOME or ~/.local/share)",
    )
    return p.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    ns = _parse_args(argv)
    if ns.cmd == "add":
        xbel_path = ns.xbel_file or default_xbel_path()
        tree = ensure_xbel_tree(xbel_path)
        add_or_update_bookmark(
            tree,
            ns.file,
            app_name=ns.app,
            exec_cmd=ns.exec_cmd,
            mime_type=ns.mime,
        )
        write_tree(tree, xbel_path)
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

