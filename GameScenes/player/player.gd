extends KinematicBody2D

signal move_normal_change(newNormal)
signal move_state_change(newState)
signal next_jump_update(newDist)

export(Color) var lineColor = Color(0.6, 0.898, 0.314)
export(float) var playerMoveSpeed = 250.0

enum MOVE_STATE {LEFT = 0, RIGHT = 1, NONE = 2, JUMPING = 3}
var playerMoveState = MOVE_STATE.NONE

var attachedPlatform = null
var attachedPlatformExtents = null
var playerExtents = null

#normal vector to movement direction. Should be pointing away from the surface the player is moving along
var moveNormal = Vector2(0, -1)
#Position of the mouse on the screen
var mousePos = Vector2(0, 0)

#Jumping variables
#We have to store all the move state in case the player doesn't land anywhere
var launchPosition = Vector2(0, 0)
var launchPlatform = null
var launchMoveNormal = null
export(Vector2) var jumpDir = Vector2(0, 0)
export(float) var jumpMoveSpeed = 500.0
#How far can the player jump without any power ups?
export(float) var defaultJumpDistance = 1024.0
#How far can the next jump go?  Can be increased by power-ups (even mid-jump)
var nextJumpDistance = 0

func _ready():
	set_process_input(true)
	connect("move_normal_change", $AnimatedSprite, "_on_Player_move_normal_change")
	connect("move_state_change", $AnimatedSprite, "_on_Player_move_state_change")
	playerExtents = $CollisionShape2D.shape.radius * scale.x
	nextJumpDistance = defaultJumpDistance
	emit_signal("next_jump_update", nextJumpDistance)

func _process(delta):
	#Only run platform-sticking code if there is an attached platform
	#If the player has moved off the edge of a platform, change direction
	if (attachedPlatform and playerMoveState != MOVE_STATE.JUMPING):
		#Get seperation vector 
		var sepVec = position - attachedPlatform.position
		
		#North edge of platform
		if (sepVec.y <= -playerExtents - attachedPlatformExtents.y - 1):
			moveNormal = Vector2(0, -1)
			emit_signal("move_normal_change", moveNormal)
			position.y = attachedPlatform.position.y - attachedPlatformExtents.y - playerExtents
		#East edge of platform
		if (sepVec.x >= playerExtents + attachedPlatformExtents.x + 1):
			moveNormal = Vector2(1, 0)
			emit_signal("move_normal_change", moveNormal)
			position.x = attachedPlatform.position.x + attachedPlatformExtents.x + playerExtents
		#South edge of platform
		if (sepVec.y >= playerExtents + attachedPlatformExtents.y + 1):
			moveNormal = Vector2(0, 1)
			emit_signal("move_normal_change", moveNormal)
			position.y = attachedPlatform.position.y + attachedPlatformExtents.y + playerExtents
		#West edge of platform
		if (sepVec.x <= -playerExtents - attachedPlatformExtents.x - 1):
			moveNormal = Vector2(-1, 0)
			emit_signal("move_normal_change", moveNormal)
			position.x = attachedPlatform.position.x - attachedPlatformExtents.x - playerExtents
	
	#Move the player tangent to the last stored collision normal at a fixed speed
	var collision = null
	if (playerMoveState == MOVE_STATE.RIGHT):
		collision = move_and_collide(Vector2(-playerMoveSpeed * moveNormal.y, playerMoveSpeed * moveNormal.x) * delta)
	elif (playerMoveState == MOVE_STATE.LEFT):
		collision = move_and_collide(Vector2(playerMoveSpeed * moveNormal.y, -playerMoveSpeed * moveNormal.x) * delta)
	elif (playerMoveState == MOVE_STATE.JUMPING):
		collision = move_and_collide(jumpDir*jumpMoveSpeed*delta)
		
	#If there is a new collision, switch collider data
	if (collision):
		if collision.collider.is_in_group("platform") and (collision.collider != attachedPlatform or playerMoveState == MOVE_STATE.JUMPING):
			#New platform the player is on
			attachedPlatform = collision.collider
			#get the half-extents of the platform
			attachedPlatformExtents = collision.collider_shape.shape.extents
			attachedPlatformExtents.x *= collision.collider.scale.x
			attachedPlatformExtents.y *= collision.collider.scale.y
			#Set the movement normal for the new collision
			moveNormal = collision.normal
			emit_signal("move_normal_change", moveNormal)
			#Reset the move state if this is a landed jump
			if (playerMoveState == MOVE_STATE.JUMPING):
				playerMoveState = MOVE_STATE.NONE
				#If the player has less jump distance 
				if (nextJumpDistance < defaultJumpDistance):
					nextJumpDistance = defaultJumpDistance
					emit_signal("next_jump_update", nextJumpDistance)
				emit_signal("move_state_change", playerMoveState)
				emit_signal("move_normal_change", moveNormal)
		#Collided with a slime ball
		elif collision.collider.is_in_group("slime"):
			nextJumpDistance += collision.collider.slimeCount
			collision.collider.queue_free()
			emit_signal("next_jump_update", nextJumpDistance)
			emit_signal("move_state_change", playerMoveState)
		elif collision.collider.is_in_group("goal"):
			#Level over, move to next level
			get_tree().change_scene(collision.collider.nextLevelScn.resource_path)
		elif collision.collider.is_in_group("hazard_block") and playerMoveState == MOVE_STATE.JUMPING:
			reset_jump()
	
	#If the player is jumping, decriment the timer
	if (playerMoveState == MOVE_STATE.JUMPING):
		nextJumpDistance -= jumpMoveSpeed * delta
		emit_signal("next_jump_update", nextJumpDistance)
		#Check if the player is out of jump distance
		if (nextJumpDistance <= 0):
			reset_jump()
	#Update the drawn targeting line if we aren't
	update()
	
