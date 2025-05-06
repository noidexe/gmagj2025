extends Marker3D
class_name Beacon

@onready var light = $OmniLight3D
@onready var backoff : Timer = $backoff

func _ready() -> void:
	if not Engine.is_editor_hint():
		light.hide()
		assert(get_node_or_null("Camera3D"))
		assert(get_node_or_null("model"))
	if get_node_or_null("model"):
		$trigger.global_position = get_node("model").global_position
		$sfx.global_position = $trigger.global_position

func focus():
	(get_node("Camera3D") as Camera3D).make_current()
	light.show()
	
func unfocus():
	light.hide()

func _on_trigger_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if backoff.is_stopped():
		$sfx.play()
		backoff.start()
