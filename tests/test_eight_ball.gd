class_name TestEightBall
extends RefCounted

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_test_reset_rack()
	_test_illegal_break()
	_test_legal_break_no_pocket()
	_test_break_and_assign()
	_test_open_table_assignment()
	_test_wrong_ball_first()
	_test_no_contact()
	_test_scratch_ball_in_hand()
	_test_no_rail_foul()
	_test_continue_on_own_pocket()
	_test_eight_early_loss()
	_test_eight_win()
	_test_eight_scratch_loss()
	_test_eight_on_break_spotted()
	_test_no_double_settle()
	_test_practice_never_ends()
	_test_nine_ball()
	_test_randomized(8000)
	print("Eight-ball rule checks: %d  failures: %d" % [_checks, _failures.size()])
	for f in _failures:
		print("FAIL: ", f)
	return _failures.is_empty()


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _eng(mode: PoolTypes.Mode = PoolTypes.Mode.EIGHT_BALL) -> EightBallEngine:
	var e := EightBallEngine.new()
	e.reset(mode)
	return e


func _ev(d: Dictionary) -> ShotEvents:
	return ShotEvents.from_dict(d)


func _shot(e: EightBallEngine, d: Dictionary) -> Dictionary:
	e.begin_shot()
	return e.resolve(_ev(d))


func _test_reset_rack() -> void:
	var e := _eng()
	_ok(e.on_table.size() == 16, "16 balls racked")
	_ok(e.phase == PoolTypes.Phase.BREAK, "starts on break")
	_ok(e.legal_object_ids().size() == 14, "break can hit any non-8 object? wait 14 non-8")
	# actually legal on break is all non-8 object balls still on table = 14
	_ok(e.winner < 0, "no winner")


func _test_illegal_break() -> void:
	var e := _eng()
	var r := _shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 2})
	_ok(r.get("foul") == "illegal break", "illegal break foul")
	_ok(e.ball_in_hand, "ball in hand after illegal break")
	_ok(e.current == 1, "incoming player")


func _test_legal_break_no_pocket() -> void:
	var e := _eng()
	var r := _shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(str(r.get("foul", "")) == "", "legal break")
	_ok(e.current == 1, "turn passes")
	_ok(e.phase == PoolTypes.Phase.OPEN, "open after break")


func _test_break_and_assign() -> void:
	var e := _eng()
	var r := _shot(e, {"first_contact": 3, "contacted_any": true, "pocketed": [3], "rail_count_on_break": 1, "rail_after_first_contact": true})
	_ok(str(r.get("foul", "")) == "", "pocket on break ok")
	_ok(e.groups[0] == PoolTypes.Group.SOLIDS, "breaker solids")
	_ok(e.groups[1] == PoolTypes.Group.STRIPES, "other stripes")
	_ok(e.current == 0, "breaker continues")
	_ok(not e.on_table[3], "3 off table")


func _test_open_table_assignment() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(e.current == 1, "player 1 to shoot")
	_shot(e, {"first_contact": 12, "contacted_any": true, "pocketed": [12], "rail_after_first_contact": true})
	_ok(e.groups[1] == PoolTypes.Group.STRIPES, "assigned stripes")
	_ok(e.groups[0] == PoolTypes.Group.SOLIDS, "other solids")


func _test_wrong_ball_first() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 2, "contacted_any": true, "pocketed": [2], "rail_count_on_break": 4, "rail_after_first_contact": true})
	var r := _shot(e, {"first_contact": 10, "contacted_any": true, "rail_after_first_contact": true})
	_ok(r.get("foul") == "wrong ball first", "must hit solids")


func _test_no_contact() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	var r := _shot(e, {"first_contact": -1, "contacted_any": false})
	_ok(r.get("foul") == "no contact", "miss table")


func _test_scratch_ball_in_hand() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	var r := _shot(e, {"first_contact": 9, "contacted_any": true, "cue_pocketed": true, "rail_after_first_contact": true})
	_ok(r.get("foul") == "scratch", "scratch")
	_ok(e.ball_in_hand, "ball in hand")
	_ok(e.on_table[0], "cue returns")


func _test_no_rail_foul() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	var r := _shot(e, {"first_contact": 9, "contacted_any": true, "rail_after_first_contact": false})
	_ok(r.get("foul") == "no rail after contact", "frozen hit no rail")


func _test_continue_on_own_pocket() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 4, "contacted_any": true, "pocketed": [4], "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(e.current == 0, "still shooter")
	_shot(e, {"first_contact": 5, "contacted_any": true, "pocketed": [5], "rail_after_first_contact": true})
	_ok(e.current == 0, "continues")
	_shot(e, {"first_contact": 6, "contacted_any": true, "rail_after_first_contact": true})
	_ok(e.current == 1, "safety passes")


func _test_eight_early_loss() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "pocketed": [1], "rail_count_on_break": 4, "rail_after_first_contact": true})
	var r := _shot(e, {"first_contact": 8, "contacted_any": true, "pocketed": [8], "rail_after_first_contact": true})
	_ok(e.phase == PoolTypes.Phase.OVER, "over")
	_ok(e.winner == 1, "opponent wins early 8")
	_ok(str(r.get("reason", "")).contains("early"), "early reason")


