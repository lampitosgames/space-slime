extends Sprite

var playerNode = null

func _ready():
	playerNode = get_tree().get_root().find_node("player")

func _process(delta):
	var viewRect = get_viewport_rect()
	position = Vector2(viewRect.size.x/2, 32)

func _on_player_next_jump_update(newDist):
	if (playerNode):
		scale.x = Utils.map(newDist, 0, playerNode.defaultJumpDistance, 0, get_viewport_rect().size.x/2)
	else:
		scale.x = Utils.map(newDist, 0, 1024, 0, get_viewport_rect().size.x/32)
	