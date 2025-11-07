extends Node3D

@export var left_wheel_default: MeshInstance3D
@export var right_wheel_default: MeshInstance3D
@export var axle_mesh: MeshInstance3D
@export var left_wheel_mesh: MeshInstance3D
@export var right_wheel_mesh: MeshInstance3D

# Cardan (third mesh)
@export var cardan_mesh: MeshInstance3D
@export var cardan_axis: Vector3 = Vector3(0, 0, -1)
@export var cardan_multiplier: float = 1.0
@export var cardan_direction: float = 1.0 # 1.0 = normal, -1.0 = reversed

var prev_left_rot: Vector3
var prev_right_rot: Vector3

const PI2 = PI * 2.0

func _ready():
	if left_wheel_default:
		prev_left_rot = left_wheel_default.rotation
	else:
		prev_left_rot = Vector3.ZERO

	if right_wheel_default:
		prev_right_rot = right_wheel_default.rotation
	else:
		prev_right_rot = Vector3.ZERO

func _process(delta):
	if not (left_wheel_default and right_wheel_default):
		_update_axle()
		return

	var curr_left_rot = left_wheel_default.rotation
	var curr_right_rot = right_wheel_default.rotation

	var left_diff = Vector3(
		_shortest_angle(curr_left_rot.x, prev_left_rot.x),
		_shortest_angle(curr_left_rot.y, prev_left_rot.y),
		_shortest_angle(curr_left_rot.z, prev_left_rot.z)
	)
	var right_diff = Vector3(
		_shortest_angle(curr_right_rot.x, prev_right_rot.x),
		_shortest_angle(curr_right_rot.y, prev_right_rot.y),
		_shortest_angle(curr_right_rot.z, prev_right_rot.z)
	)

	_update_axle()
	_apply_wheel_rotations(left_diff, right_diff)
	_apply_cardan_rotation(left_diff, right_diff)

	prev_left_rot = curr_left_rot
	prev_right_rot = curr_right_rot

func _update_axle():
	if not (left_wheel_default and right_wheel_default and axle_mesh):
		return

	var left_pos = left_wheel_default.global_transform.origin
	var right_pos = right_wheel_default.global_transform.origin
	var axle_dir = (right_pos - left_pos).normalized()

	var axle_pos = (left_pos + right_pos) * 0.5
	axle_mesh.global_transform.origin = axle_pos

	var up = global_transform.basis.y.normalized()
	if abs(axle_dir.dot(up)) > 0.99:
		up = global_transform.basis.z.normalized()

	var right = axle_dir.cross(up).normalized()
	var forward = right.cross(axle_dir).normalized()

	var basis = Basis()
	basis.x = axle_dir
	basis.y = forward
	basis.z = right

	axle_mesh.global_transform.basis = basis

func _apply_wheel_rotations(left_diff: Vector3, right_diff: Vector3):
	if not (left_wheel_mesh and right_wheel_mesh):
		return

	left_wheel_mesh.rotate_object_local(Vector3(1, 0, 0), left_diff.x)
	right_wheel_mesh.rotate_object_local(Vector3(1, 0, 0), right_diff.x)

func _apply_cardan_rotation(left_diff: Vector3, right_diff: Vector3):
	if not cardan_mesh:
		return

	# Combine both wheels' spin and apply multiplier + direction
	var combined = (left_diff.x + right_diff.x) * cardan_multiplier * cardan_direction

	cardan_mesh.rotate_object_local(cardan_axis.normalized(), combined)

func _shortest_angle(curr: float, prev: float) -> float:
	var d = curr - prev
	while d > PI:
		d -= PI2
	while d < -PI:
		d += PI2
	return d
