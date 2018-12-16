extends Node

const MOVE_GOAL_RADIUS = 15.0
const MAX_INTERACT_RADIUS = 50.0
const INTERACT_RADIUS = 25.0
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'ui' : 'Default',
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'default_action',
		},
	
	'MoveTo' : {
		'priority' : 0,
		'ui' : 'Default',
		'animation' : 'Walk',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : 'get_mouse_pos',
		'action' : 'move_to',
		},
		
	'RequestChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'animation' : 'Stand',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_target',
		'action' : 'request_chat',
		},
		
	'WaitChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'animation' : 'ChatRequest',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'action' : 'wait_chat',
		},
		
	'Chat' : {
		'priority' : 1,
		'ui' : 'Chat',
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'action' : 'chat',
		},
	
	'RequestShoot' : {
		'priority' : 2,
		'ui' : 'Default',
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : 'get_closest_target',
		'action' : 'request_shoot',
		},
		
	'Shoot' : {
		'priority' : 3,
		'ui' : 'Default',
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
	
	'RequestGetShot' : {
		'priority' : 2,
		'ui' : 'Default',
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : 'request_get_shot',
		},
	
	'GetShot' : {
		'priority' : 3,
		'ui' : 'Default',
		'animation' : 'Dead',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
		
	'Sleep' : {
		'priority' : 2,
		'ui' : 'Default',
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : 'get_closest_target',
		},
		
	'Search' : {
		'priority' : 2,
		'ui' : 'Default',
		'animation' : 'Shoot',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : 'get_closest_target',
		},
		
	'Intel' : {
		'priority' : 2,
		'ui' : 'Intel',
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		},
	
	}

signal change_ui

slave var slave_action = ACTIONS['Default']
slave var slave_target_id = null

var action = ACTIONS['Default']
var target_ref = null
var target = null

onready var Chat = $'/root/Game/UI/Chat/'


func target_is_player():
	
	return target != null \
		and typeof(target) == TYPE_OBJECT \
		and target is Node \
		and target.is_in_group('Slave')


func target_has_action(action_name):
	
	var target_action = target.get_node('Action').slave_action
	
	return target_action.has('action') and target_action['action'] == action_name


func target_interacting_with_me():
	
	var target_target_id = target.get_node('Action').slave_target_id
	
	return target_target_id == int(get_parent().name)


func on_animation_finished():
	
	if action['reset_anim_finish']:
		start_action('Default')


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
					return
		
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
		
		
		get_parent().set_animation(new_action['animation'])
		
		
		if new_action.has('ui'):
			emit_signal('change_ui', new_action['ui'])
		
		
		action = new_action
		rset('slave_action', action)


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


func get_closest_target():
	
	#if $Sprite.flip_h:
	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == get_parent():
			continue
		
		var player_dist = player.global_position.distance_to(get_parent().global_position)
		
		if player_dist < MAX_INTERACT_RADIUS:
		
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
	$'../Sprite'.flip_h = direction.x < 0
	
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
	get_parent().get_node('Sprite').flip_h = direction.x < 0
	
	if target_is_player() and target_has_action('wait_chat') and target_interacting_with_me():
		get_parent().receive_message('You are in chat with ' + target.nickname + '.')
		start_action('Chat', target)
		target.rpc('receive_message', 'You are in chat with ' + get_parent().nickname + '.')
		target.get_node('Action').rpc('remote_start_action_inherit', 'Chat')
	
	
	return false


func chat():
	
	if not target_is_player() \
		or not (target_has_action('wait_chat') or target_has_action('chat')) \
		or not target_interacting_with_me():
		get_parent().receive_message('Chat ended by ' + target.nickname + '.')
		return true
	
	return false


func request_shoot():
	
	var direction = target.global_position - get_parent().global_position
	$'../Sprite'.flip_h = direction.x < 0
	
	
	target.get_node('Action').rpc('remote_start_action', 'RequestGetShot', int(get_parent().name))
		
		
	if $'../Sprite'.flip_h:
		get_parent().global_position = target.global_position + Vector2(INTERACT_RADIUS, 0)
	else:
		get_parent().global_position = target.global_position - Vector2(INTERACT_RADIUS, 0)
		
		
	return false


func request_get_shot():
	
	var shooter = get_node('../../' + str(target))
	
	var direction = shooter.global_position - get_parent().global_position
	$'../Sprite'.flip_h = direction.x < 0
	
	shooter.get_node('Action').rpc('remote_start_action', 'Shoot', null)
	start_action('GetShot', shooter)
	
	return false


func _ready():
	
	if is_network_master():
		connect('change_ui', Chat, 'change_ui')


func _physics_process(delta):
	
	if is_network_master():
		exec_action()
