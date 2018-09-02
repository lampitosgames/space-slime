extends StaticBody2D

export(Resource) var nextLevelScn = null

func _process(delta):
	if (!$AnimationPlayer.is_playing()):
		$AnimationPlayer.play("rotateLevelEnd", -1, 2.0, false)
