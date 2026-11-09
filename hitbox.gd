extends Area3D

@export var danio = 8

var activa = false
var ya_golpeo = false


func _physics_process(_delta):
	if not activa or ya_golpeo:
		return
	for otra in get_overlapping_areas():
		if otra.is_in_group("hurtbox"):
			ya_golpeo = true
			var victima = otra.get_parent()
			if victima.has_method("recibir_danio"):
				victima.recibir_danio(danio)
			return


func encender():
	activa = true
	ya_golpeo = false
	print("hitbox ON cuadro ", Engine.get_physics_frames())


func apagar():
	activa = false
	print("hitbox OFF cuadro ", Engine.get_physics_frames())
