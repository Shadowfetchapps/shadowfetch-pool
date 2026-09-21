class_name EightBallEngine
extends RefCounted

## Presentation-independent 8-ball. Physics reports ShotEvents; this settles the law.

signal state_changed
signal game_over(winner: int, reason: String)

var mode: PoolTypes.Mode = PoolTypes.Mode.EIGHT_BALL
var phase: PoolTypes.Phase = PoolTypes.Phase.BREAK
var current: int = 0
var groups: Array[PoolTypes.Group] = [PoolTypes.Group.OPEN, PoolTypes.Group.OPEN]
var on_table: Dictionary = {}
var ball_in_hand: bool = false
var winner: int = -1
var end_reason: String = ""
var last_foul: String = ""
var last_result: Dictionary = {}
var shot_index: int = 0
var _settled_shot: int = -1


func reset(p_mode: PoolTypes.Mode = PoolTypes.Mode.EIGHT_BALL) -> void:
	mode = p_mode
	phase = PoolTypes.Phase.BREAK
	current = 0
	groups = [PoolTypes.Group.OPEN, PoolTypes.Group.OPEN]
	on_table.clear()
	on_table[PoolTypes.CUE] = true
	if mode == PoolTypes.Mode.NINE_BALL:
		for n in PoolTypes.NINE_BALL_SET:
			on_table[n] = true
	else:
		for n in range(1, 16):
			on_table[n] = true
	ball_in_hand = false
	winner = -1
	end_reason = ""
	last_foul = ""
	last_result = {}
	shot_index = 0
	_settled_shot = -1
	state_changed.emit()


func begin_shot() -> String:
	if phase == PoolTypes.Phase.OVER:
		return "Game is over"
	if _settled_shot == shot_index and shot_index > 0:
		pass
	shot_index += 1
	last_foul = ""
	return ""


func resolve(events: ShotEvents) -> Dictionary:
	if phase == PoolTypes.Phase.OVER:
		return {"error": "Game is over"}
	if _settled_shot == shot_index:
		return {"error": "Already settled"}
	_settled_shot = shot_index
	if mode == PoolTypes.Mode.PRACTICE:
		return _resolve_practice(events)
	if mode == PoolTypes.Mode.NINE_BALL:
		return _resolve_nine(events)
	return _resolve_eight(events)


func legal_object_ids() -> Array[int]:
	if mode == PoolTypes.Mode.NINE_BALL:
		return [lowest_on_table()]
	if phase == PoolTypes.Phase.BREAK or phase == PoolTypes.Phase.OPEN:
		var allb: Array[int] = []
		for n in range(1, 16):
			if n != PoolTypes.EIGHT and on_table.get(n, false):
				allb.append(n)
		return allb
	if phase == PoolTypes.Phase.ON_EIGHT:
		var eight: Array[int] = []
		if on_table.get(PoolTypes.EIGHT, false):
			eight.append(PoolTypes.EIGHT)
		return eight
	var g := groups[current]
	var out: Array[int] = []
	for n in PoolTypes.group_balls(g):
		if on_table.get(n, false):
			out.append(n)
	return out


func remaining_for(player: int) -> Array[int]:
	var g := groups[player]
	if g == PoolTypes.Group.OPEN:
		return legal_object_ids()
	var out: Array[int] = []
	for n in PoolTypes.group_balls(g):
		if on_table.get(n, false):
			out.append(n)
	return out


func lowest_on_table() -> int:
	for n in range(1, 10):
		if on_table.get(n, false):
			return n
	return -1


func _pocket(ids: Array[int]) -> void:
	for n in ids:
		on_table[n] = false


func _restore_off_table_as_pocketed(events: ShotEvents) -> void:
	for n in events.off_table:
		if n != PoolTypes.CUE:
			on_table[n] = false
			if n not in events.pocketed:
				events.pocketed.append(n)


func _end(w: int, reason: String) -> Dictionary:
	phase = PoolTypes.Phase.OVER
	winner = w
	end_reason = reason
	last_result = {"winner": w, "reason": reason, "foul": last_foul, "continue": false}
	game_over.emit(w, reason)
	state_changed.emit()
	return last_result


func _foul(reason: String, events: ShotEvents) -> Dictionary:
	last_foul = reason
	_pocket(events.pocketed)
	if events.cue_pocketed or PoolTypes.CUE in events.off_table:
		on_table[PoolTypes.CUE] = true
	ball_in_hand = true
	current = 1 - current
	_refresh_phase()
	last_result = {
		"winner": -1,
		"reason": reason,
		"foul": reason,
		"continue": false,
		"ball_in_hand": true,
		"pocketed": events.pocketed.duplicate(),
	}
	state_changed.emit()
	return last_result


func _continue_or_pass(keep: bool, events: ShotEvents, note: String) -> Dictionary:
	_pocket(events.pocketed)
	if events.cue_pocketed:
		on_table[PoolTypes.CUE] = true
	if not keep:
		current = 1 - current
		ball_in_hand = false
	else:
		ball_in_hand = false
	_refresh_phase()
	last_result = {
		"winner": -1,
		"reason": note,
		"foul": "",
		"continue": keep,
		"ball_in_hand": false,
		"pocketed": events.pocketed.duplicate(),
	}
	state_changed.emit()
	return last_result


