class_name TestSettingsStore
extends RefCounted

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	var created := false
	var store: Node = Engine.get_main_loop().root.get_node_or_null("SettingsStore")
	if store == null:
		store = load("res://scripts/save/settings_store.gd").new()
		Engine.get_main_loop().root.add_child(store)
		created = true
	store.reset_to_defaults()
	store.master_volume = 0.33
	store.show_trajectory = false
	store.save_settings()
	store.reset_to_defaults()
	store.load_settings()
	_ok(is_equal_approx(store.master_volume, 0.33), "persist volume")
	_ok(store.show_trajectory == false, "persist trajectory")
	var f := FileAccess.open(store.settings_path(), FileAccess.WRITE)
	f.store_string("{bad")
	f.close()
	store.load_settings()
	_ok(is_equal_approx(store.master_volume, 0.85), "corrupt recover")
	if created:
		store.queue_free()
	print("Settings checks: %d  failures: %d" % [_checks, _failures.size()])
	for m in _failures:
		print("FAIL: ", m)
	return _failures.is_empty()


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
