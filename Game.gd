extends Node

const SPAWN_POSITIONS = [
	Vector2(50, 50),
	Vector2(550, 50),
	Vector2(50, 550),
	Vector2(550, 550),
]
const COLORS = ['Green', 'Red', 'Yellow', 'Blue']
const COMPONENTS = ['Shoes', 'Coat', 'Face', 'Hat',]

var player_count = 0
var player_colors = [{}, {}, {}, {},]


func _ready():
	
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	
	if get_tree().is_network_server():
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
			set = [color1, color2, color2, color2,]
			random_colors.append(shuffle_list(set))
		
		for component_idx in range(4):
			for player_idx in range(4):
				var random_color = random_colors[player_idx][component_idx] 
				player_colors[player_idx][COMPONENTS[component_idx]] = random_color
		
		print(player_colors)
		
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
	
	$Players.get_tree().change_scene('res://interface/Menu.tscn')


func spawn_player():
	
	var new_player = preload('res://player/Player.tscn').instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	$Players.add_child(new_player)
	
	var info = Network.self_data
	new_player.init(
		info.name, SPAWN_POSITIONS[player_count], player_colors[player_count], false)


remote func update_player_info(sender_id):
	
	if get_tree().is_network_server():
		player_count += 1
		rpc_id(sender_id, 'send_player_info', player_count, player_colors)


remote func send_player_info(count, colors):
	
	player_count = count
	player_colors = colors
	
	spawn_player()
