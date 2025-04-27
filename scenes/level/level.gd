extends Node3D

@onready var player : Player = $player
@onready var luzmala : LuzMala = $fire
@onready var ui : UI = $UI

@onready var worldenvironment : WorldEnvironment = $WorldEnvironment

@export var checkpoints : Array[Checkpoint] = []
var current_checkpoint : Checkpoint

var debug_mode := false
@onready var _player_initial_sprint_speed = player.sprint_speed

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$maze_preview.queue_free()
	for checkpoint in checkpoints:
		checkpoint.validate(self)
	_next_checkpoint()
	await RenderingServer.frame_post_draw
	$anims.play("intro")

func _on_fire_state_changed(old: Variant, new: Variant) -> void:
	match new:
		LuzMala.State.FOLLOW:
			player.freeze()
		LuzMala.State.LEAVE:
			player.unfreeze()
		LuzMala.State.DESPAWNED:
			_on_fire_despawned()


func _on_fire_target_reached() -> void:
	if not debug_mode and not current_checkpoint.beacons.is_empty():
		for i in current_checkpoint.beacons.size():
			var beacon : Beacon = get_node(current_checkpoint.beacons[i])
			print("target reached")
			$vision_sfx.play()
			beacon.focus()
			await get_tree().create_timer(4.0).timeout
			beacon.unfocus()
			player.make_current()
			await get_tree().create_timer(1.0).timeout
	luzmala.leave(get_node(current_checkpoint.despawn_point))
	var tween := create_tween()
	tween.tween_property($puddle, "position:y", -0.7, 10)

func _on_fire_despawned() -> void:
	await get_tree().create_timer(2.0).timeout
	_next_checkpoint()

func _next_checkpoint():
	if checkpoints.is_empty():
		return
	current_checkpoint = checkpoints.pop_front()
	luzmala.roam(get_node(current_checkpoint.spawn_point).global_position)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exposure_up"):
		worldenvironment.environment.tonemap_exposure += 0.1
	elif event.is_action_pressed("exposure_down"):
		worldenvironment.environment.tonemap_exposure -= 0.1
	elif event.is_action_pressed("exposure_reset"):
		worldenvironment.environment.tonemap_exposure = 1.0
	elif event.is_action("volume_down"):
		AudioServer.set_bus_volume_linear(0, max(AudioServer.get_bus_volume_linear(0) - 0.1, 0.1))
	elif event.is_action("volume_up"):
		AudioServer.set_bus_volume_linear(0, min(AudioServer.get_bus_volume_linear(0) + 0.1, 2.0))
		pass
	elif event.is_action_pressed("debug_toggle"):
		debug_mode = !debug_mode
		player.sprint_speed = 8.0 if debug_mode else _player_initial_sprint_speed
		ui.show_map(debug_mode)
	elif debug_mode and event.is_pressed() and event is InputEventKey:
		var key_event : InputEventKey = event as InputEventKey
		var unicode := String.chr(key_event.unicode)
		if unicode.is_valid_int() and int(unicode) < checkpoints.size():
			player.global_position = get_node(checkpoints[int(unicode)].spawn_point).global_position

func _on_end_trigger_body_entered(body: Node3D) -> void:
	await ui.fade(1, 3.0).finished
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Sun.light_energy = 1.0
	$end_camera.make_current()
	ui.show_end_ui()
	ui.fade(0, 1.0)
