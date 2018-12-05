extends Node

onready var Feed = $'/root/Game/UI/Chat/ChatContainer/FeedContainer/Feed'
onready var Message_Input = $'/root/Game/UI/Chat/ChatContainer/MessageContainer/Message_Input'


func _ready():
	
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func _player_connected(id):
	
	Feed.text += '\n ' + str(id) + ' has joined'


func _player_disconnected(id):
	
	Feed.text += '\n ' + str(id) + ' has left'


func _connected_ok():
	
	Feed.text += '\n You have joined the room'
	rpc('announce_user', Network.local_player_id)


func _on_Message_Input_text_entered(new_text):
	
	Message_Input.text = ''
	rpc('display_message', Network.local_player_id, new_text)


sync func display_message(player, new_text):
	
	Feed.text += '\n ' + str(player) + ' : ' + new_text


remote func announce_user(player):
	
	Feed.text += '\n ' + str(player) + ' has joined the room' 