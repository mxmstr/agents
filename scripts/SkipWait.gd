extends Label


func _on_timeout():
	
	var player = $'/root/Game/World'.get_node(str(get_tree().get_network_unique_id()))
	player.get_node('Action')._start_action('Default')


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func _process(delta):
	
	if visible:
	
		var vect = get_viewport().get_mouse_position() - (rect_position + (rect_size / 2))
		var mouse_over = abs(vect.x) < (rect_size.x / 2) and abs(vect.y) < (rect_size.y / 2)
		
		if mouse_over and Input.is_action_just_pressed('mouse_left'):
			$Timer.start()
		elif not Input.is_action_pressed('mouse_left'):
			$Timer.stop()
