extends Node

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 60.0
@export var gana_con_tiempo = false
@export var metas = 2
@export var espera_reinicio = 2.0

static var intentos = 1
static var mejor = 0.0
static var rondas_ganadas = 0
var ganador = 0
var mensaje_final = ""

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0
var reloj = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite
	print("intento ", intentos, " · mejor tiempo ", snappedf(mejor, 0.01))

func _physics_process(delta):
	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			reiniciar()
		return

	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		decidir_por_vida()
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
	print("fin: ", Estado.keys()[estado], " cuadro ", Engine.get_physics_frames(), " (", motivo, ")")
	get_tree().paused = true
	reloj = espera_reinicio
	
	var usado = tiempo_limite - tiempo
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado

func reiniciar():
	intentos += 1
	get_tree().paused = false
	get_tree().reload_current_scene()
	
# La llama salud.gd cuando a alguien se le acaban las vidas.
func cayo(quien):
	if estado != Estado.JUGANDO:
		return
	if quien != null and quien.is_in_group("jugador1"):
		declarar(2, "KO")
	else:
		declarar(1, "KO")


func declarar(numero, motivo):
	ganador = numero
	mensaje_final = "GANA EL JUGADOR " + str(numero)
	terminar(Estado.GANO, mensaje_final + " por " + motivo)


# Si se acaba el tiempo, gana quien tenga más vida.
func decidir_por_vida():
	var v1 = vida_de("jugador1")
	var v2 = vida_de("jugador2")
	if v1 == v2:
		ganador = 0
		mensaje_final = "EMPATE"
		terminar(Estado.PERDIO, "empate por tiempo")
	elif v1 > v2:
		declarar(1, "tiempo")
	else:
		declarar(2, "tiempo")


func vida_de(grupo):
	var pj = get_tree().get_first_node_in_group(grupo)
	if pj == null:
		return 0
	var s = pj.get_node_or_null("Salud")
	if s == null:
		return 0
	return s.vida
