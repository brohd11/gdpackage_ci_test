extends GdUnitTestSuite

const UString = preload("res://addons/_lib/util_r/src/string/u_string.gd")
const SugarLib = preload("res://addons/_lib/sugar/src/sugar.gd")
const Sweets = preload("res://scripts/sweet_ui/generated/sweets.gd")


func test_util_r() -> void:
	assert_str(UString.dot_join("utility", "test")).is_equal("utility.test")


func test_sugar() -> void:
	assert_bool(SugarLib.any(false, true)).is_true()
	assert_bool(SugarLib.all(true, false)).is_false()


func test_sweet_ui() -> void:
	var label = Sweets.label().text("transitive dependency")
	assert_str(label._control.text).is_equal("transitive dependency")
	label._control.free()


func test_async() -> void:
	await get_tree().process_frame
	assert_str(UString.dot_join("", "awaited")).is_equal("awaited")


func test_failure_switch() -> void:
	assert_str(OS.get_environment("GDPACKAGE_CI_FAIL")).override_failure_message("INTENTIONAL_GDUNIT4_FAILURE").is_not_equal("gdunit4")
