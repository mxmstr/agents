extends Node2D

export(Resource) var effect
export(float) var frequency
#export(float) var decay


func _ready():
	
	$Timer.connect('timeout', self, '_on_timeout')
	_stop()


func _process(delta):
	
	$Timer.wait_time = frequency
	
#	if decay > 0:
#		$Timer.wait_time -= decay * delta
#		$Timer.wait_time = max(0, $Timer.wait_time)


func _on_timeout():
	
	add_child(effect.instance())


func _start():

	$Timer.wait_time = frequency
	set_process(true)
	$Timer.start()


func _stop():
	
	set_process(false)
	$Timer.stop()