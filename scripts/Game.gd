extends Node

const SPAWN_POSITIONS = [
	Vector2(500, 200),
	Vector2(250, 1000),
	Vector2(-450, 600),
	Vector2(1100, 600),
]
const ROLES = ['Traitor', 'Agent', 'Agent', 'Agent']
const COLORS = ['Red', 'Green', 'Blue', 'Yellow']
const COMPONENTS = ['Hat', 'Eyes', 'Face', 'Coat', 'Pants', 'Shoes']

var player_count = 0
var player_colors = [{}, {}, {}, {},]
var traitor_colors = {}
var player_roles = []
var dead_count = 0

export(String) var PlayerScene
export(String) var MenuScene

signal error
signal victory_good
signal victory_bad


func _ready():
	
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	connect('error', $UI/Chat/Announcements/Error, 'set_text')
	
	if get_tree().is_network_server():
		
		_randomize_colors()
		_spawn_player()


func _adjust_to_virtual_keyboard():
	
	var height = -1 * OS.get_virtual_keyboard_height()# + $MarginContainer.get('custom_constants/margin_bottom')
	
	$UI.offset.y = min(height, 0)
	$World.offset.y = min(height, 0)


func _randomize_colors():
	
	player_roles = _shuffle_list(ROLES.duplicate())
	var traitor_idx = player_roles.find('Traitor')
	var default_colors = [
		COLORS.duplicate(),
		COLORS.duplicate(),
		COLORS.duplicate(),
		COLORS.duplicate(),
		COLORS.duplicate(),
		COLORS.duplicate(),
		]
	
	
	var random_colors = []
	
	for i in range(len(default_colors)):
		var set = _shuffle_list(default_colors[i])
		var color1 = set[0]
		var color2 = set[1]
		
		set = [color1, color2, color2, color2]
		set = _shuffle_list(set)
		
		while set[traitor_idx] == color1:
			set = _shuffle_list(set)
		
		random_colors.append(set)
	
	
	for player_idx in range(4):
		for component_idx in range(6):
			
			var random_color = random_colors[component_idx][player_idx] 
			player_colors[player_idx][COMPONENTS[component_idx]] = random_color
			
			if player_roles[player_idx] == 'Traitor':
				traitor_colors = player_colors[player_idx]


func _shuffle_list(list):
	
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
	
	rpc_id(1, '_update_player_info', get_tree().get_network_unique_id())


func _on_player_disconnected(id):
	
	player_count -= 1
	
	$UI/Chat._player_disconnected(id)
	
	if $World.get_node(str(id)) != null:
		$World.get_node(str(id)).queue_free()


func _on_server_disconnected():
	
	get_tree().change_scene(MenuScene)


func _spawn_player():
	
	var new_player = load(PlayerScene).instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	$World.add_child(new_player)
	$UI/Chat._player_connected(get_tree().get_network_unique_id())
	
	new_player.init(
		false,
		Network.player_name, 
		SPAWN_POSITIONS[player_count], 
		player_colors[player_count],  
		player_roles[player_count],
		traitor_colors.keys()[player_count],
		traitor_colors.values()[player_count]
		)


func _spawn_slave(id, player_name):
	
	var new_player = load(PlayerScene).instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	$World.add_child(new_player)
	
	new_player.init(true, player_name)


remote func _victory_good():
	
	emit_signal('victory_good')


remote func _victory_bad():
	
	emit_signal('victory_bad')


remote func _player_has_died(role):
	
	if get_tree().is_network_server():
		if role == 'Traitor':
			_victory_good()
			rpc('_victory_good')
		elif role == 'Agent':
			dead_count += 1
			if dead_count == 3:
				_victory_bad()
				rpc('_victory_bad')


remote func _update_player_info(sender_id):
	
	if get_tree().is_network_server():
		player_count += 1
		rpc_id(sender_id, '_send_player_info', player_count, player_colors, traitor_colors, player_roles)


remote func _send_player_info(count, colors, t_colors, roles):
	
	player_count = count
	player_colors = colors
	traitor_colors = t_colors
	player_roles = roles
	
	_spawn_player()


func _process(delta):
	
	_adjust_to_virtual_keyboard()