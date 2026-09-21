class_name AppPaths
extends RefCounted

const APP_ID := "shadowfetch-pool"


static func config_dir() -> String:
	var override := OS.get_environment("SHADOWFETCH_POOL_CONFIG")
	if not override.is_empty():
		return override
	var xdg := OS.get_environment("XDG_CONFIG_HOME")
	if xdg.is_empty():
		xdg = OS.get_environment("HOME").path_join(".config")
	return xdg.path_join(APP_ID)


static func data_dir() -> String:
	var override := OS.get_environment("SHADOWFETCH_POOL_DATA")
	if not override.is_empty():
		return override
	var xdg := OS.get_environment("XDG_DATA_HOME")
	if xdg.is_empty():
		xdg = OS.get_environment("HOME").path_join(".local/share")
	return xdg.path_join(APP_ID)


static func settings_path() -> String:
	return config_dir().path_join("settings.json")


static func stats_path() -> String:
	return data_dir().path_join("statistics.json")


static func ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(config_dir())
	DirAccess.make_dir_recursive_absolute(data_dir())
