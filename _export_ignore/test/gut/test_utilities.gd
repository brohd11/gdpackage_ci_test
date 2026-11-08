extends GutTest

const UString = preload("res://addons/_lib/util_r/src/string/u_string.gd")
const SugarLib = preload("res://addons/_lib/sugar/src/sugar.gd")
const Sweets = preload("res://scripts/sweet_ui/generated/sweets.gd")


func test_util_r() -> void:
	assert_eq(UString.dot_join("utility", "test"), "utility.test")


func test_sugar() -> void:
	assert_true(SugarLib.any(false, true))
	assert_false(SugarLib.all(true, false))


func test_sweet_ui() -> void:
	var label = Sweets.label().text("transitive dependency")
	assert_eq(label._control.text, "transitive dependency")
	label._control.free()


func test_async() -> void:
	await get_tree().process_frame
	assert_eq(UString.dot_join("", "awaited"), "awaited")


func test_failure_switch() -> void:
	assert_ne(OS.get_environment("GDPACKAGE_CI_FAIL"), "gut", "INTENTIONAL_GUT_FAILURE")
