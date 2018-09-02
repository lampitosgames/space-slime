extends Sprite

signal cursor_move(globalCoords)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	position = get_global_mouse_position()
	emit_signal("cursor_move", position)
