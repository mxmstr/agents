extends KinematicBody2D

const MOVE_SPEED = 250.0
const MAX_HP = 100
const MOVE_CAM_MARGIN = 200
const MOVE_CAM_MAX = 720
const MOVE_CAM_MIN = -720

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)
slave var slave_flip_h = false
slave var slave_animation = 'Stand'

var nickname = ''
var health_points = MAX_HP
var enable_abilities = true
var colors = null
var role = null
var intel = []
var bullets = 1
var darts = 1

onready var Chat = $'/root/Game/UI/Chat'
onready var Objective = Chat.find_node('Objective')
onready var MessageInput = Chat.find_node('MessageInput')
onready var SearchTitle = Chat.find_node('SearchTitle')
onready var SearchInfo = Chat.find_node('SearchInfo')
onready var IntelDisplay = Chat.find_node('IntelDisplay')
onready var ClickZone = Chat.find_node('ClickZone')
onready var ButtonExit = Chat.find_node('Exit')
onready var ButtonChat = Chat.find_node('Chat')
onready var ButtonEndChat = Chat.find_node('EndChat')
onready var ButtonShoot = Chat.find_node('Shoot')
onready var ButtonSleep = Chat.find_node('Sleep')
onready var ButtonSearch = Chat.find_node('Search')
onready var ButtonHideSearch = Chat.find_node('HideSearch')
onready var ButtonIntel = Chat.find_node('Intel')
onready var ButtonHideIntel = Chat.find_node('HideIntel')

onready var BUTTON_BINDINGS = {
	'chat' : ButtonChat,
	'end_chat' : ButtonEndChat,
	'shoot' : ButtonShoot,
	'sleep' : ButtonSleep,
	'search' : ButtonSearch,
	'intel' : ButtonIntel,
	'hide_intel' : ButtonHideIntel,
	}


func init(is_slave, _nickname, start_position=Vector2(), _colors=null, _role=null, intel_component=null, intel_color=null):
	
	nickname = _nickname
	colors = _colors
	role = _role
	
	$HUD/Nickname.text = _nickname
	global_position = start_position
	
	#$Action.emit_signal('change_ui', 'Default')
	
	
	if is_network_master():
		$'/root/Game'.connect('victory_good', self, '_victory_good')
		$'/root/Game'.connect('victory_bad', self, '_victory_bad')
		
		if role == 'Traitor':
			Chat._set_objective('You are the traitor. Kill all agents.')
		elif role == 'Agent':
			Chat._set_objective('Find and eliminate the traitor.')
		
		intel.append('The traitor has ' + intel_color + ' ' + intel_component + '.')
		_update_intel_display()
		
		_send_player_info(colors, role)
	
	if is_slave:
		add_to_group('Slave')
		slave_position = start_position


func _victory_good():
	
	$Action._start_action('Victory')
	$Action.emit_signal('change_ui', 'VictoryGood')


func _victory_bad():
	
	$Action._start_action('Victory')
	$Action.emit_signal('change_ui', 'VictoryBad')


remote func _request_player_info(sender_id):
	
	if is_network_master():
		rpc_id(sender_id, '_send_player_info', colors, role)


remote func _send_player_info(_colors, _role):
	
	colors = _colors
	role = _role
	
	for component in colors:
		var color_name = colors[component]
		get_node(component).self_modulate = get_node(component).get(color_name.to_lower())


remote func _request_player_inventory(sender_id, _role):
	
	if is_network_master():
		var sender = get_node('/root/Game/World/' + str(sender_id))
		
		if _role == 'Traitor':
			sender.rpc('_send_player_inventory', nickname, bullets, darts, intel)
			
			bullets = 0
			darts = 0
			
			_update_intel_display()
		else:
			sender.rpc('_send_player_inventory', nickname, 0, 0, intel)
		
		intel = []


remote func _send_player_inventory(_nickname, _bullets, _darts, _intel):
	
	if is_network_master():
		
		SearchTitle.text = _nickname + "'s Inventory"
		if role == 'Traitor':
			SearchInfo.text = str(_bullets) + ' Bullets ' + str(_darts) + ' Darts ' + str(len(_intel)) + ' Intel Confiscated'
		else:
			SearchInfo.text = str(len(_intel)) + ' Intel Confiscated'
		
		bullets += _bullets
		darts += _darts
		
		for line in _intel:
			intel.append(line)
		
		_update_intel_display()


remote func _set_colors(_colors):
	
	colors = _colors


func _sprite_is_flipped():
	
	return $Hat.flip_h


func _sprite_has_animation(anim_name):
	
	return $AnimationPlayer.current_animation == anim_name


