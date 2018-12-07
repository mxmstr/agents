extends KinematicBody2D

var ACTION = preload("Player.Action.gd").new()

const MOVE_SPEED = 5.0
const MOVE_GOAL_RADIUS = 15.0
const INTERACT_RADIUS = 25.0
const MAX_HP = 100

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)
slave var slave_flip_h = false
slave var slave_animation = 'Stand'

var health_points = MAX_HP
var action = ACTION.ACTIONS['Default']
var target = null

onready var ClickZone = $'/root/Game/ClickZone/ClickZone'
onready var ButtonShoot = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Shoot'
onready var ButtonSleep = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Sleep'
onready var ButtonSearch = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Search'
onready var ButtonIntel = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Intel'


func init(nickname, start_position, is_slave):
	
	$GUI/Nickname.text = nickname
	global_position = start_position
	
	if is_slave:
		add_to_group('Slave')
		slave_position = start_position


func get_closest_target():
	
	#if $Sprite.flip_h:
	var closest = null
	
	for player in get_tree().get_nodes_in_group('Slave'):
		
		if player == self:
			continue
		
		var player_dist = player.global_position.distance_to(global_position)
		
		if player_dist < INTERACT_RADIUS:
		
			if closest == null:
				closest = player
				continue
			
			var closest_dist = closest.global_position.distance_to(global_position)
				
			if player_dist < closest_dist:
				closest = player
			
	return closest


func set_animation(anim_name):
	
	$Sprite.animation = anim_name
	rset('slave_animation', anim_name)


func slave_sync():
	
	move_and_collide(slave_direction.normalized() * MOVE_SPEED)
	position = slave_position
	$Sprite.flip_h = slave_flip_h
	
	if $Sprite.animation != slave_animation:
		$Sprite.animation = slave_animation


func on_action_button(action_name):
	
	start_action(action_name, null)


func on_animation_finished():
	
	if is_network_master() and action['reset_anim_finish']:
		start_action('Default', null)


func start_action(action_name, new_target):
	
	var new_action = ACTION.ACTIONS[action_name]
	
	if -1 in [new_action['priority'], action['priority']] \
		or new_action['priority'] > action['priority'] \
		or (new_action['can_interrupt'] and new_action['priority'] == action['priority']):
		
		if new_action.has('target_source'):
			new_target = funcref(self, new_action['target_source']).call_func()
			if new_target == null:
				return
				
		target = new_target
		
		set_animation(new_action['animation'])
		
		action = new_action


remote func remote_start_action(action_name, new_target):
	
	if is_network_master():
		start_action(action_name, new_target)


func exec_action():
	
	if funcref(ACTION, action['action']).call_func(self):
		start_action('Default', null)


func _ready():
	
	if is_network_master():
		ClickZone.connect('button_down', self, 'on_action_button', ['MoveTo'])
		ButtonShoot.connect('button_down', self, 'on_action_button', ['RequestShoot'])
		ButtonSleep.connect('button_down', self, 'on_action_button', ['Sleep'])
		ButtonSearch.connect('button_down', self, 'on_action_button', ['Search'])
		ButtonIntel.connect('button_down', self, 'on_action_button', ['Intel'])


func _physics_process(delta):
	
	if is_network_master():
		rset_unreliable('slave_position', position)
		rset_unreliable('slave_flip_h', $Sprite.flip_h)
		exec_action()
	else:
		slave_sync()
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)
