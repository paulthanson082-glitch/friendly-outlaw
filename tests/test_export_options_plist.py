"""
Comprehensive tests for ios/ProNotes/ExportOptions.plist

Tests cover:
- The plist file is present and is valid, well-formed XML
- plistlib can parse it into the expected key/value pairs
- Required export configuration values (method, destination, signing/upload
  options, thinning) match what `xcodebuild -exportArchive` expects
- Boundary/negative checks against unexpected top-level keys or wrong types
"""

import os
import plistlib
import unittest
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PLIST_PATH = os.path.join(REPO_ROOT, "ios", "ProNotes", "ExportOptions.plist")


def _load_plist():
    with open(PLIST_PATH, "rb") as f:
        return plistlib.load(f)


class ExportOptionsPlistTests(unittest.TestCase):
    def test_file_exists(self):
        self.assertTrue(os.path.isfile(PLIST_PATH))

    def test_is_valid_xml(self):
        tree = ET.parse(PLIST_PATH)
        self.assertEqual(tree.getroot().tag, "plist")

    def test_has_apple_plist_doctype_and_version(self):
        with open(PLIST_PATH, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn('<?xml version="1.0" encoding="UTF-8"?>', content)
        self.assertIn("Apple//DTD PLIST 1.0//EN", content)
        self.assertIn('<plist version="1.0">', content)

    def test_is_parseable_as_plist_dictionary(self):
        data = _load_plist()
        self.assertIsInstance(data, dict)

    def test_declares_app_store_export_method(self):
        data = _load_plist()
        self.assertEqual(data["method"], "app-store")

    def test_destination_is_upload(self):
        data = _load_plist()
        self.assertEqual(data["destination"], "upload")

    def test_strips_swift_symbols(self):
        data = _load_plist()
        self.assertIs(data["stripSwiftSymbols"], True)

    def test_does_not_upload_bitcode(self):
        data = _load_plist()
        self.assertIs(data["uploadBitcode"], False)

    def test_uploads_symbols_for_crash_reporting(self):
        data = _load_plist()
        self.assertIs(data["uploadSymbols"], True)

    def test_does_not_compile_bitcode(self):
        data = _load_plist()
        self.assertIs(data["compileBitcode"], False)

    def test_thinning_is_disabled(self):
        data = _load_plist()
        # The raw plist stores this as an XML-escaped literal string value
        # ("&lt;none&gt;") rather than the plist keyword `none`.
        self.assertEqual(data["thinning"], "<none>")

    def test_no_unexpected_top_level_keys(self):
        data = _load_plist()
        expected_keys = {
            "method",
            "destination",
            "stripSwiftSymbols",
            "uploadBitcode",
            "uploadSymbols",
            "compileBitcode",
            "thinning",
        }
        self.assertEqual(set(data.keys()), expected_keys)

    def test_boolean_values_have_actual_boolean_type(self):
        data = _load_plist()
        for key in ("stripSwiftSymbols", "uploadBitcode", "uploadSymbols", "compileBitcode"):
            self.assertIsInstance(data[key], bool, f"{key} should be a boolean")

    def test_string_values_have_actual_string_type(self):
        data = _load_plist()
        for key in ("method", "destination", "thinning"):
            self.assertIsInstance(data[key], str, f"{key} should be a string")

    def test_bitcode_options_are_mutually_consistent(self):
        # uploadBitcode should never be enabled when compileBitcode is disabled,
        # since Apple deprecated bitcode entirely; guards against a regression
        # where these two flags drift out of sync.
        data = _load_plist()
        if data["compileBitcode"] is False:
            self.assertIs(data["uploadBitcode"], False)


if __name__ == "__main__":
    unittest.main()