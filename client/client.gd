extends Node

const TILE_SIZE = 10
const PARALLAX_EFFECT = 0.1
onready var player_scene = load("res://shared/player.tscn")
onready var local_player = player_scene.instance()
onready var ship_scene = load("res://shared/ship.tscn")
onready var star_scene = load("res://shared/stars.tscn")
onready var asteroid_scene = load("res://shared/asteroid.tscn")
onready var world = load("res://shared/world.tscn").instance()
onready var laser_scene = load("res://shared/items/laser.tscn")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var color = Color.blue
var ip = "127.0.0.1"
var port = 2020
var username = "default"
var ship_name = "test"
var menu

var fake_input = false
var fake_input_direction_count = 0

var last_player_position = Vector2(0,0)
var last_player_rotation = Vector2(0,0)
var last_zoom = 1.0
var starscape

var socket = PacketPeerUDP.new()

var player_list = {}
var ship_list = {}
var misc_objects = {}

var time_ping_sent #microseconds
var network_process_accumulator = 0

var state = "unloaded"

# Called when the node enters the scene tree for the first time.
func _ready():
	print("TEST")
	state = "unconnected"
	add_notification("initializing world")
	add_child(world)

	local_player.color = color
	local_player.ip = ip
	local_player.port = port
	local_player.username = username
	local_player.is_local = true

	
	var new_ship = ship_scene.instance()
	ship_list[ship_name] = new_ship
	add_child(new_ship)
	new_ship.add_child(local_player)
	new_ship.set_name(ship_name)
	
	var new_transform = get_viewport().canvas_transform.translated(get_viewport().size/2.0)
	get_viewport().canvas_transform = new_transform
	last_player_position = local_player.global_position
	last_player_rotation = local_player.global_rotation
	
	make_background()

	player_list[username] = local_player
	socket.connect_to_host(local_player.ip, local_player.port)
	var join_lobby_data = {
		"username" : local_player.username,
		"color" : local_player.color,
		"ship" : ship_name,
	}
	send_command("join_lobby" , join_lobby_data)
	time_ping_sent = OS.get_ticks_usec()
	add_notification("connecting to server")
	state = "connecting"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	local_player.last_input.up = Input.is_action_pressed("up")
	local_player.last_input.down = Input.is_action_pressed("down")
	local_player.last_input.left = Input.is_action_pressed("left")
	local_player.last_input.right = Input.is_action_pressed("right")
	local_player.last_input.lclick = Input.is_action_pressed("lclick")
	local_player.last_input.rclick = Input.is_action_pressed("rclick")

	if Input.is_action_just_pressed("fake_input"):
		fake_input = !fake_input
	if fake_input:
		fake_input_direction_count += 1
		if posmod(fake_input_direction_count,500) > 250:
			local_player.last_input.left = true
		else:
			local_player.last_input.right = true
	if Input.is_action_pressed("slot0"):
		local_player.last_input.slot = 0
	if Input.is_action_pressed("slot1"):
		local_player.last_input.slot = 1
	if Input.is_action_pressed("slot2"):
		local_player.last_input.slot = 2


