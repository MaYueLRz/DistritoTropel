extends Node

enum Estado { JUGANDO, GANO, PERDIO }

# Entrega21 - sistema de rondas (mejor de 3). El HUD ya pide victorias_de(), ronda_actual()
# y rondas_para_ganar; la pantalla de la ronda y la de victoria están en pantalla_ronda.gd.
signal ronda_terminada(ganador, como)
signal combate_terminado(campeon)

@export var tiempo_limite = 60.0
@export var gana_con_tiempo = false
@export var metas = 2
@export var espera_reinicio = 2.0
@export var rondas_para_ganar = 2          # mejor de 3: gana quien llegue primero a 2
@export var reapariciones_por_ronda = 0    # 0: un KO cierra la ronda. -1 deja lo que tenga Salud

static var intentos = 1
static var mejor = 0.0
static var rondas_ganadas = 0
# Estas dos se guardan al recargar la escena, por eso son static.
static var victorias = [0, 0]              # rondas ganadas por el jugador 1 y el 2
static var ronda = 1
var ganador = 0
var como_termino = ""                      # "KO", "tiempo" o "empate"
var campeon = 0
var esperando_decision = false
var mensaje_ronda = ""
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
	print("ronda ", ronda, " · marcador ", victorias[0], " - ", victorias[1])
	call_deferred("preparar_combate")
	var pantalla = load("res://pantalla_ronda.gd").new()
	pantalla.partida = self
	add_child(pantalla)

func _physics_process(delta):
	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			if campeon == 0:
				reiniciar()
			elif not esperando_decision:
				esperando_decision = true
				print("combate terminado: campeón jugador ", campeon)
				combate_terminado.emit(campeon)
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
	cerrar_ronda()

func reiniciar():
	intentos += 1
	if ganador != 0:
		ronda += 1          # un empate se repite con el mismo número de ronda
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
	como_termino = "KO" if motivo == "KO" else "tiempo"
	mensaje_ronda = "GANA EL JUGADOR " + str(numero)
	terminar(Estado.GANO, mensaje_ronda + " por " + motivo)


# Si se acaba el tiempo, gana quien tenga más vida.
func decidir_por_vida():
	var v1 = vida_de("jugador1")
	var v2 = vida_de("jugador2")
	if v1 == v2:
		ganador = 0
		como_termino = "empate"
		mensaje_ronda = "EMPATE"
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


# ================= RONDAS =================
# Las llama el HUD (hud_juego.gd) para dibujar los rombitos y el cartel de ronda.
func victorias_de(lado):
	return victorias[lado - 1]


func ronda_actual():
	return ronda


# Suma el punto de la ronda y mira si alguien ya ganó el combate.
func cerrar_ronda():
	if ganador == 1 or ganador == 2:
		victorias[ganador - 1] += 1
		if victorias[ganador - 1] >= rondas_para_ganar:
			campeon = ganador
			mensaje_final = "GANA EL JUGADOR " + str(ganador)
	print("fin de la ronda ", ronda, " · ", como_termino, " · marcador ", victorias[0], " - ", victorias[1])
	ronda_terminada.emit(ganador, como_termino)


# Con rondas, cada KO cierra la ronda: Salud ya no reaparece a nadie.
func preparar_combate():
	if reapariciones_por_ronda < 0:
		return
	for grupo in ["jugador1", "jugador2"]:
		for pj in get_tree().get_nodes_in_group(grupo):
			var salud = pj.get_node_or_null("Salud")
			if salud != null:
				salud.reapariciones = reapariciones_por_ronda


# Borra el marcador y empieza otro combate desde la ronda 1.
static func nuevo_combate():
	victorias = [0, 0]
	ronda = 1


func revancha():
	nuevo_combate()
	intentos += 1
	get_tree().paused = false
	get_tree().reload_current_scene()