func _refresh_phase() -> void:
	if phase == PoolTypes.Phase.OVER:
		return
	if mode == PoolTypes.Mode.NINE_BALL:
		phase = PoolTypes.Phase.ASSIGNED
		return
	if groups[0] == PoolTypes.Group.OPEN:
		phase = PoolTypes.Phase.OPEN if phase != PoolTypes.Phase.BREAK else PoolTypes.Phase.BREAK
		if shot_index > 1 and phase == PoolTypes.Phase.BREAK:
			phase = PoolTypes.Phase.OPEN
		return
	if remaining_for(current).is_empty() and on_table.get(PoolTypes.EIGHT, false):
		phase = PoolTypes.Phase.ON_EIGHT
	else:
		phase = PoolTypes.Phase.ASSIGNED


func _assign_from_first_legal_pocket(events: ShotEvents) -> void:
	if groups[current] != PoolTypes.Group.OPEN:
		return
	for n in events.pocketed:
		if PoolTypes.is_solid(n) or PoolTypes.is_stripe(n):
			var g := PoolTypes.group_of(n)
			groups[current] = g
			groups[1 - current] = PoolTypes.opposite(g)
			return


func _legal_first(events: ShotEvents) -> bool:
	if events.first_contact < 0:
		return false
	var legal := legal_object_ids()
	if phase == PoolTypes.Phase.BREAK or phase == PoolTypes.Phase.OPEN:
		return events.first_contact != PoolTypes.CUE and PoolTypes.is_object(events.first_contact)
	return events.first_contact in legal


func _resolve_practice(events: ShotEvents) -> Dictionary:
	_restore_off_table_as_pocketed(events)
	_pocket(events.pocketed)
	if events.cue_pocketed or PoolTypes.CUE in events.off_table:
		on_table[PoolTypes.CUE] = true
		ball_in_hand = true
	else:
		ball_in_hand = false
	last_result = {"winner": -1, "reason": "practice", "foul": "", "continue": true, "pocketed": events.pocketed.duplicate()}
	state_changed.emit()
	return last_result


func _resolve_eight(events: ShotEvents) -> Dictionary:
	_restore_off_table_as_pocketed(events)
	var eight_down := PoolTypes.EIGHT in events.pocketed or PoolTypes.EIGHT in events.off_table
	var cue_down := events.cue_pocketed or PoolTypes.CUE in events.off_table
	var was_break := phase == PoolTypes.Phase.BREAK
	var on_eight := phase == PoolTypes.Phase.ON_EIGHT or remaining_for(current).is_empty()

	if eight_down:
		if was_break:
			# 8 on break: spot the 8, treat as foul if cue also down, else continue if others pocketed
			on_table[PoolTypes.EIGHT] = true
			var kept: Array[int] = []
			for n in events.pocketed:
				if n != PoolTypes.EIGHT:
					kept.append(n)
			events.pocketed = kept
			if cue_down:
				return _foul("scratch on break", events)
			if events.pocketed.is_empty() and events.rail_count_on_break < 4:
				return _foul("illegal break", events)
			return _continue_or_pass(not events.pocketed.is_empty(), events, "8 spotted after break")
		if not on_eight:
			return _end(1 - current, "8-ball pocketed early")
		if cue_down:
			return _end(1 - current, "scratched on the 8")
		if not _legal_first(events):
			return _end(1 - current, "wrong ball first on the 8")
		return _end(current, "8-ball pocketed")

	if cue_down:
		return _foul("scratch", events)
	if not events.contacted_any or events.first_contact < 0:
		return _foul("no contact", events)
	if not _legal_first(events):
		return _foul("wrong ball first", events)
	var pocketed_object := false
	for n in events.pocketed:
		if PoolTypes.is_object(n):
			pocketed_object = true
	if not was_break and not pocketed_object and not events.rail_after_first_contact:
		return _foul("no rail after contact", events)
	if was_break:
		if not pocketed_object and events.rail_count_on_break < 4:
			return _foul("illegal break", events)
		if pocketed_object:
			_assign_from_first_legal_pocket(events)
			phase = PoolTypes.Phase.ASSIGNED if groups[current] != PoolTypes.Group.OPEN else PoolTypes.Phase.OPEN
			return _continue_or_pass(true, events, "legal break")
		phase = PoolTypes.Phase.OPEN
		return _continue_or_pass(false, events, "legal break no pocket")
	if pocketed_object:
		if groups[current] == PoolTypes.Group.OPEN:
			_assign_from_first_legal_pocket(events)
		# Must have pocketed one of your group to continue
		var own := false
		for n in events.pocketed:
			if groups[current] == PoolTypes.Group.OPEN or PoolTypes.group_of(n) == groups[current]:
				if n != PoolTypes.EIGHT:
					own = true
		return _continue_or_pass(own, events, "shot")
	return _continue_or_pass(false, events, "safety")


func _resolve_nine(events: ShotEvents) -> Dictionary:
	_restore_off_table_as_pocketed(events)
	var nine_down := 9 in events.pocketed or 9 in events.off_table
	var cue_down := events.cue_pocketed or PoolTypes.CUE in events.off_table
	var lowest := _lowest_before_pocket(events)
	if cue_down:
		if nine_down and events.first_contact == lowest:
			on_table[9] = true
		return _foul("scratch", events)
	if events.first_contact != lowest:
		return _foul("wrong ball first", events)
	if nine_down:
		return _end(current, "9-ball pocketed")
	var any_obj := false
	for n in events.pocketed:
		if n >= 1:
			any_obj = true
	if not any_obj and not events.rail_after_first_contact:
		return _foul("no rail after contact", events)
	return _continue_or_pass(any_obj, events, "nine")


func _lowest_before_pocket(events: ShotEvents) -> int:
	var present: Dictionary = on_table.duplicate()
	for n in range(1, 10):
		if present.get(n, false):
			return n
	return 1
