 extends Control

enum mode { Server, Client }

var _mode = Server

export(String) var GameScene
export(String) var ServerListScene
export(NodePath) var PlayerName
export(NodePath) var ServerName
export(NodePath) var Address
export(NodePath) var Port
export(NodePath) var Error


func _ready():
	
	#Network.connect('server_info_posted', self, '_on_server_info_posted')
	
	_load_config()


func _adjust_to_virtual_keyboard():
	
	var height = -1 * OS.get_virtual_keyboard_height() + $MarginContainer.get('custom_constants/margin_bottom')
	
	rect_position.y = min(height, 0)


func _on_Name_text_changed(new_text):
	
	Network.player_name = new_text


func _on_Name_focus_exited():
	
	if get_node(PlayerName).text == '':
		get_node(PlayerName).text = 'Agent'


func _on_ServerName_text_changed(new_text):
	
	Network.server_name = new_text


func _on_Port_text_changed(new_text):
	
	Network.port = int(new_text)


func _on_IP_text_changed(new_text):
	
	Network.ip = new_text


func _on_Create_button_down():
	
	_mode = Server


func _on_Join_button_down():
	
	_mode = Client


func _on_Browse_button_down():
	
	get_tree().change_scene(ServerListScene)


func _on_Confirm_button_down():
	
	var error
	
	if _mode == Server:
		
		if null in [Network.server_name, Network.port]:
			return
		
		error = Network._create_server()
		
	else:
		
		if null in [Network.port, Network.ip]:
			return
			
		if not Network.ip.is_valid_ip_address():
			return
		
		error = Network._connect_to_server()
	
	
	if error == OK:
		if _mode == Server:
			Network._post_game_info()
		_load_game()
	elif error == ERR_ALREADY_IN_USE:
		get_node(Error).text = 'Address is already in use.'
	elif error == ERR_CANT_CREATE:
		get_node(Error).text = 'Cannot create.'


func _save_config():
	
	var config = ConfigFile.new()
	config.set_value('Network', 'nickname', Network.player_name)
#	config.set_value('Network', 'servername', _server_name)
#	config.set_value('Network', 'port', _port)
#	config.set_value('Network', 'ip', _ip)
	config.save('res://settings.cfg')


func _load_config():
	
	var config = ConfigFile.new()
	var error = config.load('res://settings.cfg')
	
	if error == OK:
		Network.player_name = config.get_value('Network', 'nickname', Network.player_name)
#		_server_name = config.get_value('Network', 'servername', _server_name)
#		_port = config.get_value('Network', 'port', _port)
#		_ip = config.get_value('Network', 'ip', _ip)
		
		get_node(PlayerName).text = Network.player_name
#		get_node(ServerName).text = _server_name
#		get_node(Port).text = str(_port)
#		get_node(Address).text = _ip


func _load_game():
	
	_save_config()
	get_tree().change_scene(GameScene)


func _process(delta):
	
	_adjust_to_virtual_keyboard()