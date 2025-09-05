import os
import tempfile
import unittest
from xml.etree import ElementTree as ET

from recents_xbel.xbel import (
    ensure_xbel_tree,
    add_or_update_bookmark,
    write_tree,
)


def read_text(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()


class TestXBEL(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmpdir.cleanup)
        self.tmp = self.tmpdir.name

    def test_create_new_file_and_add(self):
        xbel = os.path.join(self.tmp, "recently-used.xbel")
        tree = ensure_xbel_tree(xbel)
        add_or_update_bookmark(tree, os.path.join(self.tmp, "a.png"), app_name="Grim", mime_type="image/png")
        write_tree(tree, xbel)

        xml = read_text(xbel)
        root = ET.fromstring(xml)
        self.assertIn(root.tag, ("xbel", "recent-files"))
        bms = root.findall("bookmark")
        self.assertEqual(len(bms), 1)
        bm = bms[0]
        self.assertTrue(bm.get("href", "").startswith("file://"))
        self.assertTrue(bm.get("added"))
        self.assertTrue(bm.get("modified"))
        self.assertTrue(bm.get("visited"))
        mime = bm.find(".//{http://www.freedesktop.org/standards/shared-mime-info}mime-type")
        self.assertIsNotNone(mime)
        self.assertEqual(mime.get("type"), "image/png")

    def test_update_existing_increments_count(self):
        xbel = os.path.join(self.tmp, "recently-used.xbel")
        tree = ensure_xbel_tree(xbel)
        add_or_update_bookmark(
            tree, os.path.join(self.tmp, "b.png"), app_name="Grim", mime_type="image/png"
        )
        write_tree(tree, xbel)

        tree2 = ensure_xbel_tree(xbel)
        add_or_update_bookmark(
            tree2, os.path.join(self.tmp, "b.png"), app_name="Grim", mime_type="image/png"
        )
        write_tree(tree2, xbel)

        xml = read_text(xbel)
        root = ET.fromstring(xml)
        bm = root.find("bookmark")
        self.assertIsNotNone(bm)
        app = bm.find(".//{http://www.freedesktop.org/standards/desktop-bookmarks}application")
        self.assertIsNotNone(app)
        self.assertEqual(app.get("name"), "Grim")
        self.assertEqual(app.get("count"), "2")

    def test_handles_legacy_recent_files_root(self):
        xbel = os.path.join(self.tmp, "recently-used.xbel")
        with open(xbel, "w", encoding="utf-8") as f:
            f.write("<?xml version='1.0' encoding='utf-8'?><recent-files></recent-files>")
        tree = ensure_xbel_tree(xbel)
        add_or_update_bookmark(tree, os.path.join(self.tmp, "c.png"), mime_type="image/png")
        write_tree(tree, xbel)

        xml = read_text(xbel)
        root = ET.fromstring(xml)
        self.assertIn(root.tag, ("xbel", "recent-files"))
        bm = root.find("bookmark")
        self.assertIsNotNone(bm)
