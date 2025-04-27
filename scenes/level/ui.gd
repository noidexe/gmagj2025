extends CanvasLayer

func _ready() -> void:
	$Control/title.modulate.a = 0
	$Control/credits_code.modulate.a = 0
	$Control/credits_design.modulate.a = 0


func _on_title_trigger_body_entered(body: Node3D) -> void:
	_display_text($Control/title, 1.0, 3.0, 1.0)


func _on_credit_code_trigger_body_entered(body: Node3D) -> void:
	_display_text($Control/credits_code)


func _on_credit_design_trigger_body_entered(body: Node3D) -> void:
	_display_text($Control/credits_design)

func _display_text(node: Control, attack: float = 0.5, sustain: float = 3.0, release: float = 0.5):
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1, attack)
	tween.tween_property(node, "modulate:a", 1, sustain)
	tween.tween_property(node, "modulate:a", 0, release)
