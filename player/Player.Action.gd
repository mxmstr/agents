
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'default_action',
		},
	
	'MoveTo' : {
		'priority' : 0,
		'animation' : 'Walk',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : 'get_global_mouse_position',
		'action' : 'move_to',
		},
	
	'RequestShoot' : {
		'priority' : 1,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_target',
		'action' : 'request_shoot',
		},
		
	'Shoot' : {
		'priority' : 2,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'action' : 'shoot',
		},
	
	'RequestGetShot' : {
		'priority' : 1,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'request_get_shot',
		},
	
	'GetShot' : {
		'priority' : 2,
		'animation' : 'Dead',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'get_shot',
		},
		
	'Sleep' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : 'get_closest_target',
		'action' : 'shoot',
		},
		
	'Search' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : 'get_closest_target',
		'action' : 'shoot',
		},
		
	'Intel' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : 'get_closest_target',
		'action' : 'shoot',
		},
	
	}


func default_action(player):
	
	return false


func move_to(player):
	
	var direction = player.target - player.global_position
	
	player.rset('slave_direction', direction)
	
	var collision = player.move_and_collide(direction.normalized() * player.MOVE_SPEED)
	player.get_node('Sprite').flip_h = direction.x < 0
	
	return (
		direction.length() < player.MOVE_GOAL_RADIUS or 
		(collision != null and collision.collider.is_in_group('Slave'))
		)


func request_shoot(player):
	
	var direction = player.target.global_position - player.global_position
	player.get_node('Sprite').flip_h = direction.x < 0
	
	
	player.target.rpc(
		'remote_start_action', 
		'RequestGetShot',
		int(player.name)
		)
		
		
	if player.get_node('Sprite').flip_h:
		player.global_position = player.target.global_position + Vector2(player.INTERACT_RADIUS, 0)
	else:
		player.global_position = player.target.global_position - Vector2(player.INTERACT_RADIUS, 0)
		
		
	return false


func shoot(player):
	
	return false


func request_get_shot(player):
	
	var shooter = player.get_node('../' + str(player.target))
	
	var direction = shooter.global_position - player.global_position
	player.get_node('Sprite').flip_h = direction.x < 0
	
	shooter.rpc(
		'remote_start_action',
		'Shoot',
		null
		)
	
	player.start_action('GetShot', shooter)
	
	return false


func get_shot(player):
	
	return false