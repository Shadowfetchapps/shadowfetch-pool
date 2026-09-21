extends Node

var mode: PoolTypes.Mode = PoolTypes.Mode.EIGHT_BALL
var vs_ai: bool = true
var local_multi: bool = false
var self_test: bool = false
var player_break: bool = true


func reset_defaults() -> void:
	mode = PoolTypes.Mode.EIGHT_BALL
	vs_ai = true
	local_multi = false
	self_test = false
	player_break = true


func mode_name() -> String:
	match mode:
		PoolTypes.Mode.PRACTICE:
			return "Practice"
		PoolTypes.Mode.NINE_BALL:
			return "9-Ball"
		_:
			return "8-Ball"
