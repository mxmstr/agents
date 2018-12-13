extends KinematicBody2D

const MOVE_SPEED = 5.0
const MAX_HP = 100

slave var slave_position = Vector2()
slave var slave_direction = Vector2(0, 0)
slave var slave_flip_h = false
slave var slave_animation = 'Stand'

var nickname = ''
var health_points = MAX_HP

onready var MessageInput = $'/root/Game/UI/Chat/ChatContainer/MessageContainer/Message_Input'
onready var ClickZone = $'/root/Game/ClickZone/ClickZone'
onready var ButtonChat = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Chat'
onready var ButtonEndChat = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/EndChat'
onready var ButtonShoot = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Shoot'
onready var ButtonSleep = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Sleep'
onready var ButtonSearch = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Search'
onready var ButtonIntel = $'/root/Game/UI/Chat/ChatContainer/ActionsContainer/Intel'


func init(_nickname, start_position, is_slave):
	
	nickname = _nickname
	$GUI/Nickname.text = _nickname
	global_position = start_position
	
	if is_slave:
		add_to_group('Slave')
		slave_position = start_position


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
	
	if is_network_master():
		MessageInput.connect('text_entered', self, 'send_message')
		ClickZone.connect('button_down', self, 'on_action_button', ['MoveTo'])
		ButtonChat.connect('button_down', self, 'on_action_button', ['RequestChat'])
		ButtonEndChat.connect('button_down', self, 'on_action_button', ['Default'])
		ButtonShoot.connect('button_down', self, 'on_action_button', ['RequestShoot'])
		ButtonSleep.connect('button_down', self, 'on_action_button', ['Sleep'])
		ButtonSearch.connect('button_down', self, 'on_action_button', ['Search'])
		ButtonIntel.connect('button_down', self, 'on_action_button', ['Intel'])


func _physics_process(delta):
	
	if is_network_master():
		rset_unreliable('slave_position', position)
		rset_unreliable('slave_flip_h', $Sprite.flip_h)
	else:
		slave_sync()
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)
