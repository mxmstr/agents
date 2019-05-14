extends Node

const MASTER_SERVER = 'http://mxmstr.pythonanywhere.com/servers'
const JOIN_SERVER_TIMEOUT = 5
const SERVER_QUERY_TIME = 10
const MAX_CLIENTS = 3

var player_name = 'Agent'
var server_name = null
var ip = null
var port = null
var clients = 1

var hosts = { }
var players = { }
var local_player_id = 1

signal clients_updated
signal server_info_posted
signal host_list_requested
signal player_disconnected
signal server_disconnected


func _server_is_full():
	
	return clients == MAX_CLIENTS + 1


func _ready():
	
	#print(IP.get_local_addresses())
	
	
	var addrs = IP.get_local_addresses()

	for addr in addrs:
#		if addr.begins_with('100.'):
#			ip = addrs[addrs.find(addr) + 3]
#			break
		if addr.begins_with('192.'):
			ip = addr#addrs[addrs.find(addr) + 2]
			break
		if addr.begins_with('172.'):
			ip = addr#addrs[addrs.find(addr) + 2]
			break
		if addr.begins_with('10.'):
			ip = addr#addrs[addrs.find(addr) + 2]
			break
	
	var get_request = HTTPRequest.new()
	get_request.name = 'HostListRequest'
	get_request.connect('request_completed', self, '_on_host_list_requested')
	add_child(get_request)
	
	var post_request = HTTPRequest.new()
	post_request.name = 'PostServerRequest'
	post_request.connect('request_completed', self, '_on_post_game_info')
	add_child(post_request)
	
	var query_timer = Timer.new()
	query_timer.name = 'QueryTimer'
	query_timer.wait_time = SERVER_QUERY_TIME
	query_timer.connect('timeout', self, '_post_game_info')
	add_child(query_timer)
	
	var join_timer = Timer.new()
	join_timer.name = 'JoinTimer'
	join_timer.wait_time = JOIN_SERVER_TIMEOUT
	join_timer.connect('timeout', get_tree(), 'emit_signal', ['server_disconnected'])
	add_child(join_timer)
	
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')


func _post_game_info():
	
	var headers = ["Content-Type: application/json"]
	var query = JSON.print({
		'action': 'update',
		'ip': ip,
		'server_name': server_name,
		'port': port,
		'clients': clients
		})
	
	$PostServerRequest.request(Network.MASTER_SERVER, headers, true, HTTPClient.METHOD_POST, query)
	print('post')


func _post_game_ended():
	
	var headers = ["Content-Type: application/json"]
	var query = JSON.print({
		'action': 'delete',
		'ip': ip,
		'server_name': server_name,
		'port': port,
		'clients': clients
		})
	
	$PostServerRequest.request(Network.MASTER_SERVER, headers, true, HTTPClient.METHOD_POST, query)
	print('end')


func _on_post_game_info(result, response_code, headers, body):
	
	#print([result, response_code, str(headers), body])
	
	if response_code == 200:
		
		#print(body.get_string_from_utf8())
		var json = JSON.parse(body.get_string_from_utf8())
		#print(json.result)
	
	emit_signal('server_info_posted')


func _request_host_list():
	
	$HostListRequest.request(Network.MASTER_SERVER)


func _on_host_list_requested(result, response_code, headers, body):
	
	if response_code == 200:
		
		#print(body.get_string_from_utf8())
		var json = JSON.parse(body.get_string_from_utf8())
		#print(json.result)
		hosts = json.result
		
		emit_signal('host_list_requested')


func _create_server():
	
	clients = 1
	
	players[1] = { 'name': player_name }
	
	var peer = NetworkedMultiplayerENet.new()
	var error = peer.create_server(port, MAX_CLIENTS)
	
	if error == OK:
		get_tree().set_network_peer(peer)
		print('start')
		$QueryTimer.start()
	
	return error


func _connect_to_server():
	
	clients = 1
	
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	
	var peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(ip, port)
	
	if error == OK:
		get_tree().set_network_peer(peer)
		$JoinTimer.start()
		
	return error


func _connected_to_server():
	
	$JoinTimer.stop()
	
	local_player_id = get_tree().get_network_unique_id()
	players[local_player_id] = { 'name': player_name }
	
	rpc('_send_player_info', local_player_id, player_name)


func _on_player_disconnected(id):
	
	players.erase(id)
	clients -= 1
	emit_signal('clients_updated', clients)
	
	if get_tree().is_network_server():
		_post_game_info()


func _on_player_connected(connected_player_id):
	
	print('connected')
	
	local_player_id = get_tree().get_network_unique_id()
	clients += 1
	emit_signal('clients_updated', clients)
	
	if get_tree().is_network_server():
		_post_game_info()
	else:
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)


func _on_server_disconnected():
	
	print('stop')
	_post_game_ended()
	$QueryTimer.stop()
	$JoinTimer.stop()


remote func _request_player_info(request_from_id, player_id):
	
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_player_info', player_id, players[player_id].name)


remote func _send_player_info(_id, _player_name):
	
	players[_id] = { 'name': _player_name }
	
	$'/root/Game'._spawn_slave(_id, _player_name)
