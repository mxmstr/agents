extends Node

const MOVE_GOAL_RADIUS = 15.0
const MAX_INTERACT_RADIUS = 50.0
const INTERACT_RADIUS = 25.0
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'default_action',
		},
	
	'MoveTo' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Walk',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : 'get_mouse_pos',
		'action' : 'move_to',
		},
		
	'RequestChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_alive_target',
		'action' : 'request_chat',
		},
		
	'WaitChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'ChatRequest',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'action' : 'wait_chat',
		},
		
	'Chat' : {
		'priority' : 1,
		'ui' : 'Chat',
		'hud' : 'Chat',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'action' : 'chat',
		},
	
	'RequestShoot' : {
		'priority' : 2,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_alive_target',
		'action' : 'request_shoot',
		},
		
	'Shoot' : {
		'priority' : 3,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
	
	'RequestGetShot' : {
		'priority' : 3,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'request_get_shot',
		},
	
	'GetShot' : {
		'priority' : 5,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : false,
		'animation' : 'Dead',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
		
	'RequestSleep' : {
		'priority' : 2,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_alive_target',
		'action' : 'request_sleep',
		},
		
	'Sleep' : {
		'priority' : 3,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
	
	'GetSlept' : {
		'priority' : 5,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : false,
		'animation' : 'Sleep',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
		
	'RequestSearch' : {
		'priority' : 2,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Default',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_dead_target',
		'action' : 'request_search',
		},
		
	'Search' : {
		'priority' : 2,
		'ui' : 'Search',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Search',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
		
	'Intel' : {
		'priority' : 2,
		'ui' : 'Intel',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Intel',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
	
	'Victory' : {
		'priority' : 4,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
	
	}

signal change_ui
signal change_hud

slave var slave_action = 'Default'
slave var slave_target_id = null

var action = ACTIONS['Default']
var target_ref = null
var target = null

onready var Chat = $'/root/Game/UI/Chat/'
onready var HUD = $'../GUI'


func target_is_player():
	
	return target != null \
		and typeof(target) == TYPE_OBJECT \
		and target is Node \
		and target.is_in_group('Slave')


func target_has_action(action_name):
	
	var target_action = target.get_node('Action').slave_action
	
	return target_action == action_name


func target_interacting_with_me():
	
	var target_target_id = target.get_node('Action').slave_target_id
	
	return target_target_id == int(get_parent().name)


func on_animation_finished():
	
	if action['reset_anim_finish']:
		start_action('Default')


func on_player_died():
	
	$'/root/Game'.player_has_died(get_parent().role)
	$'/root/Game'.rpc('player_has_died', get_parent().role)


func start_timer(time, result):
	
	var timer = Timer.new()
	timer.connect('timeout', self, result)
	timer.wait_time = time
	timer.one_shot = true
	add_child(timer)
	timer.start()


func send_message(message):
	
	if target_is_player():
		target.rpc('receive_message', message)


func start_action(action_name, new_target=null):
	
	var new_action = ACTIONS[action_name]
	
	if -1 in [new_action['priority'], action['priority']] \
		or new_action['priority'] > action['priority'] \
		or (new_action['can_interrupt'] and new_action['priority'] == action['priority']):
		
		if new_target == null:
		
			if new_action.has('target_source'):
				new_target = funcref(self, new_action['target_source']).call_func()
				if new_target == null:
					return false
		
		target = new_target
		
		if typeof(target) == TYPE_OBJECT:
			target_ref = weakref(target)
		else:
			target_ref = null
		
		
		if target_is_player():
			slave_target_id = int(target.name)
			rset('slave_target_id', int(target.name))
		else:
			slave_target_id = null
			rset('slave_target_id', null)
		
		
		get_parent().set_collision(new_action['collision'])
		get_parent().rpc('set_collision_remote', new_action['collision'])
		get_parent().set_animation(new_action['animation'])
		
		
		if new_action.has('ui'):
			emit_signal('change_ui', new_action['ui'])
		if new_action.has('hud'):
			emit_signal('change_hud', new_action['hud'])
		
		
		action = new_action
		rset('slave_action', action_name)
		
		return true
	
	return false


func exec_action():
	
	#if target_is_player():
	if target_ref != null and not target_ref.get_ref():
		start_action('Default')
		return
	
	if action.has('action') and funcref(self, action['action']).call_func():
		start_action('Default')


remote func remote_start_action(action_name, new_target=null):
	
	if is_network_master():
		start_action(action_name, new_target)


remote func remote_start_action_inherit(action_name):
	
	if is_network_master():
		start_action(action_name, target)


################# Sources


func get_mouse_pos():
	
	return get_parent().get_global_mouse_position()


func get_closest_alive_target():
	
	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == get_parent():
			continue
		
		var player_action = player.get_node('Action').slave_action
		var player_dist = player.global_position.distance_to(get_parent().global_position)
		
		if player_dist < MAX_INTERACT_RADIUS and not player_action in ['GetShot', 'GetSlept']:
		
			if closest == null:
				closest = player
				continue
			
			var closest_dist = closest.global_position.distance_to(get_parent().global_position)
				
			if player_dist < closest_dist:
				closest = player
			
	return closest


func get_closest_dead_target():
	
	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == get_parent():
			continue
		
		var player_action = player.get_node('Action').slave_action
		var player_dist = player.global_position.distance_to(get_parent().global_position)
		
		if player_dist < MAX_INTERACT_RADIUS and player_action in ['GetShot', 'GetSlept']:
		
			if closest == null:
				closest = player
				continue
			
			var closest_dist = closest.global_position.distance_to(get_parent().global_position)
				
			if player_dist < closest_dist:
				closest = player
			
	return closest


################# Actions


func default_action():
	
	return false


func move_to():
	
	var direction = target - get_parent().global_position
	
	get_parent().rset('slave_direction', direction)
	
	var collision = get_parent().move_and_collide(
		direction.normalized() * get_parent().MOVE_SPEED
		)
	get_parent().set_sprite_prop('flip_h', direction.x < 0)
	
	return (
		direction.length() < MOVE_GOAL_RADIUS or 
		(collision != null and collision.collider.is_in_group('Slave'))
		)


func request_chat():
	
	get_parent().receive_message('Chat requested with ' + target.nickname + '.')
	target.rpc('receive_message', get_parent().nickname + ' wants to chat.')
	start_action('WaitChat', target)
	
	return false


func wait_chat():
	
	var direction = target.global_position - get_parent().global_position
	get_parent().set_sprite_prop('flip_h', direction.x < 0)
	
	if target_is_player() and target_has_action('WaitChat') and target_interacting_with_me():
		get_parent().receive_message('You are in chat with ' + target.nickname + '.')
		start_action('Chat', target)
		target.rpc('receive_message', 'You are in chat with ' + get_parent().nickname + '.')
		target.get_node('Action').rpc('remote_start_action_inherit', 'Chat')
	
	
	return false


func chat():
	
	if not target_is_player() \
		or not (target_has_action('WaitChat') or target_has_action('Chat')) \
		or not target_interacting_with_me():
		get_parent().receive_message('Chat ended by ' + target.nickname + '.')
		return true
	
	return false


func request_shoot():
	
	if get_parent().bullets == 0:
		return true
	
	var direction = target.global_position - get_parent().global_position
	get_parent().set_sprite_prop('flip_h', direction.x < 0)
	
	if get_parent().sprite_is_flipped():
		get_parent().global_position = target.global_position + Vector2(INTERACT_RADIUS, 0)
	else:
		get_parent().global_position = target.global_position - Vector2(INTERACT_RADIUS, 0)
	
	target.get_node('Action').rpc('remote_start_action', 'RequestGetShot', int(get_parent().name))
	start_action('Shoot', target)
	
	get_parent().bullets -= 1
	get_parent().update_intel_display()
	
	return false


func request_get_shot():
	
	var shooter = get_node('../../' + str(target))
	
	var direction = shooter.global_position - get_parent().global_position
	get_parent().set_sprite_prop('flip_h', direction.x < 0)
	
	start_timer(1.0, 'on_player_died')
	
	shooter.get_node('Action').rpc('remote_start_action', 'Shoot', null)
	start_action('GetShot', shooter)
	
	return false


func request_sleep():
	
	if get_parent().darts == 0:
		return true
	
	var direction = target.global_position - get_parent().global_position
	get_parent().set_sprite_prop('flip_h', direction.x < 0)
	
	if get_parent().sprite_is_flipped():
		get_parent().global_position = target.global_position + Vector2(INTERACT_RADIUS, 0)
	else:
		get_parent().global_position = target.global_position - Vector2(INTERACT_RADIUS, 0)
	
	target.get_node('Action').rpc('remote_start_action', 'GetSlept', null)
	start_action('Sleep', target)
	
	get_parent().darts -= 1
	get_parent().update_intel_display()
	
	return false


func request_search():
	
	target.rpc('request_player_inventory', int(get_parent().name), get_parent().role)
	start_action('Search', target)
	
	return false


func search():
	
	if not target_is_player() \
		or not (target_has_action('GetSlept') or target_has_action('GetShot')) \
		or not target_interacting_with_me():
		return true
	
	return false


func _ready():

	if is_network_master():
		connect('change_ui', Chat, 'change_ui')
		connect('change_hud', HUD, 'change_hud')


func _physics_process(delta):

	if is_network_master():
		exec_action()
