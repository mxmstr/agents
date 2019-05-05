extends Control

const HUD_PRESETS = {
	
	'Default' : {
		'visible' : [
			'Nickname',
			],
		},
		
	'Chat' : {
		'visible' : [
			'Nickname',
			'SpeechBubble',
			],
		},
	
	}

var preset = 'Default'


func _apply_hud_preset(container):
	
	for child in container.get_children():
		if child is CanvasItem:
			child.visible = preset['visible'].has(child.name)
			_apply_hud_preset(child)


func _change_hud(new_ui):
	
	preset = HUD_PRESETS[new_ui]
	
	_apply_hud_preset(self)
	rpc('_remote_change_hud', new_ui)


remote func _remote_change_hud(new_ui):
	
	preset = HUD_PRESETS[new_ui]
	
	_apply_hud_preset(self)


func _ready():
	
	_change_hud('Default')