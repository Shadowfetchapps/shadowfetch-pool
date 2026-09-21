extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.04)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 40
	panel.offset_bottom = -40
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = "How to Play"
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = """8-BALL
Rack 1–15. Break must pocket a ball or drive four balls to a rail. The table stays open until a player legally pockets a solid or stripe; that group is theirs. After that you must contact your group first. A ball must then hit a rail or be pocketed. Scratch or a foul gives the opponent ball in hand.

The 8-ball is last. Pocket it early and you lose. Scratch while pocketing the 8 and you lose. Pocket the 8 legally after clearing your group and you win. An 8 pocketed on the break is spotted; the shot is not an automatic loss.

9-BALL
Balls 1–9. Always hit the lowest numbered ball first. Pocket the 9 on a legal shot (including a combo) to win.

PRACTICE
Same physics, no assignment, no match ending.

CONTROLS
Move the mouse to aim. Mouse wheel sets power. Click the cloth to shoot. When you have ball in hand, click to place the cue. Esc pauses. Optional aim line lives in Settings.

AI
The opponent aims at legal pockets with the same physics. Difficulty only changes aim noise and power, not collisions.
"""
	s.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	v.add_child(back)
