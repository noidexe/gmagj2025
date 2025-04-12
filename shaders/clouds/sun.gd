@tool
extends DirectionalLight3D

var atmosphere_tex := load("res://shaders/clouds/sky_lut.tres")
var cloud_sky := load("res://shaders/clouds/clouds_sky.tres")

func _ready():
	cloud_sky.sun = self
	cloud_sky.request_full_sky_init()
	
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		atmosphere_tex.request_update()
		
