extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var port = 2020
var socket = PacketPeerUDP.new()

var client_list = {}
var disconnected_client_list = []
var ship_list = {}
var misc_objects = {}

var misc_id = 0

var current_tick = 0
var current_camera = Camera2D.new()

var time_since_last_update
onready var player_scene = preload("res://player.tscn")
onready var ship_scene = preload("res://ship.tscn")
onready var asteroid_scene = load("res://asteroid.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	socket.listen(port)
	time_since_last_update = OS.get_ticks_usec()

	var new_asteroid = spawn_body(asteroid_scene)
func _process(delta):
	var delta_time = OS.get_ticks_usec() - time_since_last_update
	if delta_time/1000000.0 > 1.0/Globals.NETWORK_UPDATE_INTERVAL:
		time_since_last_update = OS.get_ticks_usec()
		
		network_process()
		for client in client_list.values():
			client.network_process()	
		current_tick += 1

func network_process():
	for client_key in client_list.keys():
		#if last_known_tick is within 3 seconds of 0, probably still connecting and syncing
		var tick_delta = current_tick - client_list[client_key].last_known_tick
		if client_list[client_key].has_sent_packet and tick_delta > Globals.BUFFER_LENGTH:

			client_list[client_key].has_sent_packet = false
			socket.set_dest_address(client_list[client_key].ip, client_list[client_key].port)
			send_error("connection_dropped")
			client_list[client_key].ip = "no_ip"
			client_list[client_key].port = -1
			
			disconnected_client_list.append(client_list[client_key])
			client_list.erase(client_key)


	while socket.get_available_packet_count() > 0:
		process_packet(socket.get_var())
	send_updates()



func _physics_process(delta):
	pass

func process_packet(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	socket.set_dest_address(packet_ip, packet_port)
	
	if typeof(received) != TYPE_DICTIONARY:
		send_error("packet_not_dict")
		return
	if !received.has("command"):
		send_error("invalid_command")
		return
	match received.command:
		"join_lobby":
			handle_join(received)
		"input_update":
			handle_input(received)
		_:
			send_error("unknown_command")

func handle_join(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if client_list.has(client_id):
		send_error("already_connected")
		return
	for client in client_list.values():
		if client.username == received.data.username:
			send_error("username_taken")
			return
	for i in range(0, disconnected_client_list.size()):
		#check if trying to join as unconnected client
		if disconnected_client_list[i].username == received.data.username:
			client_list[client_id] = disconnected_client_list[i]
			disconnected_client_list.remove(i)
			client_list[client_id].ip = packet_ip
			client_list[client_id].port = packet_port
			client_list[client_id].last_known_tick = current_tick
			$CanvasLayer/playerlist.text += "\n%s" % [client_id]
			send_command("join_accepted", "welcome")
			return
	var new_player = player_scene.instance()
	new_player.color = received.data.color
	new_player.username = received.data.username
	new_player.ip = packet_ip
	new_player.port = packet_port
	new_player.server_side = true
	if not ship_list.has(received.data.ship):
		var new_ship = spawn_body(ship_scene, true)
		new_ship.server_side = true
		new_ship.set_name(received.data.ship)
		ship_list[received.data.ship] = new_ship
	ship_list[received.data.ship].add_child(new_player)
	client_list[client_id] = new_player 
	new_player.add_child(current_camera)
	current_camera.make_current()
	$CanvasLayer/playerlist.text += "\n%s" % [client_id]
	send_command("join_accepted", "welcome")

func handle_input(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if !client_list.has(client_id):
		send_error("not_connected")
		return
	var local_client = client_list[client_id]
	
	local_client.has_sent_packet = true
	local_client.input_buffer[local_client.input_buffer_head] = received.data.duplicate()
	local_client.last_known_tick = received.tick
	
func send_error(message):
	print("sent error: %s" % [message])
	socket.put_var({
		"command": "error",
		"msg" : message
	})

func send_updates():
	var send_client_data = {
		"clients": [],
		"ships" : [],
		"misc_objects" : []
	}
	for ship in ship_list:
		send_client_data.ships.append({
			"name" : ship,
			"position" : ship_list[ship].get_position(),
			"rotation" : ship_list[ship].get_rotation(),
			"velocity" : ship_list[ship].get_linear_velocity(),
		})
	for object in misc_objects.values():
		send_client_data.misc_objects.append({
			"type" : object.object_type,
			"misc_id": object.misc_id,
			"position" : object.get_position(),
			"rotation" : object.get_rotation(),
		})
	for client_id in client_list:
		send_client_data.clients.append({
			"position" : client_list[client_id].get_position(),
			"ship" : client_list[client_id].get_parent().name,
			"username" : client_list[client_id].username,
			"color" : client_list[client_id].color,
			"last_known_tick" : client_list[client_id].last_known_tick,
		})
	for client in client_list.values():
		socket.set_dest_address(client.ip, client.port)
		send_command("update", send_client_data)
		
func send_command(command,data):
	socket.put_var({
		"command" : command,
		"tick" : current_tick,
		"data" : data
	})

func spawn_body(body, is_ship = false):
	var new_body = body.instance()
	add_child(new_body)
	if not is_ship:
		new_body.misc_id = misc_id
		misc_objects[misc_id] = new_body
		misc_id += 1
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	while(true):
		var random_location = Vector2(
			rng.randf_range(Globals.GAME_AREA.position.x, Globals.GAME_AREA.end.x),
			rng.randf_range(Globals.GAME_AREA.position.y, Globals.GAME_AREA.end.y)
		)
		var minimum_distance = INF
		for ship in ship_list.values():
			var distance = random_location.distance_to(ship.get_position())
			if distance < minimum_distance:
				minimum_distance = distance
		for object in misc_objects.values():
			var distance = random_location.distance_to(object.get_position())
			if distance < minimum_distance:
				minimum_distance = distance
		if minimum_distance > Globals.SAFE_DISTANCE:
			new_body.set_position(random_location)
			break
	return new_body
