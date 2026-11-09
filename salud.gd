extends Node
# Taller 10 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 3: reaparecer antes de perder (3 vidas = vida inicial + 2 reapariciones).

signal cambio(vida)
signal sin_vida

@export var vida = 3
@export var invulnerable = 1.0
@export var reapariciones = 2          # "3 vidas" del documento
@export var espera_reaparecer = 2.0    # protección al reaparecer (segundos)
var reloj = 0.0
var vida_inicial = 0
var punto = Vector3.ZERO
@onready var pj = get_parent()


func _ready():
	sin_vida.connect(_al_quedar_sin_vida)
	# Se guardan aquí, cuando todavía nada ha cambiado.
	vida_inicial = vida
	punto = pj.global_position


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


func _al_quedar_sin_vida():
	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_inicial
		pj.global_position = punto
		reloj = espera_reaparecer
		cambio.emit(vida)
		print("reaparece cuadro ", Engine.get_physics_frames())
		return
	# Sin reapariciones: ahora sí pierde (igual que el nivel anterior).
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		partida.perder("sin vida")
