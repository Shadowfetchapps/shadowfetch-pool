extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.04)
	add_child(bg)
	_preview()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	box.offset_left = 56
	box.offset_right = 500
	box.offset_top = 72
	box.offset_bottom = -72
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var k := Label.new()
	k.text = "REGULATION CLOTH"
	k.add_theme_color_override("font_color", ThemeFactory.accent())
	box.add_child(k)
	var title := Label.new()
	title.text = "Shadowfetch"
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Pool"
	sub.add_theme_font_size_override("font_size", 30)
	box.add_child(sub)
	var blurb := Label.new()
	blurb.text = "8-Ball, 9-Ball, and practice. Honest fouls. No cheat physics."
	blurb.add_theme_color_override("font_color", ThemeFactory.muted())
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(blurb)
	box.add_child(_btn("PLAY", func(): _start(PoolTypes.Mode.EIGHT_BALL, true)))
	box.add_child(_btn("GAME MODES", func(): get_tree().change_scene_to_file("res://scenes/menus/game_modes.tscn")))
	box.add_child(_btn("HOW TO PLAY", func(): get_tree().change_scene_to_file("res://scenes/menus/how_to_play.tscn")))
	box.add_child(_btn("STATISTICS", func(): get_tree().change_scene_to_file("res://scenes/menus/statistics.tscn")))
	box.add_child(_btn("SETTINGS", func(): get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")))
	box.add_child(_btn("QUIT", func(): get_tree().quit()))
	SettingsStore.apply_display()
	SettingsStore.apply_audio()
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.6).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("menu.png"))
			print("SCREENSHOT ", dir.path_join("menu.png"))
	if "--self-test" in args:
		GameSession.reset_defaults()
		GameSession.self_test = true
		GameSession.vs_ai = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game.tscn")


func _preview() -> void:
	var wrap := SubViewportContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.stretch = true
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	wrap.add_child(vp)
	add_child(wrap)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.03, 0.04, 0.04)
	e.ambient_light_energy = 0.5
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.4, 0.38)
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 20, 0)
	light.shadow_enabled = true
	world.add_child(light)
	var t := PoolTable.new()
	world.add_child(t)
	var pos := t.rack_positions(PoolTypes.Mode.EIGHT_BALL)
	for id in pos.keys():
		var b := PoolBall.new()
		b.setup(int(id))
		world.add_child(b)
		b.freeze = true
		b.global_position = pos[id]
	var cam := Camera3D.new()
	cam.fov = 36
	world.add_child(cam)
	var tw := create_tween().set_loops()
	tw.tween_method(func(a: float):
		if is_instance_valid(cam):
			cam.position = Vector3(sin(a) * 2.4, 2.1, cos(a) * 2.4)
			cam.look_at(Vector3.ZERO)
	, 0.2, 0.2 + TAU, 26.0)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 46
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func _start(mode: PoolTypes.Mode, ai: bool) -> void:
	GameSession.reset_defaults()
	GameSession.mode = mode
	GameSession.vs_ai = ai
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")
