extends Area3D

@onready var pj = get_parent()

var activa = false
var ya_golpeo = false
var empuje = 0.0


func _physics_process(_delta):
	if not activa or ya_golpeo:
		return
	for otra in get_overlapping_areas():
		if otra.is_in_group("hurtbox"):
			if otra.get_parent() == pj:
				continue
			ya_golpeo = true
			var victima = otra.get_parent()
			if victima.has_method("recibir_danio"):
				victima.recibir_danio(pj.ataque)
				empujar(victima)
				hitstop(0.05)
			return


func empujar(victima):
	if empuje <= 0.0:
		return
	if not (victima is CharacterBody3D):
		return
	var lejos = victima.global_position - pj.global_position
	lejos.y = 0.0
	if lejos.length() < 0.01:
		return
	victima.velocity += lejos.normalized() * empuje
	print("empujón de ", empuje)


func encender(fuerza = 0.0):
	activa = true
	ya_golpeo = false
	empuje = fuerza
	print("hitbox ON cuadro ", Engine.get_physics_frames())


func apagar():
	activa = false
	print("hitbox OFF cuadro ", Engine.get_physics_frames())


func hitstop(segundos):
	Engine.time_scale = 0.0
	await get_tree().create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0
