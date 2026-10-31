extends CharacterBody3D

@export var objetivo: Node3D

@onready var anim = $Modelo/AnimationPlayer

var reloj = 0.0


func _ready():
	print("objetivo: ", objetivo)
	anim.play("idle")


func _physics_process(delta):
	velocity += get_gravity() * delta
	move_and_slide()

	reloj += delta
	if reloj >= 0.5:
		reloj = 0.0
		var hacia = objetivo.global_position - global_position
		hacia.y = 0.0
		print("distancia ", snappedf(hacia.length(), 0.01))
