extends Node3D

var velocity = Vector3(0.2,0,0)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	velocity = velocity.rotated(Vector3.UP, 1 * delta)
