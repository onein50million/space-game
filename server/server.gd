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

var time_last_mission_requested = 0
var missions = []

var current_tick = 0
var current_camera = Camera2D.new()

var network_process_accumulator = 0
onready var player_scene = preload("res://shared/player.tscn")
onready var ship_scene = preload("res://shared/ship.tscn")
onready var asteroid_scene = load("res://shared/asteroid.tscn")
onready var world = load("res://shared/world.tscn").instance()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(world)
	socket.listen(port)
	spawn_body(asteroid_scene)
func _process(delta):

	process_systems()
	network_process_accumulator += delta
	if 	network_process_accumulator > 1.0/Globals.NETWORK_UPDATE_INTERVAL:
		network_process_accumulator -= 1.0/Globals.NETWORK_UPDATE_INTERVAL
		
		network_process()
		current_tick += 1

func network_process():
	for client_key in client_list.keys():
		client_list[client_key].network_process()	
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


func process_systems():
	for ship in ship_list.values():
		for system in ship.systems:
			match system.type:
				"communications":
					system.latest_data.ship_name = ship.name
					system.latest_data.missions = missions
				"_":
					pass
func _physics_process(_delta):
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
		"systems_update":
			handle_systems_update(received)
		"ping":
			send_command("ping_return", "pong")
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
	var current_client = client_list[client_id]
	
	if received.data.interact:
		handle_interact(current_client)

	current_client.has_sent_packet = true
	current_client.last_input = received.data.duplicate()
	current_client.last_known_tick = received.tick


func handle_systems_update(received):
	var packet_ip = socket.get_packet_ip()
	var packet_port = socket.get_packet_port()
	var client_id = "%s:%s" % [packet_ip, packet_port]
	if !client_list.has(client_id):
		send_error("not_connected")
		return
	
	var current_client = client_list[client_id]
	if current_client.at_console == received.data.type:
		match received.data.type:
			"communications":
				if received.data.systems_data.request_mission and OS.get_ticks_usec() - time_last_mission_requested > Globals.MISSION_FREQUENCY:
					time_last_mission_requested = OS.get_ticks_usec()
					new_mission()
			"_":
				pass
#fun indent slide
func handle_interact(current_client):
	if current_client.at_console == "none":
		for ship in ship_list.values():
			for system in ship.systems:
				if system.has_node("chair"):
					var chair_collisions = system.get_node("chair").get_overlapping_areas()
					for collision in chair_collisions:
						if collision == current_client:
							current_client.at_console = system.type
							return
	else:
		current_client.at_console = "none"


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
		var subsystem_send = []
		for subsystem in ship_list[ship].systems:
			var data = subsystem.latest_data.duplicate(true)
			subsystem_send.append({
				"type" : subsystem.type,
				"data": data
			})

		send_client_data.ships.append({
			"name" : ship,
			"position" : ship_list[ship].get_position(),
			"rotation" : ship_list[ship].get_rotation(),
			"velocity" : ship_list[ship].get_linear_velocity(),
			"subsystems" : subsystem_send,
		})
	for object in misc_objects.values():
		send_client_data.misc_objects.append({
			"type" : object.object_type,
			"misc_id": object.misc_id,
			"position" : object.get_position(),
			"rotation" : object.get_rotation(),
		})
		
	#we want to see where disconnected people are standing (no ghosts allowed)
	var iterate_clients = []
	for client_id in client_list:
		iterate_clients.append(client_list[client_id])
	iterate_clients += disconnected_client_list
	for client in iterate_clients:
		send_client_data.clients.append({
			"position" : client.get_position(),
			"rotation" : client.get_node("sprite").get_rotation(),
			"health": client.health,
			"died": client.died,
			"at_console" : client.at_console,
			"ship" : client.get_parent().name,
			"username" : client.username,
			"color" : client.color,
			"last_known_tick" : client.last_known_tick,
		})
		client.died = false
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


func new_mission():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var verbs = ["rescue", "kill", "destroy", "save", "identify"]
	var adjectives = ["tasty", "hungry", "ferocious", "evil", "scary"]
	var nouns = ["monsters", "pirates", "aliens", "bugs", "allies"]
	
	var verb = verbs[rng.randi_range(0,verbs.size()-1)]
	var number = rng.randi_range(3,15)
	var adjective = adjectives[rng.randi_range(0,adjectives.size()-1)]
	var noun = nouns[rng.randi_range(0,nouns.size()-1)]
	var mission_title = "%s the %s %s %s" %[verb,number,adjective,noun]
	missions.append({
		"title" : mission_title,
		"complete": false
	})
