extends AnimatedSprite

onready var parentNode = get_parent()
var dScale

enum MOVE_STATE {LEFT = 0, RIGHT = 1, NONE = 2, JUMPING = 3}

var activeMoveState = MOVE_STATE.NONE
var lastMoveState = MOVE_STATE.NONE
var activeNormal = Vector2(0, -1)

func _ready():
	dScale = scale

func _on_Player_move_normal_change(newNormal):
	activeNormal = newNormal.floor()
	#North face
	if (activeNormal == Vector2(0, -1)):
		transform.y = Vector2(0, dScale.y)
		transform.x = Vector2(dScale.x, 0)
	#East face
	elif (activeNormal == Vector2(1, 0)):
		transform.y = Vector2(-dScale.y, 0)
		transform.x = Vector2(0, dScale.x)
	#South face
	elif (activeNormal == Vector2(0, 1)):
		transform.y = Vector2(0, -dScale.y)
		transform.x = Vector2(-dScale.x, 0)
	#West Face
	elif (activeNormal == Vector2(-1, 0)):
		transform.y = Vector2(dScale.y, 0)
		transform.x = Vector2(0, -dScale.x)

func _on_Player_move_state_change(newState):
	#Don't store the last state as jumping
	if (newState == MOVE_STATE.LEFT or newState == MOVE_STATE.RIGHT):
		lastMoveState = activeMoveState
	#Set the new active move state
	activeMoveState = newState
	if (newState == MOVE_STATE.LEFT):
		animation = "Walk"
		flip_h = true
		offset.x = 12
		offset.y = -2
	elif (newState == MOVE_STATE.RIGHT):
		animation = "Walk"
		flip_h = false
		offset.x = -12
		offset.y = -2
	elif (newState == MOVE_STATE.JUMPING):
		animation = "Jump"
		frame = 0
		frames.set_animation_speed("Jump", frames.get_frame_count("Jump")/(parentNode.nextJumpDistance/parentNode.jumpMoveSpeed))
		offset.x = 0
		offset.y = 12
		var normJumpDir = parentNode.jumpDir.normalized()
		transform.y = -normJumpDir * dScale.y
		transform.x = Vector2(normJumpDir.y, -normJumpDir.x) * dScale.x
		#Set animation speed
	elif (newState == MOVE_STATE.NONE):
		offset.y = -2
		if (flip_h):
			offset.x = 12
		else:
			offset.x = -12
		animation = "Idle"
		