func _set_sprite_prop(prop, value):
	
	$Hat.set(prop, value)
	$Eyes.set(prop, value)
	$Face.set(prop, value)
	$Coat.set(prop, value)
	$Hands.set(prop, value)
	$Item.set(prop, value)
	$Pants.set(prop, value)
	$Shoes.set(prop, value)


func _set_collision(enabled):
	
	$CollisionShape2D.disabled = not enabled


remote func _set_collision_remote(enabled):
	
	_set_collision(enabled)


func _set_animation(anim_name):
	
	if not _sprite_has_animation(anim_name):
		$AnimationPlayer.play(anim_name)


remote func _set_animation_remote(anim_name):
	
	_set_animation(anim_name)


func _set_enable_abilities(enable):
	
	enable_abilities = enable


func _slave_sync():
	
	if colors == null:
		rpc('_request_player_info', get_tree().get_network_unique_id())
	
	move_and_collide(slave_direction.normalized() * MOVE_SPEED)
	position = slave_position
	_set_sprite_prop('flip_h', slave_flip_h)


func _on_action_button(action_name):
	
	return $Action._start_action(action_name, null)


func _on_exit_button():
	
	get_tree().network_peer.close_connection()
	get_tree().set_network_peer(null)
	get_tree().emit_signal('server_disconnected')


func _on_animation_finished(anim_name):
	
	if is_network_master():
		$Action._on_animation_finished()


func _update_intel_display():
	
	IntelDisplay.text = ''
	for line in intel:
		if IntelDisplay.text == '':
			IntelDisplay.text += line
		else:
			IntelDisplay.text += '\n ' + line
	
	IntelDisplay.text += '\n You have ' + str(bullets) + ' bullets and ' + str(darts) + ' darts.'


remote func _receive_message(message):
	
	if is_network_master():
		$'/root/Game/UI/Chat'._display_message(message)


func _send_message(message):
	
	if is_network_master():
		$Action._send_message(nickname + ' : ' + message)


func _viewport_follow_player():
	
	var viewportX = -$'/root/Game/World'.transform.origin.x
	var viewportWidth = get_viewport().get_visible_rect().size.x
	var childX = position.x
	
	var margin_right = viewportX + viewportWidth - MOVE_CAM_MARGIN
	var margin_left = viewportX + MOVE_CAM_MARGIN
	
	var offset = $'/root/Game/World'.transform.origin.x
	
	if childX < margin_left:
		offset += margin_left - childX
	if childX > margin_right:
		offset -= childX - margin_right
	
	offset = max(min(offset, MOVE_CAM_MAX), MOVE_CAM_MIN)
	
	$'/root/Game/World'.transform.origin.x = offset


func _ready():
	
	_set_animation('Stand')
	
	if is_network_master():
		MessageInput.connect('text_entered', self, '_send_message')
		MessageInput.connect('focus_entered', self, '_set_enable_abilities', [false])
		MessageInput.connect('focus_exited', self, '_set_enable_abilities', [true])
		MessageInput.connect('hide', self, '_set_enable_abilities', [true])
		ClickZone.connect('button_up', self, '_on_action_button', ['MoveTo'])
		ButtonExit.connect('button_up', self, '_on_exit_button')
		ButtonChat.connect('button_up', self, '_on_action_button', ['RequestChat'])
		ButtonEndChat.connect('button_up', self, '_on_action_button', ['Default'])
		ButtonShoot.connect('button_up', self, '_on_action_button', ['DrawGun'])
		ButtonSleep.connect('button_up', self, '_on_action_button', ['DrawTranq'])
		ButtonSearch.connect('button_up', self, '_on_action_button', ['RequestSearch'])
		ButtonHideSearch.connect('button_up', self, '_on_action_button', ['Default'])
		ButtonIntel.connect('button_up', self, '_on_action_button', ['Intel'])
		ButtonHideIntel.connect('button_up', self, '_on_action_button', ['Default'])


func _process(delta):
	
	if is_network_master():
		
		for ability in BUTTON_BINDINGS:
			var button = BUTTON_BINDINGS[ability]
			if Input.is_action_just_pressed(ability) \
				and enable_abilities \
				and button.visible:
				button.emit_signal('button_up')
				return
#			elif Input.is_action_just_released(ability) :
#				button.emit_signal('button_up')


func _physics_process(delta):
	
	if is_network_master():
		
		_viewport_follow_player()
		
		rset_unreliable('slave_position', position)
		rset_unreliable('slave_flip_h', _sprite_is_flipped())
	else:
		_slave_sync()
