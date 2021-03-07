extends Subsystem


func _ready():
	type = "captain"
	latest_data = {
		"alarm_silenced": false
	}

func _process(_delta):
	var ship = get_parent()
	var health_ratio = ship.health/ship.max_health
	if health_ratio < 0.1 and not $warning.playing:
		$warning.play()
	if health_ratio > 0.1:
		$warning.stop()
	$console/panel/right_vbox/velocity.text = "Velocity: %.1f" % ship.ship_velocity.length()
	$console/panel/direction.rotation = global_position.angle_to_point(Vector2.ZERO) - global_rotation - PI/2.0
	$console/panel/left_vbox/x_pos.text = "X: %.1f" % ship.position.x
	$console/panel/left_vbox/y_pos.text = "Y: %.1f" %ship.position.y
