extends Marker3D
class_name Beacon

@onready var light = $OmniLight3D

func _ready() -> void:
	light.hide()
	assert(get_node_or_null("Camera3D"))
	assert(get_node_or_null("model"))
	$trigger.global_position = get_node("model").global_position

func focus():
	(get_node("Camera3D") as Camera3D).make_current()
	light.show()
	
func unfocus():
	light.hide()

func _on_trigger_body_entered(body: Node3D) -> void:
	$sfx.play()
