extends Node

enum Estado { LISTA, WINDUP, ACTIVE, RECOVERY }

@export var tecla = "golpe"
@export var cuadros_windup = 24
@export var cuadros_active = 6
@export var cuadros_recovery = 36

@onready var pj = get_parent()

var estado = Estado.LISTA
var cuadros = 0


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
		Estado.ACTIVE:
			cuadros = cuadros_active
		Estado.RECOVERY:
			cuadros = cuadros_recovery
		Estado.LISTA:
			cuadros = 0
	print("golpe -> ", Estado.keys()[estado], " cuadro ", Engine.get_physics_frames())
