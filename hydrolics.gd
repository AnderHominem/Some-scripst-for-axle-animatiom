extends MeshInstance3D

@export var target_marker: Marker3D
@export var rotation_axis: Vector3 = Vector3(1, 0, 0) # local axis to rotate around (default +X)
@export var aim_axis: Vector3 = Vector3(0, 0, -1) # local axis that should point to target (default -Z)
@export var max_turn_speed: float = 0.0 # radians/sec (0 = instant)
@export var buffer_distance: float = 0.0

const EPS = 1e-6

func _process(delta: float) -> void:
	if not target_marker:
		return
	
	_aim_at(target_marker.global_transform.origin, delta)
	_telescopic_children(target_marker.global_transform.origin)

func _aim_at(target_pos: Vector3, delta: float) -> void:
	if rotation_axis.length() < EPS or aim_axis.length() < EPS:
		return

	var basis = global_transform.basis.orthonormalized()
	var axis_local = rotation_axis.normalized()
	var axis_world = (basis * axis_local).normalized()

	var to_target = target_pos - global_transform.origin
	if to_target.length() < EPS:
		return
	to_target = to_target.normalized()

	var proj_target = to_target - axis_world * to_target.dot(axis_world)
	var lt = proj_target.length()
	if lt < EPS:
		return
	proj_target /= lt

	var aim_world = (basis * aim_axis).normalized()
	var proj_aim = aim_world - axis_world * aim_world.dot(axis_world)
	var la = proj_aim.length()
	if la < EPS:
		return
	proj_aim /= la

	var d = clamp(proj_aim.dot(proj_target), -1.0, 1.0)
	var ang = acos(d)
	var sign = axis_world.dot(proj_aim.cross(proj_target))
	if sign < 0.0:
		ang = -ang

	if max_turn_speed > 0.0:
		var max_delta = max_turn_speed * delta
		ang = clamp(ang, -max_delta, max_delta)

	if abs(ang) < 1e-5:
		return

	var rot_basis = Basis(axis_world, ang)
	global_transform.basis = (rot_basis * basis).orthonormalized()


# --------------------------
# Telescopic movement of children
# --------------------------
# --------------------------
# Telescopic movement of children
# --------------------------
func _telescopic_children(target_pos: Vector3) -> void:
	var children = get_children()
	if children.size() == 0:
		return

	# calculate distance along aim_axis in local space
	var local_target_pos = to_local(target_pos)
	var dist = local_target_pos.dot(aim_axis.normalized())

	# apply buffer distance
	dist = max(dist - buffer_distance, 0.0)
	if dist < EPS:
		return

	# spread children evenly along the aim axis
	var step = dist / (children.size() + 1)
	for i in range(children.size()):
		var child = children[i]
		if not child is Node3D:
			continue
		var t = child.transform
		t.origin = aim_axis.normalized() * step * (i + 1)
		child.transform = t
