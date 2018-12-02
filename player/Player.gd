extends KinematicBody2D

const MOVE_SPEED = 10.0
const MOVE_GOAL_RADIUS = 15.0
const MAX_HP = 100
const ACTIONS = {
	
	'Default' : {
		'priority' : -1,
		'sprite' : 'res://player/detective stand right.png',
		'auto_target' : false,
		'action' : 'default_action',
		},
	
	'MoveTo' : {
		'priority' : 0,
		'sprite' : 'res://player/detective stand right.png',
		'auto_target' : false,
		'action' : 'move_to',
		},
		
	'Shoot' : {
		'priority' : 1,
		'sprite' : 'res://player/detective shoot right.png',
		'auto_target' : true,
		'action' : 'shoot',
		},
	
	}

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)
slave var slave_sprite = ''


var health_points = MAX_HP
var action = ACTIONS['Default']
var target = null


func init(nickname, start_position, is_slave):
	
	$GUI/Nickname.text = nickname
	global_position = start_position
	
	if not is_network_master():
		add_to_group('Slave')


func _ready():
	
	if is_network_master():
		$'/root/Game/UI/Chat/Shoot'.connect(
			'button_down', self, 'on_action_button', ['Shoot']
			)


func start_action(action_name, new_target):
	
	var new_action = ACTIONS[action_name]
	
	if -1 in [new_action['priority'], action['priority']] \
		or new_action['priority'] > action['priority']:
			
		action = new_action
		
		if new_action['auto_target']:
			target = get_closest_target()
		else:
			target = new_target
		
		$Sprite.texture = load(new_action['sprite'])
		#rset('slave_sprite', direction)


func exec_action():
	
	if funcref(self, action['action']).call_func():
		start_action('Default', null)


func _physics_process(delta):
	
	if is_network_master():
		
		if Input.is_action_just_pressed("ui_click_left"):
			start_action('MoveTo', get_global_mouse_position())
		
		exec_action()
		
	else:
		slave_move_to()
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)


func default_action():
	
	return false


func move_to():
	
	var direction = target - global_position
	
	rset_unreliable('slave_position', position)
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


func on_action_button(action_name):
	
	start_action(action_name, null)