func _input(ev):
	if (playerMoveState == MOVE_STATE.JUMPING):
		return
	if (ev is InputEventKey):
		if (ev.is_action_pressed("move_left")):
			playerMoveState = MOVE_STATE.LEFT
			emit_signal("move_state_change", playerMoveState)
		if (ev.is_action_pressed("move_right")):
			playerMoveState = MOVE_STATE.RIGHT
			emit_signal("move_state_change", playerMoveState)
		if (ev.is_action_released("move_left")):
			if (Input.is_action_pressed("move_right")):
				playerMoveState = MOVE_STATE.RIGHT
				emit_signal("move_state_change", playerMoveState)
			else:
				playerMoveState = MOVE_STATE.NONE
				emit_signal("move_state_change", playerMoveState)
		if (ev.is_action_released("reset_level")):
			get_tree().reload_current_scene()
		if (ev.is_action_released("move_right")):
			if (Input.is_action_pressed("move_left")):
				playerMoveState = MOVE_STATE.LEFT
				emit_signal("move_state_change", playerMoveState)
			else:
				playerMoveState = MOVE_STATE.NONE
				emit_signal("move_state_change", playerMoveState)
		#Check jump
		if (ev.is_action_released("player_jump")):
			start_jump()
	elif (ev is InputEventMouseButton):
		if (ev.is_action_released("player_jump")):
			start_jump()
	

func _draw():
	#If we're jumping, don't draw
	if (playerMoveState == MOVE_STATE.JUMPING):
		return
	#Get the vector pointing to the cursor
	var toCursorFull = (mousePos - position) * 2
	#Get the normalized version
	var toCursor = toCursorFull.normalized()
	#Length of individual dashes on the targeting line
	var lineLength = 48
	#Dash separation calculated based on cursor distance
	var lineSeparation = max(toCursorFull.length() / 8, 64)
	#Cache end-points so they don't have to be calculated more than once
	var lineEndPoints = [toCursor*lineSeparation   + toCursor*lineLength,
						 toCursor*lineSeparation*2 + toCursor*lineLength,
						 toCursor*lineSeparation*3 + toCursor*lineLength,
						 toCursor*lineSeparation*4 + toCursor*lineLength]
	#For every line segment
	for i in range(4):
		#If the end of the line isn't past the cursor
		if (lineEndPoints[i].length_squared() < toCursorFull.length_squared()):
			#Draw the line segment
			draw_line(toCursor*lineSeparation * (i+1), lineEndPoints[i], lineColor, 12)
		#The end of the line is past the cursor.  CHcek if we can still partly draw the line
		elif ((toCursor*lineSeparation * (i+1)).length_squared() < toCursorFull.length_squared()):
			#Draw the line from the start pos to the cursor
			draw_line(toCursor*lineSeparation * (i+1), toCursorFull - toCursor*8, lineColor, 12)
		#Else, we can't draw more lines so don't continue to loop
		else:
			break

func start_jump():
	#Can't jump if you're already jumping
	if (playerMoveState == MOVE_STATE.JUMPING):
		return
	#Can't jump if you're not on a platform
	if (!attachedPlatform):
		return
	#Store launch data so it can be reset later if the player misses their jump
	launchPosition = position
	launchPlatform = attachedPlatform
	launchMoveNormal = moveNormal
	#Get the jump direction
	jumpDir = (mousePos - position).normalized()
	#Set the state to jumping
	playerMoveState = MOVE_STATE.JUMPING
	emit_signal("move_state_change", playerMoveState)

func reset_jump():
	#Reset all jump variables to where they were before the jump
	position = launchPosition
	attachedPlatform = launchPlatform
	moveNormal = launchMoveNormal
	playerMoveState = MOVE_STATE.NONE
	nextJumpDistance = defaultJumpDistance
	emit_signal("next_jump_update", nextJumpDistance)
	emit_signal("move_state_change", playerMoveState)
	emit_signal("move_normal_change", moveNormal)

func _on_Cursor_cursor_move(globalCoords):
	mousePos = globalCoords
