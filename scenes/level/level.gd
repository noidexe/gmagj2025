extends Node3D

@onready var player : Player = $player
@onready var luzmala : LuzMala = $fire

@export var beacons : Array[Beacon] = []

func _ready() -> void:
	assert(not beacons.is_empty())

func _on_fire_state_changed(old: Variant, new: Variant) -> void:
	match new:
		LuzMala.State.FOLLOW:
			player.freeze()
		LuzMala.State.LEAVE:
			player.unfreeze()


func _on_fire_target_reached() -> void:
	var beacon : Beacon = beacons.pop_front()
	print("target reached")
	$vision_sfx.play()
	beacon.focus()
	await get_tree().create_timer(2.0).timeout
	beacon.unfocus()
	player.make_current()
	luzmala.leave()
