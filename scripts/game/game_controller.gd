class_name PoolGameController
extends Node3D

var engine := EightBallEngine.new()
var table: PoolTable
var balls: Dictionary = {}
var camera: Camera3D
var ui: PoolHUD
var aiming := true
var aim_dir := Vector3.RIGHT
var power := 1.4
var english := Vector2.ZERO
var placing_cue := false
var events := ShotEvents.new()
var first_contact_done := false
var rails_seen: Dictionary = {}
var _busy := false
var _stats: Dictionary = {}
var _traj: MeshInstance3D
var _ai_pending := false
var _settle_frames := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = StatsStore.load_stats()
	engine.reset(GameSession.mode)
	_world()
	_rack()
	ui = PoolHUD.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.setup(engine)
	ui.shoot_requested.connect(_player_shoot)
	ui.pause_requested.connect(_toggle_pause)
	ui.restart_requested.connect(_restart)
	ui.settings_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")
	)
	ui.menu_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	ui.quit_requested.connect(func(): get_tree().quit())
	table.ball_pocketed.connect(_on_pocket)
	_handle_cli()


func _world() -> void:
	var env_n := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.045, 0.05, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.4)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = SettingsStore.quality_effects()
	env_n.environment = env
	add_child(env_n)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -25, 0)
	key.light_energy = 1.15
	key.shadow_enabled = SettingsStore.quality_shadows()
	add_child(key)
	table = PoolTable.new()
	add_child(table)
	camera = Camera3D.new()
	camera.fov = 42
	camera.position = Vector3(0, 2.15, 1.55)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0.05))
	_traj = MeshInstance3D.new()
	var im := ImmediateMesh.new()
	_traj.mesh = im
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_color = Color(0.85, 0.9, 1.0, 0.7)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_traj.material_override = tm
	add_child(_traj)


func _rack() -> void:
	for c in balls.values():
		if c is Node:
			c.queue_free()
	balls.clear()
	var pos := table.rack_positions(engine.mode)
	var ids: Array = pos.keys()
	for id in ids:
		var b := PoolBall.new()
		b.setup(int(id))
		add_child(b)
		b.park(pos[id])
		if int(id) == 0:
			b.body_entered.connect(_on_cue_hit)
		balls[int(id)] = b


func _on_cue_hit(body: Node) -> void:
	if not _busy:
		return
	if body is PoolBall:
		var oid := (body as PoolBall).ball_id
		if oid == 0:
			return
		if not first_contact_done:
			first_contact_done = true
			events.first_contact = oid
			events.contacted_any = true
			AudioManager.play("hit")


func _on_pocket(id: int) -> void:
	if not balls.has(id):
		return
	var b: PoolBall = balls[id]
	if not b.visible:
		return
	b.pocket()
	if id == 0:
		events.cue_pocketed = true
	elif id not in events.pocketed:
		events.pocketed.append(id)
	AudioManager.play("pocket")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if get_tree().paused or _busy:
		return
	if event is InputEventMouseMotion:
		_update_aim()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			power = minf(power + 0.08, 3.0)
			ui.set_power(power)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			power = maxf(power - 0.08, 0.35)
			ui.set_power(power)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and engine.ball_in_hand:
			placing_cue = true
			_place_cue_at_mouse()
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and placing_cue:
			placing_cue = false
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not engine.ball_in_hand and _is_human():
			_player_shoot()


func _process(_dt: float) -> void:
	if placing_cue:
		_place_cue_at_mouse()
	if aiming and not _busy:
		_draw_traj()
	if _busy:
		_settle_frames += 1
		_watch_rails()
		if _settle_frames > 18 and _all_sleeping():
			_finish_shot()


func _is_human() -> bool:
	if engine.mode == PoolTypes.Mode.PRACTICE:
		return true
	if GameSession.local_multi:
		return true
	if not GameSession.vs_ai:
		return true
	return engine.current == 0


func _update_aim() -> void:
	var hit := _mouse_on_table()
	if hit == Vector3.INF:
		return
	var cue: PoolBall = balls.get(0)
	if cue == null:
		return
	var d := hit - cue.global_position
	d.y = 0
	if d.length() > 0.02:
		aim_dir = d.normalized()


func _mouse_on_table() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t := -from.y / dir.y
	return from + dir * t


func _place_cue_at_mouse() -> void:
	var p := _mouse_on_table()
	if p == Vector3.INF:
		return
	p = table.clamp_cue_ball(p, engine.phase == PoolTypes.Phase.BREAK)
	var cue: PoolBall = balls.get(0)
	if cue:
		cue.restore(p)


func _player_shoot() -> void:
	if _busy or not aiming:
		return
	if engine.ball_in_hand:
		ui.set_status("Place the cue ball first")
		return
	_strike(aim_dir, power, english)


func _strike(dir: Vector3, pwr: float, eng: Vector2) -> void:
	engine.begin_shot()
	events = ShotEvents.new()
	first_contact_done = false
	rails_seen.clear()
	_busy = true
	_settle_frames = 0
	aiming = false
	_traj.visible = false
	var cue: PoolBall = balls[0]
	cue.sleeping = false
	cue.apply_central_impulse(dir.normalized() * pwr * 0.28)
	cue.apply_torque_impulse(Vector3(eng.y, 0, -eng.x) * pwr * 0.015)
	AudioManager.play("cue")
	_stats["shots"] = int(_stats.get("shots", 0)) + 1


