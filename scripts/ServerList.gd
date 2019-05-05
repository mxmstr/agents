extends Control

export(String) var MenuScene
export(String) var GameScene
export(NodePath) var List
export(NodePath) var Error


func _ready():
	
	Network.connect('host_list_requested', self, '_refresh_list')
	
	Network._request_host_list()


func _on_Refresh_button_up():
	
	Network._request_host_list()


func _on_Back_button_up():
	
	get_tree().change_scene(MenuScene)


func _on_Join_button_up():
	
	if len(get_node(List).get_selected_items()) == 0:
		return
	
	var idx = get_node(List).get_selected_items()[0]
	var host = Network.hosts[Network.hosts.keys()[idx]]
	
	Network.ip = host.ip
	Network.port = host.port
	
	
	var error = Network._connect_to_server()
	
	if error == OK:
		_load_game()
	elif error == ERR_ALREADY_IN_USE:
		get_node(Error).text = 'Address is already in use.'
	elif error == ERR_CANT_CREATE:
		get_node(Error).text = 'Cannot join this server.'


func _refresh_list():
	
	get_node(List).clear()
	
	for host in Network.hosts:
		host = Network.hosts[host]
		get_node(List).add_item('%s (%s/4)' % [host.server_name, host.clients])


func _load_game():
	
	get_tree().change_scene(GameScene)