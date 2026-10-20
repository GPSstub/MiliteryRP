"""Regression checks: rebuilding a test place must never destroy the real map."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("military_build_place", ROOT / "tools" / "build_place.py")
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SafePlaceBuildTests(unittest.TestCase):
    def test_build_test_place_without_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "scratch.rbxlx"
            module.build(target)
            ET.parse(target)
            with self.assertRaises(FileExistsError):
                module.build(target)
            module.build(target, overwrite=True)
            ET.parse(target)

    def test_full_map_cannot_be_overwritten_even_with_force(self):
        original = ROOT / "MilitaryRP.rbxlx"
        with self.assertRaises(ValueError):
            module.build(original, overwrite=True)
        with tempfile.TemporaryDirectory() as directory:
            alias = Path(directory) / "map-alias.rbxlx"
            alias.symlink_to(original)
            with self.assertRaises(ValueError):
                module.build(alias, overwrite=True)


if __name__ == "__main__":
    unittest.main()
