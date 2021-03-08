extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

class radar_contact:
	var lifetime = 1.0
	var position = Vector2(0,0)
	var size = 0.5
	

const RADAR_DISTANCE = 10000.0
const RADAR_DETECTION_ANGLE = TAU/16.0
const BEAM_TRAIL_LENGTH = 1 #doesn't look as good as I hoped(weird aliasing artifacts), so just keeping it at 1
const LIFETIME = 1.0
const RADAR_DISPLAY_RADIUS = 25.0

var contacts = {}

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
	var main = get_parent().get_parent().get_parent()
	for object in main.misc_objects.values():
#		draw_contact(object, 0.5)
		match object.object_type:
			"guts":
				call_deferred("draw_contact",object,0.1)
			_:
				call_deferred("draw_contact",object,0.5)
	for ship in main.ship_list.values():
		call_deferred("draw_contact",ship,2.0)
#		draw_contact(ship, 1.0)
	var new_contacts = {}
	for contact in contacts:
		if contact:
			contacts[contact].lifetime -= delta
			if contacts[contact].lifetime > 0.0:
				new_contacts[contact] = contacts[contact] 
	contacts = new_contacts
func _draw():
	pass
	for i in range(0, BEAM_TRAIL_LENGTH):
		var beam_color = Color.green
		beam_color.a = (BEAM_TRAIL_LENGTH-float(i))/BEAM_TRAIL_LENGTH
		draw_line(Vector2(0,0),Vector2(RADAR_DISPLAY_RADIUS,0).rotated(angle - i*TAU*0.01),beam_color)
	for contact in contacts.values():
		draw_circle(contact.position,contact.size,Color.green)
		
func draw_contact(object, size):
	var angle_to_object = global_position.angle_to_point(object.global_position)
	var distance_to_object = global_position.distance_to(object.global_position)
	var global_angle = fposmod(angle+global_rotation + PI,TAU)

	var is_new = true

	var delta_angle = fposmod(abs(angle_to_object-global_angle),TAU)
	if delta_angle < RADAR_DETECTION_ANGLE and is_new and distance_to_object < RADAR_DISTANCE and object != get_parent().get_parent():
		var new_contact = radar_contact.new()
		get_parent().get_node("ping").volume_db = (1/size) * -10
		get_parent().get_node("ping").play()
		new_contact.position =  Vector2((distance_to_object/RADAR_DISTANCE)*RADAR_DISPLAY_RADIUS,0.0).rotated(angle_to_object-global_rotation + PI)
		new_contact.size = size
		contacts[object] = new_contact
