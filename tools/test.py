"""Compile all Luau sources and run pure regression/fault-injection tests."""
import argparse
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--luau', default=shutil.which('luau'))
parser.add_argument('--compiler', default=shutil.which('luau-compile'))
args = parser.parse_args()
if not args.luau or not args.compiler:
    parser.error('Install the official Luau CLI, or supply --luau and --compiler paths.')
for source in sorted((root / 'src').rglob('*.luau')):
    subprocess.run([args.compiler, str(source)], check=True, stdout=subprocess.DEVNULL)
for test in sorted((root / 'tests').glob('*.spec.luau')):
    subprocess.run([args.luau, str(test)], check=True, cwd=root)
print('All source compilation and pure tests passed.')
