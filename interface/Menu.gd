extends Control

var _player_name = ""
var _port = 5000
var _ip = '127.0.0.1'


func _on_Name_text_changed(new_text):
	
	_player_name = new_text


func _on_Port_text_changed(new_text):
	
	_port = int(new_text)


func _on_IP_text_changed(new_text):
	
	_ip = new_text


func _on_CreateButton_pressed():
	
	if _player_name == "":
		return
		
	Network.create_server(_player_name, _port)
	_load_game()


func _on_JoinButton_pressed():
	
	if _player_name == "":
		return
		
	Network.connect_to_server(_player_name, _ip, _port)
	_load_game()


func _load_game():
	
	get_tree().change_scene('res://Game.tscn')