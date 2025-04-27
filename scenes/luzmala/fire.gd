extends Node3D
class_name LuzMala

signal state_changed(old, new)
signal target_reached()

enum State { INIT, ROAM, FOLLOW, LEAVE, DESPAWNED }
var current_state : State = State.ROAM:
	set(new_state):
		var old_state = current_state
		current_state = new_state
		state_changed.emit(old_state, new_state)
		

var velocity := Vector3(0.5,0,0)

var start_point : Vector3
var distance_sq_to_despawn : float
var target : Node3D = null
var is_target_reached := false:
	set(v):
		if is_target_reached == v:
			return
		is_target_reached = v
		if is_target_reached:
			target_reached.emit()

@onready var particles = $GPUParticles3D
@onready var light = $OmniLight3D

func _physics_process(delta: float) -> void:
	match current_state:
		State.ROAM:
			position += velocity * delta
			velocity = velocity.rotated(Vector3.UP, 1 * delta)
			if global_position.distance_squared_to(target.global_position) <= 9:
				follow()
		State.FOLLOW:
			global_position = global_position.lerp(target.global_position, 1 - 0.2 ** delta)
			if not is_target_reached and global_position.distance_squared_to(target.global_position) <= 0.01:
				is_target_reached = true
		State.LEAVE:
			position += velocity * delta
			if global_position.distance_squared_to(start_point) > distance_sq_to_despawn:
				despawn()
		State.DESPAWNED, State.INIT:
			pass


func follow():
	particles.emitting = true
	light.show()
	current_state = State.FOLLOW

func leave( despawn_point : Node3D):
	is_target_reached = false
	start_point = global_position
	var end_point = despawn_point.global_position
	velocity = global_position.direction_to(end_point) * 1.0
	distance_sq_to_despawn = global_position.distance_squared_to(end_point)
	current_state = State.LEAVE
	

func despawn():
	current_state = State.DESPAWNED
	particles.emitting = false
	is_target_reached = false
	var tween := create_tween()
	tween.tween_property(light, "omni_range", 0, 1.0)
	tween.set_ease(Tween.EASE_IN)
	await tween.finished
	light.hide()


func roam( global_pos : Vector3):
	light.omni_range = 5.0
	velocity = Vector3(0.5,0,0)
	target = get_tree().get_first_node_in_group("luzmala_target")
	global_position = global_pos
	position.y = 0.6
	particles.emitting = true
	is_target_reached = false
	light.show()
	current_state = State.ROAM
