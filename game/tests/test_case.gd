extends RefCounted
## One file of tests: every method whose name starts with test_ is run by run_tests.gd. The scene tree's root, its
## frame signal and its timers are at hand as they would be inside the tree.

var failures := 0
var passed := 0
var root: Window = (Engine.get_main_loop() as SceneTree).root
var process_frame: Signal = (Engine.get_main_loop() as SceneTree).process_frame
const NOTIFICATION_APPLICATION_FOCUS_IN := MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN
const NOTIFICATION_APPLICATION_FOCUS_OUT := MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT


func check(ok: bool, what: String) -> void:
	if ok:
		passed += 1
	else:
		failures += 1
		print("FAIL: " + what)


func create_timer(seconds: float) -> SceneTreeTimer:
	return (Engine.get_main_loop() as SceneTree).create_timer(seconds)
