extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.04)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(520, 520)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -260
	box.offset_bottom = 260
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var t := Label.new()
	t.text = "Game Modes"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	box.add_child(t)
	box.add_child(_m("8-BALL vs AI", "Assigned groups, fouls, ball in hand.", PoolTypes.Mode.EIGHT_BALL, true, false))
	box.add_child(_m("8-BALL LOCAL", "Two players, same rules, same physics.", PoolTypes.Mode.EIGHT_BALL, false, true))
	box.add_child(_m("9-BALL vs AI", "Lowest ball first. Combo the 9 to win.", PoolTypes.Mode.NINE_BALL, true, false))
	box.add_child(_m("PRACTICE", "Full rack. No win/loss. Learn english.", PoolTypes.Mode.PRACTICE, false, false))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	box.add_child(back)


func _m(title: String, blurb: String, mode: PoolTypes.Mode, ai: bool, local: bool) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [title, blurb]
	b.custom_minimum_size.y = 70
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		GameSession.reset_defaults()
		GameSession.mode = mode
		GameSession.vs_ai = ai
		GameSession.local_multi = local
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)
	return b
