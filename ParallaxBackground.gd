extends ParallaxBackground

func _process(delta):
	scroll_offset = scroll_offset + Vector2(10, 10)*delta
