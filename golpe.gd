extends Node

enum Estado { LISTA, WINDUP, ACTIVE, RECOVERY }

@export var tecla = "golpe"
@export var animacion = "Golpe/mixamo_com"
@export var cuadros_windup = 24
@export var cuadros_active = 6
@export var cuadros_recovery = 36

@onready var pj = get_parent()
@onready var anim = pj.get_node("Modelo/AnimationPlayer")
@onready var hitbox = pj.get_node("Hitbox")

var estado = Estado.LISTA
var cuadros = 0
var esta_golpeando = false


func _physics_process(_delta):
	match estado:
		Estado.LISTA:
			if Input.is_action_just_pressed(tecla):
				cambiar_a(Estado.WINDUP)
		Estado.WINDUP:
			cuadros -= 1
			if cuadros <= 0:
				cambiar_a(Estado.ACTIVE)
		Estado.ACTIVE:
			cuadros -= 1
			if cuadros <= 0:
				cambiar_a(Estado.RECOVERY)
		Estado.RECOVERY:
			cuadros -= 1
			if cuadros <= 0:
				cambiar_a(Estado.LISTA)


func cambiar_a(nuevo):
	estado = nuevo
	match estado:
		Estado.WINDUP:
			cuadros = cuadros_windup
			esta_golpeando = true
			if anim.has_animation(animacion):
				ajustar_velocidad()
				pj.accion = animacion
			else:
				print("ojo: no existe la animación ", animacion)
		Estado.ACTIVE:
			cuadros = cuadros_active
			hitbox.encender()
		Estado.RECOVERY:
			cuadros = cuadros_recovery
			hitbox.apagar()
		Estado.LISTA:
			cuadros = 0
			esta_golpeando = false
			pj.accion = ""
			anim.speed_scale = 1.0
	print("golpe -> ", Estado.keys()[estado], " cuadro ", Engine.get_physics_frames())


func ajustar_velocidad():
	var pista = anim.get_animation(animacion)
	if pista == null:
		return
	var total = cuadros_windup + cuadros_active + cuadros_recovery
	anim.speed_scale = pista.length / (total / 60.0)
