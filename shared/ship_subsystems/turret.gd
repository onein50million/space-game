extends Subsystem


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var FIRE_RATE = 1000000 #in microseconds (usec)
var RANGE = 1000.0
var DAMAGE = 1000.0
const FORCE_RATIO = 0.1
var last_fired = 0

onready var bullet_scene = load("res://shared/ship_subsystems/railgun-round.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	type = "turret"
	latest_data = {
	"rotation": 0,
	"is_firing": false,
}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var delta_fire = OS.get_ticks_usec() - last_fired
	if delta_fire > FIRE_RATE and latest_data.is_firing and server_side:
		var ship = get_parent().get_parent()
		var recoil_offset = global_position - ship.global_position
		ship.apply_impulse(recoil_offset,-Vector2(DAMAGE*FORCE_RATIO,0).rotated(global_rotation))
		$railgun_sound.play()
		$muzzle_blast.emitting = true
		last_fired = OS.get_ticks_usec()
		var damage_left = DAMAGE
		var distance_travelled = 0.0
		var space_state =  get_world_2d().direct_space_state
		var hit_objects = []
		var current_ship_shield = []
		for system in ship.systems:
			if system.type == "shield":
				current_ship_shield += system.get_node("shield_area")

		while damage_left > 0.0 and distance_travelled < RANGE:
			var starting_point = global_position + Vector2(min(RANGE-1.0,distance_travelled),0).rotated(global_rotation)
			var final_destination = global_position + Vector2(RANGE,0).rotated(global_rotation)
			var result = space_state.intersect_ray(
				starting_point, final_destination, [$"../.."] + hit_objects + current_ship_shield,0b1100010,true, true)
			if "position" in result:
				hit_objects.append(result.collider)
				final_destination = result.position
				if result.collider.is_in_group("health"): #health objects absorb the impact
					damage_left -= result.collider.damage(DAMAGE)
					force_update_transform()
					distance_travelled += starting_point.distance_to(final_destination)
				elif result.collider.get_class() == "RigidBody2D": #rigidbodies stop the railgun
					distance_travelled += RANGE
					damage_left = 0
					var offset = final_destination - result.collider.global_position
					result.collider.apply_impulse(offset,Vector2(damage_left*FORCE_RATIO,0).rotated(global_rotation))
			else:
				distance_travelled += RANGE
			var new_line = bullet_scene.instance()
			$"../../..".add_child(new_line)
			new_line.points = PoolVector2Array([global_position,final_destination])
			ship.get_parent().unprocessed_shots.append({
				"laser_start":starting_point,
				"laser_end": final_destination,
				"type": "railgun",
				"ship": ship.name,
				"player":"none"
			})
	elif delta_fire > FIRE_RATE and latest_data.is_firing and not server_side:
		$railgun_sound.play()
		$muzzle_blast.emitting = true
		last_fired = OS.get_ticks_usec()
	if "rotation" in latest_data:
		set_rotation(latest_data.rotation)
