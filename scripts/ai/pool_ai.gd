class_name PoolAI
extends RefCounted


static func choose_shot(engine: EightBallEngine, table: PoolTable, balls: Dictionary, difficulty: String) -> Dictionary:
	var legal: Array[int] = engine.legal_object_ids()
	if legal.is_empty():
		legal = [PoolTypes.EIGHT]
	var cue: PoolBall = balls.get(0)
	if cue == null:
		return {"dir": Vector3.RIGHT, "power": 1.4, "english": Vector2.ZERO}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var best := {"score": -1e9, "dir": Vector3.RIGHT, "power": 1.6, "english": Vector2.ZERO}
	for bid in legal:
		var b: PoolBall = balls.get(bid)
		if b == null or not b.visible:
			continue
		for pocket in table.pockets:
			var to_pocket := pocket - b.global_position
			to_pocket.y = 0
			if to_pocket.length() < 0.04:
				continue
			var aim := b.global_position - to_pocket.normalized() * (PoolTable.BALL_R * 2.0)
			var dir := aim - cue.global_position
			dir.y = 0
			if dir.length() < 0.02:
				continue
			dir = dir.normalized()
			var blocked := _blocked(cue.global_position, b.global_position, balls, [0, bid])
			var score := 10.0 - to_pocket.length()
			if blocked:
				score -= 8.0
			if score > best.score:
				best = {"score": score, "dir": dir, "power": clampf(1.1 + to_pocket.length() * 0.7, 0.9, 2.6), "english": Vector2.ZERO}
	var noise := 0.18
	match difficulty:
		"easy":
			noise = 0.28
			best.power *= 0.85
		"hard":
			noise = 0.045
		_:
			noise = 0.12
	var yaw := rng.randf_range(-noise, noise)
	best.dir = best.dir.rotated(Vector3.UP, yaw)
	best.english = Vector2(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.2, 0.25)) * (0.35 if difficulty == "hard" else 1.0)
	return best


static func _blocked(from: Vector3, to: Vector3, balls: Dictionary, ignore: Array) -> bool:
	var d := to - from
	d.y = 0
	var len := d.length()
	if len < 0.01:
		return false
	var n := d / len
	for id in balls.keys():
		if int(id) in ignore:
			continue
		var b: PoolBall = balls[id]
		if b == null or not b.visible:
			continue
		var rel := b.global_position - from
		rel.y = 0
		var t := rel.dot(n)
		if t <= 0.0 or t >= len:
			continue
		var closest := from + n * t
		if (b.global_position - closest).length() < PoolTable.BALL_R * 1.85:
			return true
	return false
