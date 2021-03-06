extends Area2D

onready var player_resource = load("res://shared/player.tscn")
onready var corpse_scene = load("res://shared/corpse.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const BOUNDRY = 10.0

var input_buffer = []
var input_buffer_head = 0

var position_buffer = []
var position_buffer_head = 0

var max_health = 100
var health = max_health
var last_health = health
var hurt_recently = false

var died = false

var previous_last_known_slot = 0
var last_known_slot = 0
var last_input = {
			"up" : false,
			"down" : false,
			"left" : false,
			"right" : false,
			"angle" : PI/2.0,
			"interact" : false,
			"lclick" : false,
			"rclick" : false,
			"slot": 0,
		}

var color = Color.white
var ip = "invalid"
var port = -1
var username = "default"
var at_console = "none"


var server_side = false
var has_sent_packet = false
var is_local = false

var last_known_position = Vector2.ZERO
var last_known_rotation = 0
var last_known_tick = 0
var current_tick = -1

var client_last_known_tick = 0 #for the server to know how far behind client is
var ticks_behind = 0
var allowed_directions = {
	"up": true,
	"up_right": true,
	"right": true,
	"down_right": true,
	"down": true,
	"down_left": true,
	"left": true,
	"up_left": true,
	}
var collision_check = 1.0

func damage(damage):
	
	var damage_dealt = min(health,damage)
	health -= damage_dealt
	return damage_dealt


# Called when the node enters the scene tree for the first time.
func _ready():

	$"player_text/name".set_text(username)
	color.a = 1.0
	$player_text/name.set_modulate(color)
	for _i in range(0, Globals.BUFFER_LENGTH):
		input_buffer.append(last_input.duplicate(true))
		position_buffer.append(Vector2(0,0))
	
	for item in $sprite.get_children():
		item.server_side = server_side

func _physics_process(_delta):	
	if abs(health-last_health) >= 1.0:
		hurt_recently = true
	last_health = health
	
	for input in input_buffer[input_buffer_head]:
		input_buffer[input_buffer_head][input] = last_input[input]
	position_buffer[position_buffer_head] = get_position()
	position_buffer_head = posmod(position_buffer_head + 1, Globals.BUFFER_LENGTH)
	for child in $sprite.get_children():
		child.firing = (input_buffer[input_buffer_head].lclick and input_buffer[input_buffer_head].slot == child.slot_number and at_console=="none")
	cast_rays()
	if server_side:
		if health <= 0.0:
			die()
			died = true #sent to the client
		
		var ship = get_parent()
		match at_console:
			"none":
				move(input_buffer[input_buffer_head])

			"captain":

				ship.inputs.forward = input_buffer[input_buffer_head].up
				ship.inputs.backward = input_buffer[input_buffer_head].down
				ship.inputs.left = input_buffer[input_buffer_head].left
				ship.inputs.right = input_buffer[input_buffer_head].right
			"weapons":
				for system in ship.systems:
					if system.type == "turret":
						system.latest_data = {
							"rotation": input_buffer[input_buffer_head].angle,
							"is_firing": input_buffer[input_buffer_head].lclick
						}
 

		return
	
	if died:
		die()
		died = false

	if is_local:
		for system in $"..".systems:
			system.is_open = at_console == system.type
	if at_console == "none":
		if is_local:

			for slot in $"../../ui/item_slots".get_children():
				slot.selected = false
			$"../../ui/item_slots".get_children()[last_known_slot].selected = true
			$"..".outside_view = false

#			$sprite/gun.firing = (input_buffer[input_buffer_head].lclick and input_buffer[input_buffer_head].slot == 0 and at_console == "none")
		set_position(last_known_position)
		$sprite.set_rotation(last_known_rotation)
		
		var tick_delta = current_tick - last_known_tick #magic one, do not remove. TODO: figure out what it does. oops it's gone
		if tick_delta < Globals.BUFFER_LENGTH:
			$player_text/disconected_sprite.visible = false
			var slot_changed = false
			if previous_last_known_slot != last_known_slot:
				slot_changed = true
			for i in range(-tick_delta, 1):
				var present_input = input_buffer[posmod(input_buffer_head + i, Globals.BUFFER_LENGTH)]

				cast_rays()
				if slot_changed:
					$"../../ui/item_slots".get_children()[present_input.slot].calculate_lifetime(1.0/Globals.NETWORK_UPDATE_INTERVAL)
				move(present_input)
		else:
			$player_text/disconected_sprite.visible = true
	elif at_console == "weapons":
		if is_local:
			$"..".outside_view = true
			
			
	current_tick += 1
	input_buffer_head = posmod(input_buffer_head + 1, Globals.BUFFER_LENGTH)
	previous_last_known_slot = last_known_slot
#	input_buffer[input_buffer_head].interact = false

func cast_rays():
	var space_state =  get_world_2d().direct_space_state

	var ray_direction : Vector2 = Vector2.ZERO
	
	#this is really gross
	for direction in allowed_directions:
		match direction:
			"up": 
				ray_direction = Vector2.UP
				continue
			"up_right": 
				ray_direction = Vector2.UP + Vector2.RIGHT
				continue
			"right": 
				ray_direction = Vector2.RIGHT
				continue
			"down_right": 
				ray_direction = Vector2.DOWN + Vector2.RIGHT
				continue
			"down": 
				ray_direction = Vector2.DOWN
				continue
			"down_left":
				ray_direction = Vector2.DOWN + Vector2.LEFT
				continue
			"left":
				ray_direction = Vector2.LEFT
				continue
			"up_left":
				ray_direction = Vector2.UP + Vector2.LEFT
				continue
		var position_change =  (BOUNDRY*ray_direction.normalized().rotated(global_rotation))
		var result = space_state.intersect_ray(
			global_position, global_position + position_change, [self],	0b100,true,	true)
		allowed_directions[direction] = result.size() <= 0

func network_process():
	pass


func _process(_delta):
	update()

func move(inputs):
	$sprite.set_rotation(inputs.angle)
	var delta = 1.0/Globals.NETWORK_UPDATE_INTERVAL
	var input_vector : Vector2 = Vector2.ZERO
	#This has become horrible too
	if inputs.up and allowed_directions.up:
		input_vector = Vector2.UP
		if inputs.right and allowed_directions.up_right:
			input_vector = Vector2.UP + Vector2.RIGHT
		if inputs.left and allowed_directions.up_left:
			input_vector = Vector2.UP + Vector2.LEFT

	elif inputs.down and allowed_directions.down:
		input_vector = Vector2.DOWN
		if inputs.right and allowed_directions.down_right:
			input_vector = Vector2.DOWN + Vector2.RIGHT
		if inputs.left and allowed_directions.down_left:
			input_vector = Vector2.DOWN + Vector2.LEFT

	elif inputs.right and allowed_directions.right:
		input_vector = Vector2.RIGHT
	elif inputs.left and allowed_directions.left:
		input_vector = Vector2.LEFT

	position += (Globals.PLAYER_SPEED * input_vector.normalized() * delta * collision_check)

func die():
	at_console = "none"
	var new_corpse = corpse_scene.instance()
	get_parent().add_child(new_corpse)
	new_corpse.global_position = global_position
	health = max_health
	position = Vector2(0,0)
