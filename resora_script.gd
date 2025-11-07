@tool
extends MeshInstance3D

@export var target_marker: Marker3D
@export var rotation_axis: Vector3 = Vector3(1, 0, 0) # local axis to rotate around (default +X)
@export var aim_axis: Vector3 = Vector3(0, 0, -1) # local axis that should point to target (default -Z)
@export var max_turn_speed: float = 0.0 # radians/sec (0 = instant)

const EPS = 1e-6

func _process(delta: float) -> void:
	if not target_marker:
		return
	_aim_at(target_marker.global_transform.origin, delta)

func _aim_at(target_pos: Vector3, delta: float) -> void:
	# validate
	if rotation_axis.length() < EPS or aim_axis.length() < EPS:
		return

	# use an orthonormalized basis to reduce wobble from non-uniform scale/skew
	var basis = global_transform.basis.orthonormalized()

	# local -> world rotation axis (preserves sign)
	var axis_local = rotation_axis.normalized()
	var axis_world = (basis * axis_local).normalized()

	# direction to target (world)
	var to_target = target_pos - global_transform.origin
	if to_target.length() < EPS:
		return
	to_target = to_target.normalized()

	# project target direction onto plane perpendicular to rotation axis
	var proj_target = to_target - axis_world * to_target.dot(axis_world)
	var lt = proj_target.length()
	if lt < EPS:
		return
	proj_target /= lt

	# current aim in world and its projection onto same plane
	var aim_world = (basis * aim_axis).normalized()
	var proj_aim = aim_world - axis_world * aim_world.dot(axis_world)
	var la = proj_aim.length()
	if la < EPS:
		return
	proj_aim /= la

	# signed angle between the two projected vectors (no Vector3.angle())
	var d = clamp(proj_aim.dot(proj_target), -1.0, 1.0)
	var ang = acos(d)
	var sign = axis_world.dot(proj_aim.cross(proj_target))
	if sign < 0.0:
		ang = -ang

	# optional speed clamp
	if max_turn_speed > 0.0:
		var max_delta = max_turn_speed * delta
		ang = clamp(ang, -max_delta, max_delta)

	if abs(ang) < 1e-5:
		return

	# build a rotation basis from axis-angle and apply it in world-space
	var rot_basis = Basis(axis_world, ang)         # axis-angle -> Basis
	var new_basis = rot_basis * basis              # premultiply = rotate in world space
	global_transform.basis = new_basis.orthonormalized()
