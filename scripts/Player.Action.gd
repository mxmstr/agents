extends Node

const MOVE_GOAL_RADIUS = 30.0
const MAX_CHAT_RADIUS = 300.0
const MAX_SHOOT_RADIUS = 100.0
const MAX_SEARCH_RADIUS = 100.0
const SNAP_TO_TARGET_RADIUS = 50.0

# Confguration for actions. Should probably be its own json.
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
	
	'MoveTo' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Walk',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : '_get_mouse_pos',
		'action' : '_move_to',
		},
		
	'RequestChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'target_source' : '_get_closest_chat_target',
		'action' : '_request_chat',
		},
		
	'WaitChat' : {
		'priority' : 0,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Chat',
		'can_interrupt' : true,
		'reset_anim_finish' : false,
		'action' : '_wait_chat',
		},
		
	'Chat' : {
		'priority' : 1,
		'ui' : 'Chat',
		'hud' : 'Chat',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'action' : '_chat',
		},
	
	'DrawGun' : {
		'priority' : 2,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'DrawGun',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : '_get_closest_shootable_target',
		},
	
	'RequestShoot' : {
		'priority' : 3,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : '_get_closest_shootable_target',
		'action' : '_request_shoot',
		},
		
	'Shoot' : {
		'priority' : 4,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'ShootGun',
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
		'action' : '_request_get_shot',
		},
	
	'GetShot' : {
		'priority' : 5,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : false,
		'animation' : 'Die',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		},
		
	'DrawTranq' : {
		'priority' : 2,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'DrawTranq',
		'can_interrupt' : false,
		'reset_anim_finish' : true,
		'target_source' : '_get_closest_shootable_target',
		},
		
	'RequestSleep' : {
		'priority' : 3,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : '_get_closest_shootable_target',
		'action' : '_request_sleep',
		},
		
	'Sleep' : {
		'priority' : 4,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'ShootDart',
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
		'priority' : 1,
		'ui' : 'Default',
		'hud' : 'Default',
		'collision' : true,
		'animation' : 'Stand',
		'can_interrupt' : false,
		'reset_anim_finish' : false,
		'target_source' : '_get_closest_searchable_target',
		'action' : '_request_search',
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
onready var HUD = $'../HUD'


func _target_is_player():
	
	return target != null \
		and typeof(target) == TYPE_OBJECT \
		and target is Node \
		and target.is_in_group('Slave')


func _target_has_action(action_name):
	
	var target_action = target.get_node('Action').slave_action
	
	return target_action == action_name


func _target_interacting_with_me():
	
	var target_target_id = target.get_node('Action').slave_target_id
	
	return target_target_id == int(get_parent().name)


func _on_animation_finished():
	
	if action['reset_anim_finish']:
		_start_action('Default')


func _on_player_died():
	
	$'/root/Game'._player_has_died(get_parent().role)
	$'/root/Game'.rpc('_player_has_died', get_parent().role)


func _start_timer(time, result):
	
	var timer = Timer.new()
	timer.connect('timeout', self, result)
	timer.wait_time = time
	timer.one_shot = true
	add_child(timer)
	timer.start()


func _send_message(message):
	
	if _target_is_player():
		target.rpc('_receive_message', message)


func _start_action(action_name, new_target=null):
	
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
		
		
		if _target_is_player():
			slave_target_id = int(target.name)
			rset('slave_target_id', int(target.name))
		else:
			slave_target_id = null
			rset('slave_target_id', null)
		
		if new_action.has('collision'):
			get_parent()._set_collision(new_action['collision'])
			get_parent().rpc('_set_collision_remote', new_action['collision'])
		if new_action.has('animation'):
			get_parent()._set_animation(new_action['animation'])
			get_parent().rpc('_set_animation_remote', new_action['animation'])
		
		
		if new_action.has('ui'):
			emit_signal('change_ui', new_action['ui'])
		if new_action.has('hud'):
			emit_signal('change_hud', new_action['hud'])
		
		
		action = new_action
		rset('slave_action', action_name)
		
		return true
	
	return false


func _start_action_inherit(action_name):
	
	_start_action(action_name, target)


func _exec_action():
	
	#if target_is_player():
	if target_ref != null and not target_ref.get_ref():
		_start_action('Default')
		return
	
	if action.has('action') and funcref(self, action['action']).call_func():
		_start_action('Default')


remote func _remote_start_action(action_name, new_target=null):
	
	if is_network_master():
		_start_action(action_name, new_target)


remote func remote_start_action_inherit(action_name):
	
	if is_network_master():
		_start_action(action_name, target)


################# Sources


func _get_mouse_pos():
	
	return get_parent().get_global_mouse_position()


func _target_in_range(max_dist):
	
	var dist = get_parent().global_position.distance_to(target.global_position)
	
	return dist < max_dist


func _get_closest_target(max_dist, include_actions=[], exclude_actions=[]):

	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == get_parent():
			continue
		
		var player_action = player.get_node('Action').slave_action
		var player_dist = player.global_position.distance_to(get_parent().global_position)
		var has_included_actions = len(include_actions) == 0 or player_action in include_actions
		var has_excluded_actions = player_action in exclude_actions
		
		if player_dist < max_dist and has_included_actions and not has_excluded_actions:
		
			if closest == null:
				closest = player
				continue
			
			var closest_dist = closest.global_position.distance_to(get_parent().global_position)
				
			if player_dist < closest_dist:
				closest = player
			
	return closest


func _get_closest_chat_target():
	
	return _get_closest_target(MAX_CHAT_RADIUS, [], ['GetShot', 'GetSlept'])


func _get_closest_shootable_target():
	
	return _get_closest_target(MAX_SHOOT_RADIUS, [], ['GetShot', 'GetSlept'])


func _get_closest_searchable_target():
	
	return _get_closest_target(MAX_SEARCH_RADIUS, ['GetShot', 'GetSlept'])


################# Actions


func _snap_to_target():
	
	if get_parent()._sprite_is_flipped():
		get_parent().global_position = target.global_position + Vector2(SNAP_TO_TARGET_RADIUS, 0)
	else:
		get_parent().global_position = target.global_position - Vector2(SNAP_TO_TARGET_RADIUS, 0)


func _move_to():
	
	var direction = target - get_parent().global_position
	
	get_parent().rset('slave_direction', direction)
	
	get_parent().move_and_slide(direction.normalized() * get_parent().MOVE_SPEED)
	#var collision = get_parent().get_slide_collision()
	
	get_parent()._set_sprite_prop('flip_h', direction.x < 0)
	
	return (
		direction.length() < MOVE_GOAL_RADIUS# or 
		#(collision != null and collision.collider.is_in_group('Slave'))
		)


func _request_chat():
	
	get_parent()._receive_message('Chat requested with ' + target.nickname + '.')
	target.rpc('_receive_message', get_parent().nickname + ' wants to chat.')
	_start_action('WaitChat', target)
	
	return false


func _wait_chat():
	
	var direction = target.global_position - get_parent().global_position
	get_parent()._set_sprite_prop('flip_h', direction.x < 0)
	
	if _target_is_player() and _target_has_action('WaitChat') and _target_interacting_with_me():
		get_parent()._receive_message('You are in chat with ' + target.nickname + '.')
		_start_action('Chat', target)
		get_parent().MessageInput.text = ''
		target.rpc('_receive_message', 'You are in chat with ' + get_parent().nickname + '.')
		target.get_node('Action').rpc('_remote_start_action_inherit', 'Chat')
	
	
	return false


func _chat():
	
	if not _target_is_player() \
		or not (_target_has_action('WaitChat') or _target_has_action('Chat')) \
		or not _target_interacting_with_me():
		get_parent()._receive_message('Chat ended by ' + target.nickname + '.')
		return true
	
	return false


func _request_shoot():
	
	if get_parent().bullets == 0 or not _target_in_range(MAX_SHOOT_RADIUS):
		return true
	
	var direction = target.global_position - get_parent().global_position
	get_parent()._set_sprite_prop('flip_h', direction.x < 0)
	
	_snap_to_target()
	
	target.get_node('Action').rpc('_remote_start_action', 'RequestGetShot', int(get_parent().name))
	_start_action('Shoot', target)
	
	get_parent().bullets -= 1
	get_parent()._update_intel_display()
	
	return false


func _request_get_shot():
	
	var shooter = get_node('../../' + str(target))
	
	var direction = shooter.global_position - get_parent().global_position
	get_parent()._set_sprite_prop('flip_h', direction.x < 0)
	
	_start_timer(1.0, '_on_player_died')
	
	shooter.get_node('Action').rpc('_remote_start_action', 'Shoot', null)
	_start_action('GetShot', shooter)
	
	return false


func _request_sleep():
	
	if get_parent().darts == 0 or not _target_in_range(MAX_SHOOT_RADIUS):
		return true
	
	var direction = target.global_position - get_parent().global_position
	get_parent()._set_sprite_prop('flip_h', direction.x < 0)
	
	_snap_to_target()
	
	target.get_node('Action').rpc('_remote_start_action', 'GetSlept', null)
	_start_action('Sleep', target)
	
	get_parent().darts -= 1
	get_parent()._update_intel_display()
	
	return false


func _request_search():
	
	target.rpc('_request_player_inventory', int(get_parent().name), get_parent().role)
	_start_action('Search', target)
	
	return false


func search():
	
	if not _target_is_player() \
		or not (_target_has_action('GetSlept') or _target_has_action('GetShot')) \
		or not _target_interacting_with_me():
		return true
	
	return false


func _ready():
	
	if is_network_master():
		
		_start_action('Default')
		connect('change_ui', Chat, '_change_ui')
		connect('change_hud', HUD, '_change_hud')


func _physics_process(delta):

	if is_network_master():
		_exec_action()
