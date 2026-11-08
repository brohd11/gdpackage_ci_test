extends RefCounted

const Labels = preload("labels.gd")


static func run_tests() -> Dictionary:
	var passed = Labels.qualify("native") == "fixture.native"
	return {"result": 0 if passed else 1, "output": ["adjacent native fixture: " + ("PASS" if passed else "FAIL")]}
