extends Control


func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
	pass # Replace with function body.
