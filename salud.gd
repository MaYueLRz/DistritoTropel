extends Node
# Taller 10 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 2: sin vida, la Salud le avisa a la Partida (se busca por grupo, al momento).

signal cambio(vida)
signal sin_vida

@export var vida = 3
@export var invulnerable = 1.0
var reloj = 0.0


func _ready():
	# La Salud se escucha a sí misma: así otros scripts también pueden oír sin_vida.
	sin_vida.connect(_al_quedar_sin_vida)


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


# Se busca aquí y no en _ready(): la Partida quizá todavía no existía.
func _al_quedar_sin_vida():
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.perder("sin vida")
