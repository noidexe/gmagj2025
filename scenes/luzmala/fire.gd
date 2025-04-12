extends Node3D
class_name LuzMala

signal state_changed(old, new)
signal target_reached()

enum State { ROAM, FOLLOW, LEAVE }
var current_state : State = State.ROAM:
	set(new_state):
		var old_state = current_state
		current_state = new_state
		state_changed.emit(old_state, new_state)
		

var velocity := Vector3(0.5,0,0)

var target : Node3D = null
var is_target_reached := false:
	set(v):
		if is_target_reached == v:
			return
		is_target_reached = v
		if is_target_reached:
			target_reached.emit()

@onready var particles = $GPUParticles3D
@onready var light = $GPUParticles3D/OmniLight3D


func _ready() -> void:
	set_physics_process(false)
	while target == null:
		await get_tree().process_frame
		target = get_tree().get_first_node_in_group("luzmala_target")
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	match current_state:
		State.ROAM:
			position += velocity * delta
			velocity = velocity.rotated(Vector3.UP, 1 * delta)
			if global_position.distance_squared_to(target.global_position) <= 9:
				follow()
		State.FOLLOW:
			global_position = global_position.lerp(target.global_position, 1 - 0.1 ** delta)
			if not is_target_reached and global_position.distance_squared_to(target.global_position) <= 0.01:
				is_target_reached = true
		State.LEAVE:
			pass


func follow():
	particles.emitting = true
	light.show()
	current_state = State.FOLLOW

func leave():
	current_state = State.LEAVE
	particles.emitting = false
	is_target_reached = false
	light.hide()

func roam():
	current_state = State.ROAM
	particles.emitting = true
	is_target_reached = false
	light.show()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		var key_event : InputEventKey = event as InputEventKey
		match key_event.physical_keycode:
			KEY_KP_0:
				roam()
			KEY_KP_1:
				follow()
			KEY_KP_2:
				leave()
