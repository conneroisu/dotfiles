from __future__ import annotations

import os
import time
import datetime as _dt
from typing import Optional
from xml.etree import ElementTree as ET


NAMESPACES = {
    "mime": "http://www.freedesktop.org/standards/shared-mime-info",
    # GNOME/GTK recent files commonly use this prefix for desktop bookmarks
    "ns1": "http://www.freedesktop.org/standards/desktop-bookmarks",
    # Keep legacy bookmark ns registered if present in file, but do not use it for apps
    "bookmark": "http://www.freedesktop.org",
}

# Register namespaces so written XML includes prefixes when used
for prefix, uri in NAMESPACES.items():
    try:
        ET.register_namespace(prefix, uri)
    except Exception:
        # Older Python versions may raise if already registered
        pass


def default_xbel_path() -> str:
    xdg = os.environ.get("XDG_DATA_HOME")
    if xdg:
        return os.path.join(xdg, "recently-used.xbel")
    return os.path.join(os.path.expanduser("~/.local/share"), "recently-used.xbel")


def _utc_now_w3c() -> str:
    # Match observed style: include microseconds and Z suffix
    return _dt.datetime.utcnow().isoformat(timespec="microseconds") + "Z"


def ensure_xbel_tree(path: str) -> ET.ElementTree:
    """Load an XBEL/recent-files XML tree, creating a minimal one if needed.

    Supports both <xbel> and legacy <recent-files> roots.
    """
    if os.path.exists(path) and os.path.getsize(path) > 0:
        try:
            tree = ET.parse(path)
            root = tree.getroot()
            if root.tag in ("xbel", "recent-files"):
                return tree
        except ET.ParseError:
            # Fall through to create new
            pass

    # Create a minimal modern XBEL root
    root = ET.Element("xbel")
    tree = ET.ElementTree(root)
    return tree


def _find_existing_bookmark(root: ET.Element, href: str) -> Optional[ET.Element]:
    for bm in root.findall("bookmark"):
        if bm.get("href") == href:
            return bm
    # Some files may nest bookmarks within folders; perform a broader search
    for bm in root.iter("bookmark"):
        if bm.get("href") == href:
            return bm
    return None


def add_or_update_bookmark(
    tree: ET.ElementTree,
    file_path: str,
    *,
    app_name: Optional[str] = None,
    exec_cmd: Optional[str] = None,
    mime_type: Optional[str] = None,
    timestamp: Optional[str] = None,
) -> None:
    """Add or update a bookmark entry in an XBEL tree.

    - Creates the tree/root if needed (caller should use ensure_xbel_tree).
    - Updates existing entry by refreshing modified/visited times.
    - Adds minimal <info><metadata> with mime type if provided.
    """
    ts = timestamp or _utc_now_w3c()
    abs_path = os.path.abspath(os.path.expanduser(file_path))
    href = f"file://{abs_path}"

    root = tree.getroot()
    existing = _find_existing_bookmark(root, href)

    if existing is None:
        bm = ET.Element("bookmark", attrib={
            "href": href,
            "added": ts,
            "modified": ts,
            "visited": ts,
        })
        # Minimal metadata
        info = ET.SubElement(bm, "info")
        meta = ET.SubElement(info, "metadata", attrib={"owner": "http://freedesktop.org"})
        if mime_type:
            ET.SubElement(meta, f"{{{NAMESPACES['mime']}}}mime-type", attrib={"type": mime_type})
        if app_name:
            apps = ET.SubElement(meta, f"{{{NAMESPACES['ns1']}}}applications")
            app_attrs = {"name": app_name}
            if exec_cmd:
                app_attrs["exec"] = exec_cmd
            app_attrs["count"] = "1"
            app_attrs["modified"] = ts
            ET.SubElement(apps, f"{{{NAMESPACES['ns1']}}}application", attrib=app_attrs)

        root.append(bm)
    else:
        # Update timestamps; adjust application usage if present
        existing.set("modified", ts)
        existing.set("visited", ts)

        # Ensure metadata exists to attach mime/app data
        info = existing.find("info")
        if info is None:
            info = ET.SubElement(existing, "info")
        meta = None
        for m in info.findall("metadata"):
            owner = m.get("owner")
            if owner and "freedesktop.org" in owner:
                meta = m
                break
        if meta is None:
            meta = ET.SubElement(info, "metadata", attrib={"owner": "http://freedesktop.org"})

        if mime_type:
            # Replace or add mime-type
            found = None
            for mt in meta.findall(f"{{{NAMESPACES['mime']}}}mime-type"):
                found = mt
                break
            if found is None:
                ET.SubElement(meta, f"{{{NAMESPACES['mime']}}}mime-type", attrib={"type": mime_type})
            else:
                found.set("type", mime_type)

        if app_name:
            # Migrate any wrongly-namespaced application nodes to the desktop-bookmarks ns
            # Remove bookmark-namespaced apps if present
            for wrong_apps in list(meta.findall(f"{{{NAMESPACES['bookmark']}}}applications")):
                # Move children to correct ns1 and remove wrong element
                correct_apps = meta.find(f"{{{NAMESPACES['ns1']}}}applications")
                if correct_apps is None:
                    correct_apps = ET.SubElement(meta, f"{{{NAMESPACES['ns1']}}}applications")
                for child in list(wrong_apps):
                    attrs = dict(child.attrib)
                    new = ET.SubElement(correct_apps, f"{{{NAMESPACES['ns1']}}}application", attrib=attrs)
                meta.remove(wrong_apps)

            apps = meta.find(f"{{{NAMESPACES['ns1']}}}applications")
            if apps is None:
                apps = ET.SubElement(meta, f"{{{NAMESPACES['ns1']}}}applications")
            # Find matching application node by name
            app_node = None
            for app in apps.findall(f"{{{NAMESPACES['ns1']}}}application"):
                if app.get("name") == app_name:
                    app_node = app
                    break
            if app_node is None:
                attrs = {"name": app_name, "count": "1", "modified": ts}
                if exec_cmd:
                    attrs["exec"] = exec_cmd
                ET.SubElement(apps, f"{{{NAMESPACES['ns1']}}}application", attrib=attrs)
            else:
                # Increment count safely
                try:
                    count = int(app_node.get("count", "0")) + 1
                except ValueError:
                    count = 1
                app_node.set("count", str(count))
                app_node.set("modified", ts)
                if exec_cmd:
                    app_node.set("exec", exec_cmd)


def _indent(elem: ET.Element, level: int = 0) -> None:
    # Pretty-print in-place for readability
    i = "\n" + level * "  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        for child in elem:
            _indent(child, level + 1)
        if not child.tail or not child.tail.strip():  # type: ignore[name-defined]
            child.tail = i
    if level and (not elem.tail or not elem.tail.strip()):
        elem.tail = i


def write_tree(tree: ET.ElementTree, path: str) -> None:
    root = tree.getroot()
    _indent(root)
    # Ensure parent directory exists
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tree.write(path, encoding="utf-8", xml_declaration=True)
