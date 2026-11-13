class_name Character
extends CharacterBody3D

@export var velocidad = 3.0
@export var vida_max = 200
@export var vida = 200
@export var defensa = 0
@export var ataque = 8

signal vida_cambio(nueva)
signal murio


func recibir_danio(cantidad):
	var real = maxi(cantidad - defensa, 1)
	vida = maxi(vida - real, 0)
	print(name, " recibe ", real, " · vida ", vida)
	vida_cambio.emit(vida)
	if vida <= 0:
		morir()


func morir():
	print(name, " murió")
	murio.emit()
	set_physics_process(false)
