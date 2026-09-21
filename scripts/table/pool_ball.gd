class_name PoolBall
extends RigidBody3D

const R := 0.0285

var ball_id: int = 0


func setup(id: int) -> void:
	ball_id = id
	set_meta("ball_id", id)
	mass = 0.17
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	collision_layer = 2
	collision_mask = 1 | 2
	linear_damp = 0.85
	angular_damp = 0.95
	can_sleep = true
	var pm := PhysicsMaterial.new()
	pm.friction = 0.22
	pm.bounce = 0.68
	physics_material_override = pm
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = R
	col.shape = sh
	add_child(col)
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = R
	mesh.height = R * 2.0
	mi.mesh = mesh
	mi.material_override = _material(id)
	add_child(mi)
	if id > 0:
		var lab := Label3D.new()
		lab.text = str(id)
		lab.font_size = 18
		lab.position = Vector3(0, 0.002, R * 0.55)
		lab.modulate = Color(0.08, 0.08, 0.1) if id != 8 else Color(0.95, 0.9, 0.75)
		add_child(lab)


func _material(id: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.28
	m.clearcoat_enabled = true
	m.clearcoat = 0.55
	if id == 0:
		m.albedo_color = Color(0.96, 0.95, 0.9)
	elif id == 8:
		m.albedo_color = Color(0.08, 0.08, 0.09)
	elif id <= 7:
		m.albedo_color = _solid_color(id)
	else:
		m.albedo_color = _solid_color(id - 8)
		m.roughness = 0.22
	return m


func _solid_color(n: int) -> Color:
	match n:
		1:
			return Color(0.85, 0.72, 0.15)
		2:
			return Color(0.18, 0.32, 0.75)
		3:
			return Color(0.75, 0.16, 0.16)
		4:
			return Color(0.42, 0.16, 0.55)
		5:
			return Color(0.85, 0.42, 0.12)
		6:
			return Color(0.12, 0.48, 0.28)
		_:
			return Color(0.55, 0.12, 0.12)


func is_moving() -> bool:
	return linear_velocity.length() > 0.035 or angular_velocity.length() > 0.6


func park(at: Vector3) -> void:
	freeze = true
	global_position = at
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	sleeping = true


func pocket() -> void:
	freeze = true
	visible = false
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position.y = -1.0


func restore(at: Vector3) -> void:
	visible = true
	collision_layer = 2
	collision_mask = 1 | 2
	park(at)
