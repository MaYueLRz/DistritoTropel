extends Node
# SOLO PARA PROBAR: copia del nivel 2 de la Partida (receta P, Tarea A), sin las líneas de Enter.
# Es mi copia de prueba hasta que Gaona suba su partida.gd. Solo la usa prueba_nicolas.tscn.

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 60.0
@export var gana_con_tiempo = false
@export var metas = 0

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite


func _physics_process(delta):
	if estado != Estado.JUGANDO:
		return
	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		if gana_con_tiempo:
			ganar()
		else:
			perder("se acabó el tiempo")


func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	if metas > 0 and hechas >= metas:
		ganar()


func ganar():
	terminar(Estado.GANO, "ganó")


func perder(motivo):
	terminar(Estado.PERDIO, motivo)


func terminar(nuevo, motivo):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ")")
	get_tree().paused = true
