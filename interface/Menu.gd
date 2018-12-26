extends Control

var _player_name = ''
var _port = 5000
var _ip = '127.0.0.1'

onready var Name = $'/root/Menu/VBoxContainer/HBoxContainer/Name'
onready var Address = $'/root/Menu/VBoxContainer/HBoxContainer3/IP'
onready var Port = $'/root/Menu/VBoxContainer/HBoxContainer3/Port'


func _ready():
	
	_load_config()


func _on_Name_text_changed(new_text):
	
	_player_name = new_text


func _on_Port_text_changed(new_text):
	
	_port = int(new_text)


func _on_IP_text_changed(new_text):
	
	_ip = new_text


func _on_CreateButton_pressed():
	
	if _player_name == "":
		return
	
	var error = Network.create_server(_player_name, _port)
	
	if error == OK:
		_save_config()
		_load_game()
	elif error == ERR_ALREADY_IN_USE:
		$'VBoxContainer/Error'.text = 'ERR_ALREADY_IN_USE'
	elif error == ERR_CANT_CREATE:
		$'VBoxContainer/Error'.text = 'ERR_CANT_CREATE'


func _on_JoinButton_pressed():
	
	if _player_name == "":
		return
		
	var error = Network.connect_to_server(_player_name, _ip, _port)
	
	print(error)
	if error == OK:
		_save_config()
		_load_game()
	elif error == ERR_ALREADY_IN_USE:
		$'VBoxContainer/Error'.text = 'ERR_ALREADY_IN_USE'
	elif error == ERR_CANT_CREATE:
		$'VBoxContainer/Error'.text = 'ERR_CANT_CREATE'


func _save_config():
	
	var config = ConfigFile.new()
	config.set_value('Network', 'nickname', _player_name)
	config.set_value('Network', 'port', _port)
	config.set_value('Network', 'ip', _ip)
	config.save('res://settings.cfg')


func _load_config():
	
	var config = ConfigFile.new()
	var error = config.load('res://settings.cfg')
	
	if error == OK:
		_player_name = config.get_value('Network', 'nickname', _player_name)
		_port = config.get_value('Network', 'port', _port)
		_ip = config.get_value('Network', 'ip', _ip)
		
		Name.text = _player_name
		Port.text = str(_port)
		Address.text = _ip


func _load_game():
	
	get_tree().change_scene('res://Game.tscn')