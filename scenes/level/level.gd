extends Node3D

@onready var player : Player = $player
@onready var luzmala : LuzMala = $fire

@onready var worldenvironment : WorldEnvironment = $WorldEnvironment

@export var checkpoints : Array[Checkpoint] = []
var current_checkpoint : Checkpoint

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$maze_preview.queue_free()
	for checkpoint in checkpoints:
		checkpoint.validate(self)
	_next_checkpoint()

func _on_fire_state_changed(old: Variant, new: Variant) -> void:
	match new:
		LuzMala.State.FOLLOW:
			player.freeze()
		LuzMala.State.LEAVE:
			player.unfreeze()
		LuzMala.State.DESPAWNED:
			_on_fire_despawned()


func _on_fire_target_reached() -> void:
	if not current_checkpoint.beacons.is_empty():
		for i in current_checkpoint.beacons.size():
			var beacon : Beacon = get_node(current_checkpoint.beacons[i])
			print("target reached")
			$vision_sfx.play()
			beacon.focus()
			await get_tree().create_timer(2.0).timeout
			beacon.unfocus()
			player.make_current()
			await get_tree().create_timer(1.0).timeout
	luzmala.leave(get_node(current_checkpoint.despawn_point))

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
	elif event.is_action_pressed("show_map"):
		$UI/DebugMap.visible = !$UI/DebugMap.visible
