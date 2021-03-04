extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const RADAR_DISTANCE = 10000.0
const RADAR_DETECTION_ANGLE = TAU/16.0
const BEAM_TRAIL_LENGTH = 1 #doesn't look as good as I hoped(weird aliasing artifacts), so just keeping it at 1
const LIFETIME = 1.0
const RADAR_DISPLAY_RADIUS = 25.0

var contacts = PoolVector2Array([])

onready var radar_contact = preload("res://shared/ship_subsystems/map/radar_contact.tscn")
var angle = 0
var rotate_speed = TAU/2.0
# Called when the node enters the scene tree for the first time.
func _ready():
	$"../radar_distance".set_text("D: %s" % RADAR_DISTANCE)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	angle = fposmod(angle + rotate_speed*delta,TAU)
	update()

func _draw():
	for i in range(0, BEAM_TRAIL_LENGTH):
		var beam_color = Color.green
		beam_color.a = (BEAM_TRAIL_LENGTH-float(i))/BEAM_TRAIL_LENGTH
		draw_line(Vector2(0,0),Vector2(RADAR_DISPLAY_RADIUS,0).rotated(angle - i*TAU*0.01),beam_color)
	var main = get_parent().get_parent().get_parent()
	for object in main.misc_objects.values():
#		draw_contact(object, 0.5)
		match object.object_type:
			"guts":
				call_deferred("draw_contact",object,0.1)
			_:
				call_deferred("draw_contact",object,0.5)
	for ship in main.ship_list.values():
		call_deferred("draw_contact",ship,1.0)
#		draw_contact(ship, 1.0)
func draw_contact(object, size):
	var angle_to_object = global_position.angle_to_point(object.global_position)
	var distance_to_object = global_position.distance_to(object.global_position)
	var global_angle = fposmod(angle+global_rotation + PI,TAU)

	var is_new = true
	
	#performance problems when iterating over large arrays
	
	#using while loop
#	var i = 0
#	var contacts_size = contacts.size()
#	while i < contacts_size:
#		if contacts[i].distance_squared_to(object.global_position) < 10.0:
#			is_new = false
#		i += 1

	#using range()
#	for i in range(0,contacts.size()):
#		if contacts[i].distance_to(object.global_position) < 10.0:
#			is_new = false
	#using in
#	for contact in contacts:
#		if contact.distance_to(object.global_position) < 10.0:
#			is_new = false
	var delta_angle = fposmod(abs(angle_to_object-global_angle),TAU)
	if delta_angle < RADAR_DETECTION_ANGLE and is_new and distance_to_object < RADAR_DISTANCE and object != get_parent().get_parent():
		var new_contact = radar_contact.instance()
		add_child(new_contact)
		new_contact.lifetime = LIFETIME
		new_contact.position = Vector2((distance_to_object/RADAR_DISTANCE)*RADAR_DISPLAY_RADIUS,0.0).rotated(angle_to_object-global_rotation + PI)
		new_contact.real_position = object.global_position
		new_contact.size = size
#		contacts.append(object.global_position)
#		if contacts.size() > 1000:
#			contacts = PoolVector2Array([])
