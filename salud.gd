extends Node
# Taller 10 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 1: la Salud avisa con una señal cuando la vida cambia.

signal cambio(vida)
signal sin_vida

@export var vida = 3
@export var invulnerable = 1.0
var reloj = 0.0


func _physics_process(delta):
	reloj = maxf(reloj - delta, 0.0)


func recibir_golpe(danio):
	if reloj > 0.001:
		print("invulnerable: no cuenta")
		return
	if vida == 0:
		return
	vida = maxi(vida - danio, 0)
	reloj = invulnerable
	print("vida del jugador: ", vida)
	cambio.emit(vida)
	if vida == 0:
		print("el jugador perdió")
		sin_vida.emit()
