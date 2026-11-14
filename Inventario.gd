extends Node


signal cambio(items)

const MAXIMO = 2

@export var tecla_1 = "usar_1"
@export var tecla_2 = "usar_2"

@onready var pj = get_parent()
@onready var salud = pj.get_node_or_null("Salud")

var items = []


func _physics_process(_delta):
	if Input.is_action_just_pressed(tecla_1):
		usar(0)
	if Input.is_action_just_pressed(tecla_2):
		usar(1)


func guardar(tipo):
	if items.size() >= MAXIMO:
		return false
	items.append(tipo)
	print("recoge ", tipo, " · inventario ", items)
	cambio.emit(items)
	return true


func usar(ranura):
	if ranura >= items.size():
		print("ranura ", ranura + 1, " vacía")
		return
	var tipo = items[ranura]
	items.remove_at(ranura)
	aplicar(tipo)
	print("usa ", tipo, " · inventario ", items)
	cambio.emit(items)


func aplicar(tipo):
	match tipo:
		"refajo":
			if salud == null:
				return
			salud.vida_inicial = maxi(salud.vida_inicial, salud.vida) + 20
			salud.vida += 20
			salud.cambio.emit(salud.vida)
			print("  +20 de vida máxima · ahora ", salud.vida, "/", salud.vida_inicial)
		"yox":
			pj.ataque = int(pj.ataque * 1.15)
			print("  +15 % de daño · ahora ", pj.ataque)
		"mieltertos":
			if salud == null:
				return
			var tope = maxi(salud.vida_inicial, salud.vida)
			salud.vida = mini(salud.vida + 25, tope)
			salud.cambio.emit(salud.vida)
			print("  +25 de vida · ahora ", salud.vida, "/", tope)
		"empanada":
			pj.multiplicador *= 1.2
			print("  +20 % de velocidad · ahora x", pj.multiplicador)
