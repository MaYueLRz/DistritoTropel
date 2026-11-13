extends Node

const MAXIMO = 2

@export var tecla_1 = "usar_1"
@export var tecla_2 = "usar_2"

@onready var pj = get_parent()

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
	return true


func usar(ranura):
	if ranura >= items.size():
		print("ranura ", ranura + 1, " vacía")
		return
	var tipo = items[ranura]
	items.remove_at(ranura)
	aplicar(tipo)
	print("usa ", tipo, " · inventario ", items)


func aplicar(tipo):
	match tipo:
		"refajo":
			pj.vida_max += 20
			pj.vida += 20
			print("  +20 de vida máxima · ahora ", pj.vida, "/", pj.vida_max)
		"yox":
			pj.ataque = int(pj.ataque * 1.15)
			print("  +15 % de daño · ahora ", pj.ataque)
		"mieltertos":
			pj.vida = mini(pj.vida + 25, pj.vida_max)
			print("  +25 de vida · ahora ", pj.vida, "/", pj.vida_max)
		"empanada":
			pj.velocidad *= 1.2
			print("  +20 % de velocidad · ahora ", pj.velocidad)
