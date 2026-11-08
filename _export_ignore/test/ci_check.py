#!/usr/bin/env python3
"""Exercise direct dependencies or prove that framework assertion failures reach GDPackage CI."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["direct", "gut", "gdunit4"])
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--project", required=True)
    parser.add_argument("--toolchain-dir", default="addons/gdpackage")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[2]
    env = os.environ.copy()
    env.pop("GDPACKAGE_CI_FAIL", None)
    env.pop("GDPACKAGE_CI_UTIL_R_ONLY", None)
    with tempfile.TemporaryDirectory(prefix="gdpackage-ci-fixture-") as temporary:
        tree = Path(temporary) / "package"
        shutil.copytree(source, tree, ignore=shutil.ignore_patterns(".git", "reports", "exports", ".godot", "__pycache__"))
        if args.mode == "direct":
            env["GDPACKAGE_CI_UTIL_R_ONLY"] = "1"
            config = tree / "_export_ignore/export.yml"
            config.write_text(config.read_text().replace("brohd11/godot-util-package@v0.2.0", "brohd11/godot-util-r@v0.4.0"))
            version = subprocess.check_output([args.godot, "--version"], text=True).strip()
            if version.startswith("4.6."):
                # GUT publishes separate release lines for Godot 4.6 and 4.7.
                config.write_text(config.read_text().replace("bitwes/Gut@v9.7.1", "bitwes/Gut@v9.6.1"))
            for suite in [tree / "_export_ignore/test/gut/test_utilities.gd", tree / "_export_ignore/test/gdunit4/utilities_test.gd"]:
                text = re.sub(r"^const (SugarLib|Sweets) = .*\n", "", suite.read_text(), flags=re.MULTILINE)
                text = re.sub(r"\nfunc test_(sugar|sweet_ui)\(\) -> void:\n.*?(?=\nfunc |\Z)", "\n", text, flags=re.DOTALL)
                suite.write_text(text)
        else:
            env["GDPACKAGE_CI_FAIL"] = args.mode
        subprocess.run(["git", "init", "-q", str(tree)], check=True)
        subprocess.run(["git", "-C", str(tree), "remote", "add", "origin", "https://github.com/brohd11/gdpackage_ci_test.git"], check=True)
        result = subprocess.run([
            args.godot, "--headless", "--path", args.project,
            "--script", f"res://{args.toolchain_dir}/src/class/release/test_cli.gd",
            "--", "addons/gdpackage_ci_test", "--tree", str(tree),
        ], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=1800)
        print(result.stdout, end="")
        reports = [line.removeprefix("PE_TEST_OUTPUT ") for line in result.stdout.splitlines() if line.startswith("PE_TEST_OUTPUT ")]
        if len(reports) != 1:
            raise SystemExit("Expected exactly one completed GDPackage report")
        report = json.loads(reports[0])
        suites = {suite["path"]: suite for suite in report.get("suites", [])}
        if set(suites) != {"clean_reports", "gut", "gdunit4", "verify_reports"}:
            raise SystemExit("Framework execution did not complete")
        expected_exit = {"clean_reports": 0, "gut": 0, "gdunit4": 0, "verify_reports": 0}
        if args.mode != "direct":
            expected_exit[args.mode] = 1 if args.mode == "gut" else 100
            marker = f"INTENTIONAL_{args.mode.upper()}_FAILURE"
            if marker not in "\n".join(suites[args.mode]["output"]):
                raise SystemExit("Expected assertion failure marker is missing")
        for name, expected in expected_exit.items():
            suite = suites[name]
            if suite.get("exit") != expected or suite.get("passed") != (expected == 0) or suite.get("timed_out"):
                raise SystemExit(f"Unexpected {name} result: {suite}")
        expected_failures = int(args.mode != "direct")
        if result.returncode != expected_failures or report["failed"] != expected_failures:
            raise SystemExit("GDPackage did not propagate the expected framework result")
        print(f"Verified {args.mode} integration scenario")


if __name__ == "__main__":
    main()
