extends SceneTree

const RuleTests = preload("res://tests/test_eight_ball.gd")
const SettingsTests = preload("res://tests/test_settings_store.gd")


func _initialize() -> void:
	print("Running Shadowfetch Pool tests...")
	var tmp := OS.get_user_data_dir().path_join("pool-test-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(tmp)
	OS.set_environment("SHADOWFETCH_POOL_CONFIG", tmp.path_join("config"))
	OS.set_environment("SHADOWFETCH_POOL_DATA", tmp.path_join("data"))
	var ok := RuleTests.new().run_all() and SettingsTests.new().run_all()
	if ok:
		print("ALL TESTS PASSED")
	else:
		print("TESTS FAILED")
	quit(0 if ok else 1)
