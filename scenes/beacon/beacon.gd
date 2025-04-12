extends Marker3D
class_name Beacon

@onready var light = $OmniLight3D

func _ready() -> void:
	light.hide()
	assert(get_node_or_null("Camera3D"))
	assert(get_node_or_null("model"))

func focus():
	(get_node("Camera3D") as Camera3D).make_current()
	light.show()
	
func unfocus():
	light.hide()
