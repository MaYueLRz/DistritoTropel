extends CharacterBody3D

enum Estado { PATRULLA, PERSEGUIR }

@export var objetivo: Node3D
@export var rapidez = 2.5
@export var distancia_golpe = 1.2
@export var radio_ver = 7.0
@export var radio_perder = 11.0     # siempre más grande que radio_ver
@export var puntos: Array[Vector3] = [
	Vector3(-10, 0, -10), Vector3(10, 0, -10),
	Vector3(10, 0, 10), Vector3(-10, 0, 10)
]

@onready var anim = $Modelo/AnimationPlayer

var estado = Estado.PATRULLA
var punto = 0


func _physics_process(delta):
	velocity += get_gravity() * delta

	var hacia_objetivo = objetivo.global_position - global_position
	hacia_objetivo.y = 0.0
	var distancia = hacia_objetivo.length()

	match estado:
		Estado.PATRULLA:
			if distancia < radio_ver:
				estado = Estado.PERSEGUIR
				print("lo vio a ", snappedf(distancia, 0.01), " m")
			ir_a(puntos[punto])
			if global_position.distance_to(puntos[punto]) < 0.3:
				punto = (punto + 1) % puntos.size()
		Estado.PERSEGUIR:
			if distancia > radio_perder:
				estado = Estado.PATRULLA
				print("lo perdió a ", snappedf(distancia, 0.01), " m")
			ir_a(objetivo.global_position, distancia_golpe)

	move_and_slide()


func ir_a(p, parar_a = 0.05):
	var hacia = p - global_position
	hacia.y = 0.0
	if hacia.length() <= parar_a:
		velocity.x = 0.0
		velocity.z = 0.0
		anim.play("idle")
		return
	var dir = hacia.normalized()
	velocity.x = dir.x * rapidez
	velocity.z = dir.z * rapidez
	look_at(global_position + dir, Vector3.UP)
	anim.play("walk")
