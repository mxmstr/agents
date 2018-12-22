extends Node

const SPAWN_POSITIONS = [
	Vector2(300, 30),
	Vector2(500, 210),
	Vector2(350, 490),
	Vector2(60, 460),
]
const ROLES = ['Traitor', 'Agent', 'Agent', 'Agent']
const COLORS = ['Green', 'Red', 'Yellow', 'Blue']
const COMPONENTS = ['Shoes', 'Coat', 'Face', 'Hat']

var player_count = 0
var player_colors = [{}, {}, {}, {},]
var traitor_colors = {}
var player_roles = []
var dead_count = 0

signal victory_good
signal victory_bad


func _ready():
	
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	if get_tree().is_network_server():
		player_roles = shuffle_list(ROLES.duplicate())
		var traitor_idx = player_roles.find('Traitor')
		
		var default_colors = [
			COLORS.duplicate(),
			COLORS.duplicate(),
			COLORS.duplicate(),
			COLORS.duplicate(),
			]
		
		var random_colors = []
		for i in range(len(default_colors)):
			var set = shuffle_list(default_colors[i])
			var color1 = set[0]
			var color2 = set[1]
			
			set = [color1, color2, color2, color2]
			set = shuffle_list(set)
			
			while set[traitor_idx] == color1:
				set = shuffle_list(set)
			
			random_colors.append(set)
		
		for player_idx in range(4):
			for component_idx in range(4):
				
				var random_color = random_colors[component_idx][player_idx] 
				player_colors[player_idx][COMPONENTS[component_idx]] = random_color
				
				if player_roles[player_idx] == 'Traitor':
					traitor_colors = player_colors[player_idx]
		
		spawn_player()


func shuffle_list(list):
	
    var shuffledList = []
    var indexList = range(list.size())
    for i in range(list.size()):
        randomize()
        var x = randi()%indexList.size()
        shuffledList.append(list[x])
        indexList.remove(x)
        list.remove(x)
    return shuffledList


func _connected_to_server():
	
	rpc_id(1, 'update_player_info', get_tree().get_network_unique_id())


func _on_player_disconnected(id):
	
	$Players.get_node(str(id)).queue_free()


func _on_server_disconnected():
	
	get_tree().network_peer.close_connection()
	get_tree().set_network_peer(null)
	get_tree().change_scene('res://interface/Menu.tscn')


func spawn_player():
	
	var new_player = preload('res://player/Player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	$Players.add_child(new_player)
	
	var info = Network.self_data
	new_player.init(
		info.name, 
		SPAWN_POSITIONS[player_count], 
		player_colors[player_count],  
		player_roles[player_count],
		traitor_colors.keys()[player_count],
		traitor_colors.values()[player_count],
		false
		)


remote func victory_good():
	
	emit_signal('victory_good')


remote func victory_bad():
	
	emit_signal('victory_bad')


remote func player_has_died(role):
	
	if get_tree().is_network_server():
		if role == 'Traitor':
			victory_good()
			rpc('victory_good')
		elif role == 'Agent':
			dead_count += 1
			if dead_count == 3:
				victory_bad()
				rpc('victory_bad')


remote func update_player_info(sender_id):
	
	if get_tree().is_network_server():
		player_count += 1
		rpc_id(sender_id, 'send_player_info', player_count, player_colors, traitor_colors, player_roles)


remote func send_player_info(count, colors, t_colors, roles):
	
	player_count = count
	player_colors = colors
	traitor_colors = t_colors
	player_roles = roles
	
	spawn_player()
