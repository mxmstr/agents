extends KinematicBody2D

const MOVE_SPEED = 5.0
const MAX_HP = 100
const COLORS = {
	'Red' : Color(1, 0, 0, 1),
	'Green' : Color(0, 1, 0, 1),
	'Blue' : Color(0, 0, 1, 1),
	'Yellow' : Color(1, 1, 0, 1),
	}
const DEFAULT_COLORS = {
	'Shoes' : Color(0.07, 0.07, 0.07, 1),
	'Coat' : Color(0.49, 0.48, 0.46, 1),
	'Face' : Color(0.68, 0.74, 0.77, 1),
	'Hat' : Color(0.18, 0.17, 0.16, 1),
}

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)
slave var slave_flip_h = false
slave var slave_animation = 'Stand'

var nickname = ''
var health_points = MAX_HP
var colors = null

onready var MessageInput = $'/root/Game/UI/Chat/ChatContainer/MessageContainer/Message_Input'
onready var ClickZone = $'/root/Game/ClickZone/ClickZone'
onready var ButtonChat = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Chat'
onready var ButtonEndChat = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/EndChat'
onready var ButtonShoot = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Shoot'
onready var ButtonSleep = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Sleep'
onready var ButtonSearch = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Search'
onready var ButtonIntel = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Intel'
onready var ButtonHideIntel = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/HideIntel'


func init(_nickname, start_position, _colors, is_slave):
	
	nickname = _nickname
	colors = _colors
	$GUI/Nickname.text = _nickname
	global_position = start_position
	
	if is_network_master():
		send_player_info(colors)
	
	if is_slave:
		add_to_group('Slave')
		slave_position = start_position


remote func request_player_info(sender_id):
	
	if is_network_master():
		rpc_id(sender_id, 'send_player_info', colors)


remote func send_player_info(_colors):
	
	colors = _colors
	
	for component in colors:
		var color_name = colors[component]
		get_node(component).material.set_shader_param('output_color', COLORS[color_name])


remote func set_colors(_colors):
	
	colors = _colors


func sprite_is_flipped():
	
	return $SpriteBase.flip_h


func sprite_has_animation(anim_name):
	
	return $SpriteBase.animation == anim_name


func set_sprite_prop(prop, value):
	
	$SpriteBase.set(prop, value)
	$Shoes.set(prop, value)
	$Coat.set(prop, value)
	$Face.set(prop, value)
	$Hat.set(prop, value)


func set_animation(anim_name):
	
	set_sprite_prop('animation', anim_name)
	rset('slave_animation', anim_name)


func slave_sync():
	
	if colors == null:
		rpc('request_player_info', get_tree().get_network_unique_id())
	
	move_and_collide(slave_direction.normalized() * MOVE_SPEED)
	position = slave_position
	set_sprite_prop('flip_h', slave_flip_h)
	
	if not sprite_has_animation(slave_animation):
		set_animation(slave_animation)


func on_action_button(action_name):
	
	$Action.start_action(action_name, null)


func on_animation_finished():
	
	if is_network_master():
		$Action.on_animation_finished()


remote func receive_message(message):
	
	if is_network_master():
		$'/root/Game/UI/Chat'.display_message(message)


func send_message(message):
	
	if is_network_master():
		$Action.send_message(nickname + ' : ' + message)


func _ready():
	
	for component in [$Shoes, $Coat, $Face, $Hat]:
		component.set_material(component.get_material().duplicate(true))
	
	if is_network_master():
		MessageInput.connect('text_entered', self, 'send_message')
		ClickZone.connect('button_down', self, 'on_action_button', ['MoveTo'])
		ButtonChat.connect('button_down', self, 'on_action_button', ['RequestChat'])
		ButtonEndChat.connect('button_down', self, 'on_action_button', ['Default'])
		ButtonShoot.connect('button_down', self, 'on_action_button', ['RequestShoot'])
		ButtonSleep.connect('button_down', self, 'on_action_button', ['Sleep'])
		ButtonSearch.connect('button_down', self, 'on_action_button', ['Search'])
		ButtonIntel.connect('button_down', self, 'on_action_button', ['Intel'])
		ButtonHideIntel.connect('button_down', self, 'on_action_button', ['Default'])



func _process(delta):
	
	pass

#	print(get_global_mouse_position())
#	var image = get_viewport().get_texture().get_data()
#	yield(get_tree(),"idle_frame")
#	yield(get_tree(),"idle_frame")
#	image.lock()
#	print(image.get_pixel(get_global_mouse_position().x, get_global_mouse_position().y))
#	image.unlock()


func _physics_process(delta):
	
	if is_network_master():
		rset_unreliable('slave_position', position)
		rset_unreliable('slave_flip_h', sprite_is_flipped())
	else:
		slave_sync()

	if get_tree().is_network_server():
		Network.update_position(int(name), position)
