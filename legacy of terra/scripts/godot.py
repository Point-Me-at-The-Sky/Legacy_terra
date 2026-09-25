#!/usr/bin/env python3
"""Run the pinned Godot project; no downloads or system installation."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "godot"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("run", "editor", "test"))
    args = parser.parse_args()
    binary = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not binary:
        sys.exit("Godot not found. Install the pinned standard build and set GODOT_BIN to its executable. See README.md.")
    expected = (PROJECT / ".godot-version").read_text().strip().replace("-", ".")
    try:
        version = subprocess.run([binary, "--headless", "--version"], check=True, text=True, capture_output=True, timeout=15).stdout.strip()
        if not (version == expected or version.startswith(expected + ".")):
            sys.exit(f"Expected Godot {expected}, found {version}. Update the pin deliberately before changing versions.")
        command = [binary, "--path", str(PROJECT)]
        if args.action == "editor":
            command.append("--editor")
        if args.action == "test":
            command += ["--headless", "--script", "res://tests/run.gd"]
            result = subprocess.run(command, text=True, capture_output=True, timeout=60)
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
            # Godot may exit zero on script loading errors; never call that a pass.
            failed = result.returncode or "SCRIPT ERROR:" in result.stderr or "ERROR:" in result.stderr or "Godot checks:" not in result.stdout
            sys.exit(1 if failed else 0)
        sys.exit(subprocess.call(command))
    except (OSError, subprocess.SubprocessError) as error:
        sys.exit(f"Godot could not run: {error}")


if __name__ == "__main__":
    main()