func _watch_rails() -> void:
	for id in balls.keys():
		var b: PoolBall = balls[id]
		if b == null or not b.visible:
			continue
		var p := b.global_position
		if absf(p.x) > PoolTable.HALF_L - 0.05 or absf(p.z) > PoolTable.HALF_W - 0.05:
			rails_seen[int(id)] = true
			if first_contact_done:
				events.rail_after_first_contact = true
		if p.y < -0.15 or absf(p.x) > PoolTable.HALF_L + 0.35 or absf(p.z) > PoolTable.HALF_W + 0.35:
			if int(id) not in events.off_table:
				events.off_table.append(int(id))
				b.pocket()
		if is_nan(p.x) or is_nan(p.y):
			b.park(Vector3(0, PoolTable.BALL_R, 0))


func _all_sleeping() -> bool:
	for b in balls.values():
		var ball := b as PoolBall
		if ball.visible and ball.is_moving():
			return false
	return true


func _finish_shot() -> void:
	_busy = false
	events.rail_count_on_break = rails_seen.size()
	if not events.contacted_any and events.first_contact < 0:
		events.contacted_any = false
	var res := engine.resolve(events)
	if str(res.get("foul", "")) != "":
		_stats["fouls"] = int(_stats.get("fouls", 0)) + 1
		AudioManager.play("foul")
	_stats["balls_pocketed"] = int(_stats.get("balls_pocketed", 0)) + events.pocketed.size()
	if engine.phase == PoolTypes.Phase.OVER:
		_stats["games"] = int(_stats.get("games", 0)) + 1
		if engine.winner == 0:
			_stats["wins"] = int(_stats.get("wins", 0)) + 1
		else:
			_stats["losses"] = int(_stats.get("losses", 0)) + 1
		AudioManager.play("win" if engine.winner == 0 else "lose")
	if engine.ball_in_hand:
		var cue: PoolBall = balls[0]
		cue.restore(table.clamp_cue_ball(Vector3(-PoolTable.HALF_L * 0.55, PoolTable.BALL_R, 0), engine.phase == PoolTypes.Phase.BREAK))
	StatsStore.save_stats(_stats)
	ui.refresh()
	aiming = engine.phase != PoolTypes.Phase.OVER
	_traj.visible = aiming and SettingsStore.show_trajectory
	if GameSession.self_test:
		var ok := events.contacted_any or events.first_contact >= 0 or not events.pocketed.is_empty()
		print("SELFTEST contact=%s first=%s pocketed=%s foul=%s ok=%s" % [events.contacted_any, events.first_contact, events.pocketed, res.get("foul"), ok])
		get_tree().quit(0 if ok else 1)
	elif _should_ai():
		_ai_pending = true
		await get_tree().create_timer(0.45).timeout
		_ai_shoot()


func _should_ai() -> bool:
	return GameSession.vs_ai and not GameSession.local_multi and engine.mode != PoolTypes.Mode.PRACTICE and engine.phase != PoolTypes.Phase.OVER and engine.current == 1


func _ai_shoot() -> void:
	if engine.ball_in_hand:
		var cue: PoolBall = balls[0]
		cue.restore(table.clamp_cue_ball(Vector3(-0.4, PoolTable.BALL_R, 0), false))
		engine.ball_in_hand = false
	var shot := PoolAI.choose_shot(engine, table, balls, SettingsStore.ai_difficulty)
	_strike(shot.dir, shot.power, shot.english)


func _draw_traj() -> void:
	if not SettingsStore.show_trajectory or not _is_human():
		_traj.visible = false
		return
	_traj.visible = true
	var cue: PoolBall = balls.get(0)
	if cue == null:
		return
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var a := cue.global_position + Vector3(0, 0.01, 0)
	var b := a + aim_dir * 0.85
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_end()
	_traj.mesh = im


func _toggle_pause() -> void:
	if _busy:
		return
	ui.set_paused(not get_tree().paused)


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--self-test" in args:
		GameSession.self_test = true
		await get_tree().process_frame
		_strike(Vector3.RIGHT, 2.2, Vector2.ZERO)
	if "--physics-stress" in args:
		await _physics_stress()
	if "--screenshot" in args:
		await get_tree().create_timer(0.7).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots") if not OS.has_feature("standalone") else "user://screenshots"
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("table.png"))
			print("SCREENSHOT ", dir.path_join("table.png"))


func _physics_stress() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var nan_hits := 0
	var through := 0
	var overlap := 0
	for i in 400:
		engine.reset(PoolTypes.Mode.PRACTICE)
		_rack()
		await get_tree().physics_frame
		var cue: PoolBall = balls[0]
		var dir := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		cue.apply_central_impulse(dir * rng.randf_range(0.6, 3.2))
		for _k in 90:
			await get_tree().physics_frame
			for b in balls.values():
				var p := (b as PoolBall).global_position
				if is_nan(p.x) or is_nan(p.y):
					nan_hits += 1
				if p.y < -0.05 and (b as PoolBall).visible:
					through += 1
			for a in range(16):
				if not balls.has(a) or not (balls[a] as PoolBall).visible:
					continue
				for c in range(a + 1, 16):
					if not balls.has(c) or not (balls[c] as PoolBall).visible:
						continue
					if (balls[a].global_position - balls[c].global_position).length() < PoolTable.BALL_R * 1.4:
						overlap += 1
	print("PHYSICS_STRESS nan=%d through=%d overlap_samples=%d" % [nan_hits, through, overlap])
	get_tree().quit(0 if nan_hits == 0 and through == 0 else 1)