#	for slot in $ui/item_slots.get_children():
#		slot.selected = false
#	$ui/item_slots.get_children()[local_player.last_input.slot].selected = true
	

	if Input.is_action_just_pressed("interact"):
		local_player.last_input.interact = true
	var mouse_position = local_player.get_local_mouse_position()
	local_player.last_input.angle = mouse_position.angle()
	
	
	var viewport_mouse_position = get_viewport().get_mouse_position()
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	
	var zoom_ratio = clamp(viewport_mouse_position.abs().distance_to(screen_center) / Globals.DEFAULT_ZOOM,0.2,1.0)
	
	if Input.is_action_pressed("overview"):
		zoom_ratio = 16.0
	
	network_process_accumulator += delta
	while 	network_process_accumulator > 1.0/Globals.NETWORK_UPDATE_INTERVAL:
		network_process_accumulator -= 1.0/Globals.NETWORK_UPDATE_INTERVAL
		network_process()
		

	#transform stuff because godot's camera was having jitter issues
	#I have no idea what I'm doing
	var zoom_delta = last_zoom/zoom_ratio
	var player_position_delta = last_player_position - local_player.global_position
	var player_rotation_delta = last_player_rotation - local_player.global_rotation

	var new_transform = get_viewport().canvas_transform.translated(player_position_delta)
	var delta_center = new_transform.xform(local_player.global_position) - screen_center
	
	new_transform.origin -= (delta_center)
	
	new_transform.origin += -screen_center
	new_transform = new_transform.scaled(Vector2(zoom_delta,zoom_delta))
	new_transform = new_transform.rotated(player_rotation_delta)
	new_transform.origin += screen_center
	
	last_zoom = zoom_ratio
	get_viewport().canvas_transform = new_transform
	last_player_position = local_player.global_position
	last_player_rotation = local_player.global_rotation
	update_background()
func network_process():
	while socket.get_available_packet_count() > 0:
		process_packet(socket.get_var())
	if state == "connected":
		for player in player_list.values():
			player.network_process()
		for system in local_player.get_parent().systems:
			if local_player.at_console == system.type:
				var systems_update_send_data = {
					"type" : system.type,
					"systems_data" : system.client_send_data,
				}
				send_command("systems_update", systems_update_send_data)
		send_command("input_update", local_player.last_input)
		local_player.last_input.interact = false
	elif state == "connecting" and local_player.current_tick > Globals.BUFFER_LENGTH:
		add_notification("connection failed")
		exit_scene("connection failed")
func _physics_process(delta):
	pass
	
func process_packet(received):
	if typeof(received) != TYPE_DICTIONARY:
		print("packet_not_dict")
		return
	if !received.has("command"):
		print("invalid_command")
		return
	match received.command:
		"join_accepted":
			state = "connected"
			add_notification("connection succeeded")
			var round_trip_time = float(OS.get_ticks_usec() - time_ping_sent)
			print("round trip time: %s: " % round_trip_time)
			var ticks_behind = (round_trip_time/2000000.0) / (1.0/Globals.NETWORK_UPDATE_INTERVAL)
			print("ticks behind: %s" % ticks_behind)
			local_player.current_tick = received.tick + int(round(ticks_behind))
			send_command("ping", "ping")
		"update":
			process_update(received)
		"error":
			print("Error received: %s" % received.msg)
			exit_scene(received.msg)
			
		"ping_return":
			var round_trip_time = float(OS.get_ticks_usec() - time_ping_sent)
			var ticks_behind = (round_trip_time/2000000.0) / (1.0/Globals.NETWORK_UPDATE_INTERVAL)
			var tick_delta = abs(local_player.current_tick - received.tick + int(round(ticks_behind)))
			
			#this might have been causing issues so I made it only happen in extreme circumstances
			if tick_delta > Globals.BUFFER_LENGTH:
				tick_delta = received.tick + int(round(ticks_behind))
#			print("Ping: %s ms" % (round_trip_time/1000.0))
			send_command("ping", "ping")
			time_ping_sent = OS.get_ticks_usec()
		_:
			print("unknown_command")

