extends Sprite2D

@export var player : Player
var player_pos : Vector2 = Vector2.ZERO

func _ready() -> void:
	assert(player != null)

func _process(delta: float) -> void:
	player_pos = Vector2(player.position.x * 8, player.position.z * 8)
	queue_redraw()

func _draw() -> void:
	draw_circle(player_pos, 8, Color.RED)
