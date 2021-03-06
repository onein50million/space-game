extends Subsystem


func _ready():
	type = "captain"
	latest_data = {
		"alarm_silenced": false
	}

func _process(_delta):
	var health_ratio = get_parent().health/get_parent().max_health
	if health_ratio < 0.1 and not $warning.playing:
		$warning.play()
	if health_ratio > 0.1:
		$warning.stop()
