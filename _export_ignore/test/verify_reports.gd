extends SceneTree
## Frameworks may exit zero without discovering tests. Require fresh reports and every fixture test.


func _initialize() -> void:
	var failures = 0
	for framework in ["gut", "gdunit4"]:
		var path = "res://addons/gdpackage_ci_test/_export_ignore/test/reports/%s.xml" % framework if framework == "gut" else "res://addons/gdpackage_ci_test/_export_ignore/test/reports/gdunit4/report_1/results.xml"
		var xml = XMLParser.new()
		if xml.open(path) != OK:
			printerr("Missing framework report: " + path)
			failures += 1
			continue
		var tests = []
		var failed_tests = []
		var active_test = ""
		while xml.read() == OK:
			if xml.get_node_type() != XMLParser.NODE_ELEMENT:
				continue
			match xml.get_node_name():
				"testcase":
					active_test = xml.get_named_attribute_value_safe("name")
					tests.append(active_test)
				"failure", "error", "skipped":
					failed_tests.append(active_test)
		var expected = ["test_util_r", "test_async", "test_failure_switch"]
		if OS.get_environment("GDPACKAGE_CI_UTIL_R_ONLY") != "1":
			expected.append_array(["test_sugar", "test_sweet_ui"])
		var expected_failed = ["test_failure_switch"] if OS.get_environment("GDPACKAGE_CI_FAIL") == framework else []
		tests.sort()
		expected.sort()
		if tests != expected or failed_tests != expected_failed:
			printerr("%s report mismatch: tests=%s failed=%s" % [framework, tests, failed_tests])
			failures += 1
		else:
			print("%s: verified %d executed tests, %d expected failures" % [framework, tests.size(), failed_tests.size()])
	quit(0 if failures == 0 else 1)
