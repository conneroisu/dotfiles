#! recents-xbel

A small, dependency-free Python utility to safely add or update entries in the freedesktop `recently-used.xbel` ("recents xbel") file. It uses only Python's standard `xml.etree.ElementTree`.

## Usage

- Add a file to recents:

```
uv run recents-xbel add --file /absolute/path/to/file.png --mime image/png --app Grim
```

- With Python directly (no install):

```
PYTHONPATH=./tools/recents_xbel/src \
  python3 -m recents_xbel.cli add \
  --file /absolute/path/to/file.png --mime image/png --app Grim
```

The default recents file is `$XDG_DATA_HOME/recently-used.xbel` or `~/.local/share/recently-used.xbel`.

## Testing

```
cd tools/recents_xbel
uv run -m pytest
```

If `uv` or `pytest` are unavailable, you can still run unit tests that don't require third-party packages by installing pytest locally first, or run individual modules directly for smoke checks.

## Notes

- Handles both `<xbel>` and legacy `<recent-files>` roots.
- Ensures well-formed XML, ISO8601 UTC timestamps, and idempotent updates for existing bookmarks.
- Does not require or use `xmlstarlet`.
