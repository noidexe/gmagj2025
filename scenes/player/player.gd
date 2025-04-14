extends CharacterBody3D
class_name Player

@export var sprint_enabled = true
@export var crouch_enabled = true

@export var base_speed := 1.0
@export var sprint_speed := 1.0
@export var crouch_speed = 0.5

@export var jump_velocity := 4.0
@export var sensitivity = 0.1
@export var joy_sensitivity = 5.0
@export var accel = 10

var speed = base_speed
var time_scale := 1.0:
	set(v):
		time_scale = v
		$head/camera/camera_animation.speed_scale = v

var sprinting = false
var crouching = false
var camera_fov_extents = [75.0, 85.0] #index 0 is normal, index 1 is sprinting
var base_player_y_scale = 1.0
var crouch_player_y_scale = 0.75
var enabled = true:
	set(val):
		enabled = val
		set_process_input(val)
		set_process(val)
		set_physics_process(val)
		if ! is_inside_tree():
			await ready
		if not val:
			velocity = Vector3.ZERO
		camera_animation.stop()
		#$HUD/Control/crosshair.visible = val


@onready var head : Node3D = $head
@onready var camera : Camera3D = $head/camera
@onready var camera_animation : AnimationPlayer = $head/camera/camera_animation
@onready var body : MeshInstance3D = $body
@onready var collision : CollisionShape3D = $collision

@onready var world = get_parent()

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var initial_transform : Transform3D

# stores the last 50 safe positions (safe == on_floor())
var safe_positions : Array[Transform3D]
const MAX_SAFE_POSITIONS := 50

signal fade_finished
signal camera_shake_finished

func _ready():
	#world.pause.connect(_on_pause)
	#world.unpause.connect(_on_unpause)
	#parts.camera.current = true
	initial_transform = transform
	$HUD/animations.animation_finished.connect(fade_finished.emit)
	make_current()


func _process(delta):
	delta *= time_scale
	if Input.is_action_pressed("move_sprint") and !Input.is_action_pressed("move_crouch") and sprint_enabled:
		sprinting = true
		speed = sprint_speed
		camera.fov = lerp(camera.fov, camera_fov_extents[1], 10*delta)
	elif Input.is_action_pressed("move_crouch") and !Input.is_action_pressed("move_sprint") and sprint_enabled:
		crouching = true
		speed = crouch_speed
		body.scale.y = lerp(body.scale.y, crouch_player_y_scale, 10*delta) #change this to starting a crouching animation or whatever
		collision.scale.y = lerp(collision.scale.y, crouch_player_y_scale, 10*delta)
	else:
		sprinting = false
		crouching = false
		speed = base_speed
		if sprint_enabled:
			camera.fov = lerp(camera.fov, camera_fov_extents[0], 10*delta)
		if crouch_enabled:
			body.scale.y = lerp(body.scale.y, base_player_y_scale, 10*delta) #see comment on line 48
			collision.scale.y = lerp(collision.scale.y, base_player_y_scale, 10*delta)

func _physics_process(delta):
	var joy_aim = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joy_aim.length():
		head.rotation_degrees.y -= joy_aim.x * joy_sensitivity * time_scale
		head.rotation_degrees.x -= joy_aim.y * joy_sensitivity * time_scale
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = input_dir.normalized().rotated(-head.global_rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	if is_on_floor(): #don't lerp y movement
		velocity.x = lerp(velocity.x, direction.x * speed * time_scale, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * speed * time_scale, accel * delta)
	
	#bob head
	if input_dir and is_on_floor():
		camera_animation.play("head_bob", 0.5)
	else:
		camera_animation.play("reset", 0.5)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			head.rotation_degrees.y -= event.relative.x * sensitivity * time_scale
			head.rotation_degrees.x -= event.relative.y * sensitivity * time_scale
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("reset_position"):
		_reset_position()
	elif event.is_action_pressed("reset_to_safe_position"):
		_reset_to_safe_position()
	if event is InputEventKey and event.is_pressed():
		if (event as InputEventKey).physical_keycode == KEY_Q:
			freeze()
		elif (event as InputEventKey).physical_keycode == KEY_E:
			unfreeze()

func _on_pause():
	pass

func _on_unpause():
	pass


func make_current():
	camera.make_current()
	pass # Replace with function body.


func _reset_position( xform = null ):
	if !xform:
		xform = initial_transform
	velocity = Vector3.ZERO
	transform = xform
	
func _reset_to_safe_position():
	var xform = safe_positions.pop_back()
	_reset_position(xform)

func _on_safe_position_logger_timeout() -> void:
	if is_on_floor_only():
		safe_positions.append(transform)
	if safe_positions.size() > 50:
		safe_positions.pop_front()


func teleport( xform : Transform3D ):
	enabled = false
	$HUD/animations.play("fadeout")
	await $HUD/animations.animation_finished
	velocity = Vector3.ZERO
	global_position = xform.origin
	head.global_basis = xform.basis
	$HUD/animations.play("fadein")
	enabled = true


func hud_fadeout():
	$HUD/animations.play("fadeout")


func hud_fadein():
	$HUD/animations.play("fadein")

func camera_shake(duration: float = 1.0, intensity: float = 0.05):
	var original_pos = camera.position
	var remaining := duration
	while remaining > 0:
		camera.position = original_pos + Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		await get_tree().process_frame
		remaining -= get_process_delta_time()
	camera.position = original_pos
	camera_shake_finished.emit()

func freeze():
	var tween := create_tween()
	tween.tween_property(self, ^"time_scale", 0.01, 2)
	tween.set_ease(Tween.EASE_IN_OUT)
	
func unfreeze():
	var tween := create_tween()
	tween.tween_property(self, ^"time_scale", 1, 1)
	tween.set_ease(Tween.EASE_OUT)
