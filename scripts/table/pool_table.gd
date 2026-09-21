class_name PoolTable
extends Node3D

const HALF_L := 1.12
const HALF_W := 0.56
const BALL_R := 0.0285
const POCKET_R := 0.055

signal ball_pocketed(id: int)
signal rail_hit(id: int)
signal balls_collided(a: int, b: int)

var balls: Dictionary = {}
var pockets: Array[Vector3] = []
var _rail_bodies: Array[RID] = []


func _ready() -> void:
	_build_cloth()
	_build_rails()
	_build_pockets()
	_build_shell()


func _build_cloth() -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(HALF_L * 2.0 + 0.08, 0.04, HALF_W * 2.0 + 0.08)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.28, 0.18)
	mat.roughness = 0.92
	mi.material_override = mat
	mi.position.y = -0.02
	add_child(mi)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF_L * 2.0, 0.04, HALF_W * 2.0)
	col.shape = shape
	body.position.y = -0.02
	body.add_child(col)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.35
	pm.bounce = 0.02
	body.physics_material_override = pm
	add_child(body)


func _build_rails() -> void:
	var segs := [
		Vector3(0, 0.03, HALF_W + 0.03),
		Vector3(0, 0.03, -(HALF_W + 0.03)),
		Vector3(HALF_L + 0.03, 0.03, 0),
		Vector3(-(HALF_L + 0.03), 0.03, 0),
	]
	var sizes := [
		Vector3(HALF_L * 2.0 - 0.16, 0.08, 0.06),
		Vector3(HALF_L * 2.0 - 0.16, 0.08, 0.06),
		Vector3(0.06, 0.08, HALF_W * 2.0 - 0.16),
		Vector3(0.06, 0.08, HALF_W * 2.0 - 0.16),
	]
	for i in 4:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = sizes[i]
		col.shape = sh
		body.position = segs[i]
		body.add_child(col)
		var pm := PhysicsMaterial.new()
		pm.friction = 0.12
		pm.bounce = 0.72
		body.physics_material_override = pm
		body.set_meta("rail", true)
		add_child(body)
		var wood := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = sizes[i] + Vector3(0.02, 0.02, 0.02)
		wood.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.14, 0.07)
		mat.roughness = 0.45
		mat.metallic = 0.08
		wood.material_override = mat
		body.add_child(wood)


func _build_pockets() -> void:
	pockets = [
		Vector3(-HALF_L, 0, -HALF_W),
		Vector3(0, 0, -HALF_W),
		Vector3(HALF_L, 0, -HALF_W),
		Vector3(-HALF_L, 0, HALF_W),
		Vector3(0, 0, HALF_W),
		Vector3(HALF_L, 0, HALF_W),
	]
	for p in pockets:
		var area := Area3D.new()
		area.monitoring = true
		area.collision_mask = 2
		area.collision_layer = 4
		area.position = p
		var col := CollisionShape3D.new()
		var sh := SphereShape3D.new()
		sh.radius = POCKET_R
		col.shape = sh
		area.add_child(col)
		area.body_entered.connect(_on_pocket.bind(p))
		add_child(area)
		var hole := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = POCKET_R
		cyl.bottom_radius = POCKET_R
		cyl.height = 0.02
		hole.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.02, 0.02, 0.02)
		hole.material_override = mat
		hole.position.y = 0.005
		area.add_child(hole)


func _build_shell() -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.92, 0.75)
	lamp.light_energy = 4.2
	lamp.omni_range = 8.0
	lamp.position = Vector3(0, 2.4, 0)
	lamp.shadow_enabled = true
	add_child(lamp)


func _on_pocket(body: Node, _pocket: Vector3) -> void:
	if body is RigidBody3D and body.has_meta("ball_id"):
		ball_pocketed.emit(int(body.get_meta("ball_id")))


func rack_positions(mode: PoolTypes.Mode) -> Dictionary:
	var d: Dictionary = {}
	d[0] = Vector3(-HALF_L * 0.55, BALL_R, 0)
	var apex := Vector3(HALF_L * 0.32, BALL_R, 0)
	var gap := BALL_R * 2.02
	var rows := 5
	if mode == PoolTypes.Mode.NINE_BALL:
		rows = 3
	var ids: Array[int] = []
	if mode == PoolTypes.Mode.NINE_BALL:
		ids = [1, 2, 3, 4, 9, 5, 6, 7, 8]
	else:
		ids = [1, 2, 9, 3, 8, 10, 4, 11, 5, 12, 6, 13, 7, 14, 15]
	var idx := 0
	for row in rows:
		for col in row + 1:
			if idx >= ids.size():
				break
			var x := apex.x + row * gap * 0.866
			var z := (col - row * 0.5) * gap
			d[ids[idx]] = Vector3(x, BALL_R, z)
			idx += 1
	return d


func in_kitchen(pos: Vector3) -> bool:
	return pos.x <= -HALF_L * 0.5


func clamp_cue_ball(pos: Vector3, kitchen: bool) -> Vector3:
	var p := pos
	p.y = BALL_R
	p.x = clampf(p.x, -HALF_L + BALL_R * 1.2, HALF_L - BALL_R * 1.2)
	p.z = clampf(p.z, -HALF_W + BALL_R * 1.2, HALF_W - BALL_R * 1.2)
	if kitchen:
		p.x = minf(p.x, -HALF_L * 0.5)
	return p
