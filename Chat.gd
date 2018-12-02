extends Node

const MAX_USERS = 1


func _ready():
	
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func _player_connected(id):
	
	$Display.text += '\n ' + str(id) + ' has joined'


func _player_disconnected(id):
	
	$Display.text += '\n ' + str(id) + ' has left'


func _connected_ok():
	
	$Display.text += '\n You have joined the room'
	rpc('announce_user', Network.local_player_id)


func _on_Message_Input_text_entered(new_text):
	
	$Message_Input.text = ''
	rpc('display_message', Network.local_player_id, new_text)


sync func display_message(player, new_text):
	
	$Display.text += '\n ' + str(player) + ' : ' + new_text


remote func announce_user(player):
	
	$Display.text += '\n ' + str(player) + ' has joined the room' 