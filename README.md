# GDPackage CI integration fixture

This plugin proves that GDPackage can fetch test dependencies and run standard GUT and GDUnit4
CLI suites in a minimal Godot project. Its editor plugin has no UI or runtime dependencies.

The export configuration pins GUT 9.7.1, GDUnit4 6.2.3, and the declaration-only
`godot-util-package@v0.2.0` under `test_require`. That last package brings in `util_r`, `sugar`,
and `sweet-ui-generated`; each framework calls a utility from every transitive package. All
frameworks and tests are excluded from release exports.

Run from a development project containing GDPackage:

```sh
godot --headless --path . --script res://addons/gdpackage/src/class/release/test_cli.gd -- addons/gdpackage_ci_test
```

The configured commands clean old reports, run both frameworks, then verify that each executed
all five expected tests. Saved framework settings and enabled editor plugins are unnecessary.
GDUnit4's headless override is appropriate here because these tests do not simulate UI input.

GitHub Actions uses GDPackage 0.12.0. The aggregate fixture runs on Godot 4.7 because its utility
sources require that version. A direct `util_r` scenario runs on 4.6.3 and 4.7, with three tests
per framework; it pins GUT 9.6.1 on Godot 4.6 and 9.7.1 on Godot 4.7. Two negative scenarios set `GDPACKAGE_CI_FAIL` to `gut` or `gdunit4`, require the
intended assertion failure and framework exit code, and verify that the other framework and
report checks still complete. Expected failures keep those verification jobs green.

To run an additional scenario locally:

```sh
python3 addons/gdpackage_ci_test/_export_ignore/test/ci_check.py direct --project .
python3 addons/gdpackage_ci_test/_export_ignore/test/ci_check.py gut --project .
python3 addons/gdpackage_ci_test/_export_ignore/test/ci_check.py gdunit4 --project .
```
