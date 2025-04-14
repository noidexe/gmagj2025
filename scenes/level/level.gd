extends Node3D

@onready var player : Player = $player
@onready var luzmala : LuzMala = $fire

@onready var worldenvironment : WorldEnvironment = $WorldEnvironment

@export var beacons : Array[Beacon] = []
@export var firespawnpoints : Array[Marker3D] = []

func _ready() -> void:
	assert(not beacons.is_empty() and (beacons.size() % 2) == 0 )
	assert(not firespawnpoints.is_empty() )

func _on_fire_state_changed(old: Variant, new: Variant) -> void:
	match new:
		LuzMala.State.FOLLOW:
			player.freeze()
		LuzMala.State.LEAVE:
			player.unfreeze()


func _on_fire_target_reached() -> void:
	if beacons.size() < 2:
		return
	for i in 2:
		var beacon : Beacon = beacons.pop_front()
		print("target reached")
		$vision_sfx.play()
		beacon.focus()
		await get_tree().create_timer(2.0).timeout
		beacon.unfocus()
		player.make_current()
		await get_tree().create_timer(1.0).timeout
	luzmala.leave()
	var next_spawn : Marker3D = firespawnpoints.pop_front()
	luzmala.global_position = next_spawn.global_position
	luzmala.position.y = 0.6
	await get_tree().create_timer(1.0).timeout
	luzmala.roam()

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
