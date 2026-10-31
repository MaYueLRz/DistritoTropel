extends CharacterBody3D

@export var objetivo: Node3D
@export var rapidez = 2.0            # tus números: 2.5
@export var distancia_parada = 1.0   # tus números: 1.2

@onready var anim = $Modelo/AnimationPlayer

var reloj = 0.0


func _physics_process(delta):
	velocity += get_gravity() * delta

	var hacia = objetivo.global_position - global_position
	hacia.y = 0.0
	var distancia = hacia.length()

	if distancia > distancia_parada:
		var dir = hacia.normalized()
		velocity.x = dir.x * rapidez
		velocity.z = dir.z * rapidez
		anim.play("walk")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		anim.play("idle")

	if distancia > 0.05:
		look_at(global_position + hacia, Vector3.UP)

	move_and_slide()

	reloj += delta
	if reloj >= 0.5:
		reloj = 0.0
		print("distancia ", snappedf(distancia, 0.01))
