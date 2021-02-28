extends Area2D

onready var player_resource = load("res://shared/player.tscn")
onready var corpse_scene = load("res://shared/corpse.tscn")
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const BOUNDRY = 10.0

var input_buffer = []
var input_buffer_head = 0

const MAX_HEALTH = 100
var health = MAX_HEALTH
var died = false

var last_input = {
			"up" : false,
			"down" : false,
			"left" : false,
			"right" : false,
			"angle" : PI/2.0,
			"interact" : false,
			"lclick" : false,
			"rclick" : false,
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

# Called when the node enters the scene tree for the first time.
func _ready():

	$"player_text/name".set_text(username)
	set_modulate(color)
	for _i in range(0, Globals.BUFFER_LENGTH):
		input_buffer.append( {
			"up" : false,
			"down" : false,
			"left" : false,
			"right" : false,
			"angle" : PI/2.0,
			"interact" : false,
			"lclick" : false,
			"rclick" : false,
		})
	print(server_side)
func _physics_process(_delta):	

	input_buffer[input_buffer_head].up = last_input.up
	input_buffer[input_buffer_head].down = last_input.down
	input_buffer[input_buffer_head].left = last_input.left
	input_buffer[input_buffer_head].right = last_input.right
	input_buffer[input_buffer_head].angle = last_input.angle
	input_buffer[input_buffer_head].interact = last_input.interact
	input_buffer[input_buffer_head].lclick = last_input.lclick
	input_buffer[input_buffer_head].rclick = last_input.rclick
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

	if at_console == "none":
		if is_local:
			$"..".outside_view = false
			$"..".get_node("communications").is_open = false
		set_position(last_known_position)
		$sprite.set_rotation(last_known_rotation)
		var tick_delta = current_tick - last_known_tick - 1 #magic one, do not remove. TODO: figure out what it does. oops it's gone
		if tick_delta < Globals.BUFFER_LENGTH:
			$player_text/discconected_sprite.visible = false
			for i in range(-tick_delta, 1):
	#			print("i: %s" % i)
				var present_input = input_buffer[posmod(input_buffer_head + i, Globals.BUFFER_LENGTH)]
	#			print("input down: %s" % present_input.down)
	#			print("input_buffer_head: %s" % input_buffer_head)
				cast_rays()
				move(present_input)
		else:
			$player_text/discconected_sprite.visible = true
	elif at_console == "weapons":
		if is_local:
			$"..".outside_view = true
	if at_console == "communications":
		if is_local:
			$"..".get_node("communications").is_open = true
	
	
	current_tick += 1
	input_buffer_head = posmod(input_buffer_head + 1, Globals.BUFFER_LENGTH)
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
	var new_corpse = corpse_scene.instance()
	get_parent().add_child(new_corpse)
	new_corpse.global_position = global_position
	health = MAX_HEALTH
	position = Vector2(0,0)
