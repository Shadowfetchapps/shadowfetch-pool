class_name PoolHUD
extends CanvasLayer

signal shoot_requested
signal pause_requested
signal restart_requested
signal settings_requested
signal menu_requested
signal quit_requested

var engine: EightBallEngine
var _status: Label
var _turn: Label
var _power: Label
var _pause: PanelContainer


func setup(p_engine: EightBallEngine) -> void:
	engine = p_engine
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ThemeFactory.make()
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 14
	top.offset_bottom = 56
	root.add_child(top)
	_turn = Label.new()
	_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_turn)
	var pause_btn := Button.new()
	pause_btn.text = "PAUSE"
	pause_btn.pressed.connect(func(): pause_requested.emit())
	top.add_child(pause_btn)
	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 20
	_status.offset_right = -20
	_status.offset_top = 56
	_status.offset_bottom = 88
	root.add_child(_status)
	_power = Label.new()
	_power.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_power.offset_left = 24
	_power.offset_top = -70
	_power.offset_right = 360
	_power.offset_bottom = -24
	root.add_child(_power)
	var shoot := Button.new()
	shoot.text = "SHOOT"
	shoot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	shoot.offset_left = -160
	shoot.offset_top = -70
	shoot.offset_right = -24
	shoot.offset_bottom = -24
	shoot.pressed.connect(func(): shoot_requested.emit())
	root.add_child(shoot)
	_pause = PanelContainer.new()
	_pause.visible = false
	_pause.set_anchors_preset(Control.PRESET_CENTER)
	_pause.custom_minimum_size = Vector2(340, 340)
	_pause.offset_left = -170
	_pause.offset_right = 170
	_pause.offset_top = -170
	_pause.offset_bottom = 170
	_pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(_pause)
	var pv := VBoxContainer.new()
	_pause.add_child(pv)
	var t := Label.new()
	t.text = "Paused"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(t)
	pv.add_child(_p("RESUME", func(): set_paused(false)))
	pv.add_child(_p("RESTART", func(): restart_requested.emit()))
	pv.add_child(_p("SETTINGS", func(): settings_requested.emit()))
	pv.add_child(_p("MAIN MENU", func(): menu_requested.emit()))
	pv.add_child(_p("QUIT", func(): quit_requested.emit()))
	refresh()


func _p(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func set_paused(v: bool) -> void:
	_pause.visible = v
	get_tree().paused = v


func set_status(t: String) -> void:
	if _status:
		_status.text = t


func set_power(p: float) -> void:
	if _power:
		_power.text = "Power  %.2f   ·   Wheel changes power   ·   Click table to shoot" % p


func refresh() -> void:
	if engine == null:
		return
	var who := "You" if engine.current == 0 else "Opponent"
	if GameSession.local_multi:
		who = "Player %d" % (engine.current + 1)
	_turn.text = "%s   ·   %s   ·   %s" % [GameSession.mode_name(), who, PoolTypes.group_name(engine.groups[engine.current])]
	if engine.phase == PoolTypes.Phase.OVER:
		var who_won := "?"
		if engine.winner == 0:
			who_won = "You"
		elif engine.winner == 1:
			who_won = "Opponent"
		_status.text = "Game over — %s  (%s)" % [who_won, engine.end_reason]
	elif engine.ball_in_hand:
		_status.text = "Ball in hand. Click the cloth to place the cue, then shoot."
	elif str(engine.last_foul) != "":
		_status.text = "Foul: %s" % engine.last_foul
	else:
		_status.text = "Aim at a legal ball. Optional trajectory is in Settings."
	set_power(1.4)