func process_update(received):
	if !received.has("data"):
		print("update has no data")
		return
	
	for received_ship in received.data.ships:
		if not ship_list.has(received_ship.name):
			var new_ship = ship_scene.instance()
			add_child(new_ship)
			new_ship.set_mode(RigidBody2D.MODE_KINEMATIC)
			new_ship.set_name(received_ship.name)
			ship_list[received_ship.name] = new_ship
			
		ship_list[received_ship.name].set_position(received_ship.position)
		ship_list[received_ship.name].set_rotation(received_ship.rotation)
		ship_list[received_ship.name].ship_velocity = received_ship.velocity
		for i in range(0,ship_list[received_ship.name].systems.size()):
			#this is kinda sketch because it relies on both the client and server making the arrays in the same order
			ship_list[received_ship.name].systems[i].latest_data = received_ship.subsystems[i].data
	
	for received_object in received.data.misc_objects:
		if not misc_objects.has(received_object.misc_id):
			var new_object
			match received_object.type:
				"asteroid":
					new_object = asteroid_scene.instance()
				_:
					new_object = asteroid_scene.instance()
					print("unknown object type")
			new_object.set_position(received_object.position)
			new_object.set_mode(RigidBody2D.MODE_KINEMATIC)
			new_object.misc_id = received_object.misc_id
			add_child(new_object)
			misc_objects[received_object.misc_id] = new_object
		misc_objects[received_object.misc_id].set_position(received_object.position)
		misc_objects[received_object.misc_id].set_rotation(received_object.rotation)
	
	for received_shot in received.data.shots:
		var new_laser = laser_scene.instance()
		ship_list[received_shot.ship].add_child(new_laser)
		new_laser.modulate = Color.red
		new_laser.points[0] = received_shot.laser_start
		new_laser.points[1] = received_shot.laser_end

	for received_player in received.data.clients:
		if !player_list.has(received_player.username):
			var new_player = player_scene.instance()
			new_player.set_position(received_player.position)
			new_player.username = received_player.username
			new_player.color = received_player.color
			player_list[received_player.username] = new_player
			ship_list[received_player.ship].add_child(new_player)
			print("spawning player")

		#ship changing
		if player_list[received_player.username].get_parent().get_name() != received_player.ship:
			player_list[received_player.username].get_parent().remove_child(player_list[received_player.username])
			ship_list[received_player.ship].add_child(player_list[received_player.username])
#		local_player.last_known_position = received_player.position
#		local_player.last_known_tick = received.tick
		player_list[received_player.username].last_known_position = received_player.position
		player_list[received_player.username].last_known_rotation = received_player.rotation
		player_list[received_player.username].last_known_slot = received_player.slot
		player_list[received_player.username].last_known_tick = received_player.last_known_tick
		player_list[received_player.username].at_console = received_player.at_console
		player_list[received_player.username].health = received_player.health

		if received_player.died:
			player_list[received_player.username].died = true
func send_command(command, data):
	socket.put_var({
		"command": command,
		"tick" : local_player.current_tick,
		"last_received": local_player.last_known_tick,
		"ticks_behind": local_player.current_tick - local_player.last_known_tick,
		"data" : data
	})

func make_background():
	starscape = Node2D.new()
	for row in range(0, TILE_SIZE):
		for column in range (0,TILE_SIZE):
			var new_star = star_scene.instance()
			var tile_dimensions = Vector2(new_star.get_texture().get_height(),new_star.get_texture().get_width())
			var tile_position = Vector2(tile_dimensions.x*row, tile_dimensions.y*column) - (TILE_SIZE/2.0)*tile_dimensions
			new_star.global_position = local_player.global_position + tile_position
			starscape.add_child(new_star)
	add_child(starscape)
func update_background():
	starscape.global_position = local_player.global_position - Vector2(
		posmod(local_player.global_position.x*PARALLAX_EFFECT, 512),
		posmod(local_player.global_position.y*PARALLAX_EFFECT, 512))
	

func add_notification(message):
	var notifications_box = $ui/notifications_scroll/notifications_vbox
	var new_label = Label.new()
	notifications_box.add_child(new_label)
	new_label.text = message

func exit_scene(error):
#	menu.get_parent().remove_child(menu)

	get_tree().get_root().add_child(menu)
	var canvas = CanvasLayer.new()
	menu.add_child(canvas)
	var error_dialog = AcceptDialog.new()
	
	canvas.add_child(error_dialog)
	error_dialog.set_text(error)
	error_dialog.popup_centered()
	

	queue_free()
