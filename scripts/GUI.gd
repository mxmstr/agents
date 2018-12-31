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


func apply_hud_preset(container):
	
	for child in container.get_children():
		if child is CanvasItem:
			child.visible = preset['visible'].has(child.name)
			apply_hud_preset(child)


func change_hud(new_ui):
	
	preset = HUD_PRESETS[new_ui]
	
	apply_hud_preset(self)
	rpc('remote_change_hud', new_ui)


remote func remote_change_hud(new_ui):
	
	preset = HUD_PRESETS[new_ui]
	
	apply_hud_preset(self)


func _ready():
	
	change_hud('Default')