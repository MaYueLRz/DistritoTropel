extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla = "rodar"
@export var duracion = 0.3
@export var recarga = 1.2
@onready var pj = get_parent()

var estado = Estado.LISTA
<<<<<<< Updated upstream
var tiempo = 0.0
=======
var cuadros = 0
var esta_golpeando=false
>>>>>>> Stashed changes


func _physics_process(delta):
	tiempo -= delta
	match estado:
		Estado.LISTA:
			
			if Input.is_action_just_pressed(tecla):
<<<<<<< Updated upstream
				empezar()
		Estado.ACTIVA:
			if tiempo <= 0.001:  # 0.001 y no 0: restar 1/60 no da exacto
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTA


func empezar():
	estado = Estado.ACTIVA
	tiempo = duracion
	print("empieza: ", tecla)


func terminar():
	estado = Estado.RECARGA
	tiempo = recarga
	print("termina: ", tecla)
=======
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
			pj.accion = "Golpe/mixamo_com" 
			esta_golpeando = true
		Estado.ACTIVE:
			cuadros = cuadros_active
		Estado.RECOVERY:
			cuadros = cuadros_recovery
		Estado.LISTA:
			cuadros = 0
			pj.accion = "" 
			esta_golpeando = false
	print("golpe -> ", Estado.keys()[estado], " cuadro ", Engine.get_physics_frames())
>>>>>>> Stashed changes
