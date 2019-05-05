extends Node

const UI_PRESETS = {
	
	'Default' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'Search',
			'Intel',
			'ClickZone',
			],
		},
	
	'Connection' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Exit',
			'Announcements',
			'Error'
			],
		},
	
	'Chat' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'MessageContainer',
			'MessageInput',
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
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'Announcements',
			'SearchContainer',
			'SearchTitle',
			'SearchInfo',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'Search',
			'Intel',
			'ClickZone',
			],
		},
	
	'Intel' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'Announcements',
			'IntelContainer',
			'IntelBackground',
			'IntelDisplay',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			'ActionsContainer',
			'Chat',
			'Shoot',
			'Sleep',
			'Search',
			'HideIntel',
			'ClickZone',
			],
		},
		
	'VictoryGood' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'Announcements',
			'VictoryGood',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			],
		},
		
	'VictoryBad' : {
		'visible' : [
			'UIContainer',
			'TopBar',
			'Objective',
			'Exit',
			'Announcements',
			'VictoryBad',
			'MarginContainer',
			'ChatContainer',
			'FeedContainer',
			'Feed',
			],
		},
	
	}

var preset = 'Default'

onready var Objective = find_node('Objective')
onready var Error = find_node('Error')
onready var Feed = find_node('Feed')
onready var MessageInput = find_node('MessageInput')


func _player_connected(id):
	
	_display_message(str(id) + ' has joined')


func _player_disconnected(id):
	
	_display_message(str(id) + ' has left')


func _connected_ok():
	
	_display_message('You have joined the room')
	rpc('announce_user', Network.local_player_id)


func _on_Message_Input_text_entered(new_text):
	
	MessageInput.text = ''
	_display_message('You : ' + new_text)


func _on_feed_timer():
	
	var lines = Feed.text.split('\n ')
	
	if len(lines) > 2:
		$FeedTimer.start()
	
	#if len(lines) > 0:
	Feed.text = ''
	
	lines.remove(0)
	#if len(lines) == 1:
	lines.remove(0)
	
	for line in lines:
		Feed.text += '\n ' + line


func _apply_ui_preset(container):
	
	for child in container.get_children():
		if child is CanvasItem:
			child.visible = preset['visible'].has(child.name)
			_apply_ui_preset(child)


func _change_ui(new_ui):
	
	preset = UI_PRESETS[new_ui]
	
	_apply_ui_preset(self)


func _set_objective(new_text):
	
	Objective.text = new_text


sync func _display_message(new_text):
	
	Feed.text += '\n ' + new_text
	
	var lines = Feed.text.split('\n ')
	
	if len(lines) > 5:
		Feed.text = ''
	
		lines.remove(0)
		lines.remove(0)
		
		for line in lines:
			Feed.text += '\n ' + line
	
	$FeedTimer.start()


remote func _announce_user(player):
	
	_display_message(str(player) + ' has joined the room')


func _ready():
	
	get_tree().connect('connected_to_server', self, '_connected_ok')
	get_tree().connect('network_peer_disconnected', self, '_player_disconnected')
	$FeedTimer.connect('timeout', self, '_on_feed_timer')
	
	_change_ui('Default')