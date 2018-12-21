extends Node

const UI_PRESETS = {
	
	'Default' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'Search',
			'Intel',
			],
		},
	
	'Chat' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'MessageContainer',
			'Message_Input',
			'ActionsContainer',
			'EndChat',
			'Shoot',
			'Sleep',
			'Search',
			'Intel',
			],
		},
	
	'Search' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'ChatContainer',
			'SearchContainer',
			'SearchTitle',
			'SearchInfo',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'HideSearch',
			'Intel',
			],
		},
	
	'Intel' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'IntelDisplay',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'Search',
			'HideIntel',
			],
		},
		
	'VictoryGood' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'ChatContainer',
			'VictoryGood',
			'FeedContainer',
			'Feed',
			],
		},
		
	'VictoryBad' : {
		'visible' : [
			'ExitContainer',
			'Exit',
			'ChatContainer',
			'VictoryBad',
			'FeedContainer',
			'Feed',
			],
		},
	
	}

var preset = 'Default'

onready var Feed = $'/root/Game/UI/Chat/ChatContainer/FeedContainer/Feed'
onready var Message_Input = $'/root/Game/UI/Chat/ChatContainer/MessageContainer/Message_Input'


func _player_connected(id):
	
	display_message(str(id) + ' has joined')


func _player_disconnected(id):
	
	display_message(str(id) + ' has left')


func _connected_ok():
	
	display_message('You have joined the room')
	rpc('announce_user', Network.local_player_id)


func _on_Message_Input_text_entered(new_text):
	
	Message_Input.text = ''
	display_message('You : ' + new_text)


func apply_ui_preset(container):
	
	for child in container.get_children():
		if child is CanvasItem:
			child.visible = preset['visible'].has(child.name)
			apply_ui_preset(child)


func change_ui(new_ui):
	
	preset = UI_PRESETS[new_ui]
	
	apply_ui_preset(self)


sync func display_message(new_text):
	
	Feed.text += '\n ' + new_text
	
	var lines = Feed.text.split('\n ')
	
	if len(lines) > 5:
		Feed.text = ''
		
		lines.remove(0)
		lines.remove(0)
		
		for line in lines:
			Feed.text += '\n ' + line


remote func announce_user(player):
	
	display_message(str(player) + ' has joined the room')


func _ready():
	
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	change_ui('Default')