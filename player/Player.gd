extends KinematicBody2D

const MOVE_SPEED = 10.0
const MOVE_GOAL_RADIUS = 15.0
const MAX_HP = 100
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'animation' : 'Stand',
		'auto_target' : false,
		'action' : 'default_action',
		},
	
	'MoveTo' : {
		'priority' : 0,
		'animation' : 'Walk',
		'auto_target' : false,
		'action' : 'move_to',
		},
		
	'Shoot' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'auto_target' : true,
		'action' : 'shoot',
		},
		
	'Sleep' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'auto_target' : true,
		'action' : 'shoot',
		},
		
	'Search' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'auto_target' : true,
		'action' : 'shoot',
		},
		
	'Intel' : {
		'priority' : 1,
		'animation' : 'Shoot',
		'auto_target' : true,
		'action' : 'shoot',
		},
	
	}

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)

var health_points = MAX_HP
var action = ACTIONS['Default']
var target = null

onready var CLICK_ZONE = $'/root/Game/ClickZone/ClickZone'
onready var BUTTON_SHOOT = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Shoot'
onready var BUTTON_SLEEP = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Sleep'
onready var BUTTON_SEARCH = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Search'
onready var BUTTON_INTEL = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Intel'


func init(nickname, start_position, is_slave):
	
	$GUI/Nickname.text = nickname
	global_position = start_position
	
	if is_slave:
		add_to_group('Slave')
		slave_position = start_position


func _ready():
	
	if is_network_master():
		CLICK_ZONE.connect('button_down', self, 'on_action_button', ['MoveTo', 'get_global_mouse_position'])
		BUTTON_SHOOT.connect('button_down', self, 'on_action_button', ['Shoot'])
		BUTTON_SLEEP.connect('button_down', self, 'on_action_button', ['Sleep'])
		BUTTON_SEARCH.connect('button_down', self, 'on_action_button', ['Search'])
		BUTTON_INTEL.connect('button_down', self, 'on_action_button', ['Intel'])


func start_action(action_name, new_target):
	
	var new_action = ACTIONS[action_name]
	
	if -1 in [new_action['priority'], action['priority']] \
		or new_action['priority'] >= action['priority']:
			
		action = new_action
		
		if new_action['auto_target']:
			target = get_closest_target()
		else:
			target = new_target
		
		set_animation(new_action['animation'])


func exec_action():
	
	if funcref(self, action['action']).call_func():
		start_action('Default', null)


func _physics_process(delta):
	
	if is_network_master():
		rset_unreliable('slave_position', position)
		exec_action()
	else:
		slave_move_to()
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)


func default_action():
	
	return false


func move_to():
	
	var direction = target - global_position
	
	rset('slave_direction', direction)
	
	move_and_collide(direction.normalized() * MOVE_SPEED)
	$Sprite.flip_h = direction.x < 0
	
	return direction.length() < MOVE_GOAL_RADIUS


func shoot():
	
	return false


func slave_move_to():
	
	move_and_collide(slave_direction.normalized() * MOVE_SPEED)
	$Sprite.flip_h = slave_direction.x < 0
	
	position = slave_position


func get_closest_target():
	
	#if $Sprite.flip_h:
	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == self:
			continue
		
		if closest == null:
			closest = player
		
		if player.global_position.distance_to(closest.global_position):
			closest = player
			
	return closest


func on_action_button(action_name, target_source=null):
	
	if target_source == null:
		start_action(action_name, null)
	else:
		start_action(
			action_name, 
			funcref(self, target_source).call_func()
			)


func set_animation(anim_name):
	
	$Sprite.animation = anim_name
	rpc('remote_set_animation', anim_name)


remote func remote_set_animation(anim_name):
	
	$Sprite.animation = anim_name