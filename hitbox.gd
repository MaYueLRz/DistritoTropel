extends Area3D

@onready var pj = get_parent()
@onready var forma = $CollisionShape3D

var activa = false
var ya_golpeo = false
var empuje = 0.0
var datos = {}
var efecto: PackedScene = null

func _ready():
	if forma.shape != null:
		forma.shape = forma.shape.duplicate()
	apagar()


func encender(fuerza_empuje = 0.0):
	activa = true
	ya_golpeo = false
	empuje = fuerza_empuje
	set_deferred("monitoring", true)
	forma.set_deferred("disabled", false)


func apagar():
	activa = false
	set_deferred("monitoring", false)
	forma.set_deferred("disabled", true)


func configurar(alcance, altura, radio):
	position = Vector3(0.0, altura, -alcance)
	if forma.shape is SphereShape3D:
		forma.shape.radius = radio


func _physics_process(_delta):
	if not activa or ya_golpeo:
		return
	if not monitoring:
		return
	for otra in get_overlapping_areas():
		if otra.is_in_group("hurtbox"):
			if otra.get_parent() == pj:
				continue
			ya_golpeo = true
			var victima = otra.get_parent()
			if victima.has_method("recibir_golpe"):
				var info = datos.duplicate()
				info["danio"] = int(pj.ataque * datos.get("fuerza", 1.0))
				info["empuje"] = empuje
				info["desde"] = pj.global_position
				info["punto"] = global_position
				if efecto != null:
					var fx = efecto.instantiate()
					get_tree().current_scene.add_child(fx)
					fx.global_position = global_position
					fx.finished.connect(fx.queue_free)
					fx.play()
				victima.recibir_golpe(info)
				hitstop(0.05)
			elif victima.has_method("recibir_danio"):
				victima.recibir_danio(int(pj.ataque * datos.get("fuerza", 1.0)))
				empujar(victima)
				hitstop(0.05)
			return

func empujar(victima):
	if empuje <= 0.0:
		return
	var lejos = victima.global_position - pj.global_position
	lejos.y = 0.0
	if lejos.length() < 0.01:
		return
	var f = lejos.normalized() * empuje
	if victima.has_method("recibir_empuje"):
		victima.recibir_empuje(f)
	elif victima is CharacterBody3D:
		victima.velocity += f


func hitstop(segundos):
	Engine.time_scale = 0.0
	await get_tree().create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0
