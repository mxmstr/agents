extends Node

const SPAWN_POSITIONS = [
	Vector2(50, 50),
	Vector2(550, 50),
	Vector2(550, 50),
	Vector2(550, 550),
]

var player_count = 0


func _ready():
	
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	if get_tree().is_network_server():
		spawn_player()


func _connected_to_server():
	
	print('connected')
	
	rpc_id(1, 'update_player_count', get_tree().get_network_unique_id())


func _on_player_disconnected(id):
	
	$Players.get_node(str(id)).queue_free()


func _on_server_disconnected():
	
	$Players.get_tree().change_scene('res://interface/Menu.tscn')


func spawn_player():
	
	var new_player = preload('res://player/Player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	$Players.add_child(new_player)
	
	var info = Network.self_data
	new_player.init(info.name, SPAWN_POSITIONS[player_count], false)


remote func update_player_count(sender_id):
	
	if get_tree().is_network_server():
		player_count += 1
		rpc_id(sender_id, 'send_player_count', player_count)


remote func send_player_count(count):
	
	player_count = count
	print(player_count)
	
	spawn_player()