func _test_eight_win() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "pocketed": [1, 2, 3, 4, 5, 6, 7], "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(e.phase == PoolTypes.Phase.ON_EIGHT or e.remaining_for(0).is_empty(), "on eight")
	var r := _shot(e, {"first_contact": 8, "contacted_any": true, "pocketed": [8], "rail_after_first_contact": true})
	_ok(e.winner == 0, "breaker wins on 8")
	_ok(str(r.get("reason", "")) == "8-ball pocketed", "win reason")


func _test_eight_scratch_loss() -> void:
	var e := _eng()
	_shot(e, {"first_contact": 1, "contacted_any": true, "pocketed": [1, 2, 3, 4, 5, 6, 7], "rail_count_on_break": 4, "rail_after_first_contact": true})
	_shot(e, {"first_contact": 8, "contacted_any": true, "pocketed": [8], "cue_pocketed": true})
	_ok(e.winner == 1, "scratch on 8 loses")


func _test_eight_on_break_spotted() -> void:
	var e := _eng()
	var r := _shot(e, {"first_contact": 1, "contacted_any": true, "pocketed": [8, 2], "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(e.winner < 0, "break 8 is not loss")
	_ok(e.on_table[8], "8 spotted")
	_ok(str(r.get("foul", "")) == "", "not a foul if others pocketed")


func _test_no_double_settle() -> void:
	var e := _eng()
	e.begin_shot()
	var ev := _ev({"first_contact": 1, "contacted_any": true, "rail_count_on_break": 4, "rail_after_first_contact": true})
	_ok(not e.resolve(ev).has("error"), "first settle")
	_ok(e.resolve(ev).has("error"), "second settle blocked")


func _test_practice_never_ends() -> void:
	var e := _eng(PoolTypes.Mode.PRACTICE)
	_shot(e, {"first_contact": 8, "contacted_any": true, "pocketed": [8], "cue_pocketed": true})
	_ok(e.phase != PoolTypes.Phase.OVER, "practice no game over")
	_ok(e.winner < 0, "no winner in practice")


func _test_nine_ball() -> void:
	var e := _eng(PoolTypes.Mode.NINE_BALL)
	_ok(e.on_table.size() == 10, "cue+1-9")
	_shot(e, {"first_contact": 1, "contacted_any": true, "pocketed": [1], "rail_after_first_contact": true})
	_ok(e.current == 0, "combo continue")
	var r := _shot(e, {"first_contact": 2, "contacted_any": true, "pocketed": [9], "rail_after_first_contact": true})
	_ok(e.winner == 0, "combo 9 wins")
	_ok(str(r.get("reason", "")).contains("9"), "nine reason")
	var e2 := _eng(PoolTypes.Mode.NINE_BALL)
	_shot(e2, {"first_contact": 2, "contacted_any": true, "rail_after_first_contact": true})
	_ok(e2.last_foul == "wrong ball first", "must hit lowest")


func _test_randomized(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var ended := 0
	var fouls := 0
	for i in count:
		var e := _eng()
		var guard := 0
		while e.phase != PoolTypes.Phase.OVER and guard < 80:
			guard += 1
			var legal: Array[int] = e.legal_object_ids()
			if legal.is_empty():
				legal.append(8)
			var first := legal[rng.randi_range(0, legal.size() - 1)]
			if rng.randf() < 0.08:
				first = rng.randi_range(1, 15)
			var pocketed: Array = []
			if rng.randf() < 0.35:
				pocketed.append(first)
			if rng.randf() < 0.04:
				pocketed.append(8)
			if rng.randf() < 0.07:
				pocketed.append(0)
			var d := {
				"first_contact": first if rng.randf() > 0.05 else -1,
				"contacted_any": rng.randf() > 0.05,
				"pocketed": pocketed,
				"cue_pocketed": 0 in pocketed or rng.randf() < 0.06,
				"rail_after_first_contact": rng.randf() > 0.2,
				"rail_count_on_break": rng.randi_range(0, 6),
			}
			e.begin_shot()
			var res := e.resolve(_ev(d))
			_ok(not res.has("error") or str(res.get("error")) == "Already settled" or str(res.get("error")) == "Game is over", "resolve %d" % i)
			if str(res.get("foul", "")) != "":
				fouls += 1
				_ok(e.current == 0 or e.current == 1, "player flip-flop")
			if e.phase == PoolTypes.Phase.OVER:
				ended += 1
				_ok(e.winner == 0 or e.winner == 1, "winner is a side")
				_ok(e.end_reason != "", "end reason")
		_ok(e.on_table.has(0), "cue identity remains")
		for n in range(16):
			_ok(e.on_table.has(n) or not PoolTypes.is_object(n), "ball key")
	_ok(ended > 0, "random games finished")
	_ok(fouls > 0, "random fouls occurred")
	print("Randomized 8-ball games/shots: %d games, %d ended, %d fouls" % [count, ended, fouls])
