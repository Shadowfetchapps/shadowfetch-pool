class_name StatsStore
extends RefCounted

const Paths = preload("res://scripts/save/app_paths.gd")


static func empty() -> Dictionary:
	return {
		"games": 0,
		"wins": 0,
		"losses": 0,
		"fouls": 0,
		"shots": 0,
		"balls_pocketed": 0,
	}


static func load_stats() -> Dictionary:
	var path := Paths.stats_path()
	if not FileAccess.file_exists(path):
		return empty()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return empty()
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
		var base := empty()
		for k in base.keys():
			if json.data.has(k):
				base[k] = json.data[k]
		return base
	return empty()


static func save_stats(stats: Dictionary) -> void:
	Paths.ensure_dirs()
	var f := FileAccess.open(Paths.stats_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(stats, "\t"))
