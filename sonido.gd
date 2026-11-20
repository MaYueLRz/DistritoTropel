extends Node


# Volúmenes en dB (0 es el máximo, bajar es negativo).
@export var volumen_musica = -15.0      # la música de la pelea va de fondo
@export var volumen_intro = -9.0        # la de la cuenta atrás se oye más
@export var volumen_ambiente = -17.0
@export var volumen_sfx = 0.0
@export var carpeta = "res://sonidos/"
@export var avisar = false              # true imprime cada sonido en la Salida

# Cada sonido tiene variantes: el juego escoge una al azar y le cambia un poco el tono.
const VARIANTES = {
	"swing": ["golpe_a", "golpe_b"],
	"swing_fuerte": ["patada"],
	"impacto": ["impacto_a", "impacto_b"],
	"impacto_fuerte": ["impacto_fuerte"],
	"dano": ["dano_a", "dano_b", "dano_c"],
	"paso": ["paso_a", "paso_b", "paso_c"],
	"ko": ["ko"],
	"tick": ["tick"],
	"pelea": ["pelea"],
	"victoria": ["victoria"],
	"derrota": ["derrota"],
	"recoger": ["recoger"],
	"usar": ["usar"],
	"ui_hover": ["ui_hover"],
	"ui_click": ["ui_click"],
}
const CAMBIO_TONO = {
	"swing": 0.10, "swing_fuerte": 0.06, "impacto": 0.08, "impacto_fuerte": 0.05,
	"dano": 0.05, "paso": 0.12,
}

# Mismos números que personaje.gd (enum Estado) y golpe.gd (enum Estado).
const CAMINAR = 1
const CORRER = 2
const GOLPE_ACTIVE = 2
const PASO_CAMINAR = 0.50
const PASO_CORRER = 0.30

var sonidos = {}
var musica = null
var intro = null
var ambiente = null
var voces_ui = []
var turno_ui = 0
var turno_3d = 0
var reproductores = {}

var jugadores = []
var estado_golpe = {}
var reloj_paso = {}
var vidas = {}
var cuantos_items = {}
var cuenta = null
var cuenta_anterior = 0
var partida = null
var termino = false
var pausa_antes = false
var sin_ui_hasta = 0
var bus_musica = -1


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS    # sigue sonando con el menú de pausa
	crear_buses()
	cargar_sonidos()
	crear_voces()
	call_deferred("conectar")


func _physics_process(delta):
	var pausado = get_tree().paused
	if pausado != pausa_antes:
		pausa_antes = pausado
		cambio_de_pausa(pausado)
	vigilar_partida()
	if pausado:
		return
	vigilar_cuenta()
	for pj in jugadores:
		vigilar_golpe(pj)
		vigilar_pasos(pj, delta)


# ---------------------------------------------------------------- preparación

func crear_buses():
	for nombre in ["Musica", "SFX", "Ambiente"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nombre)
			AudioServer.set_bus_send(i, "Master")
	bus_musica = AudioServer.get_bus_index("Musica")
	if AudioServer.get_bus_effect_count(bus_musica) == 0:
		var filtro = AudioEffectLowPassFilter.new()
		filtro.cutoff_hz = 900.0
		AudioServer.add_bus_effect(bus_musica, filtro)
	AudioServer.set_bus_effect_enabled(bus_musica, 0, false)
	AudioServer.set_bus_volume_db(bus_musica, volumen_musica)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambiente"), volumen_ambiente)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volumen_sfx)


func cargar(nombre):
	var ruta = carpeta + nombre + ".wav"
	if ResourceLoader.exists(ruta):
		return load(ruta)
	print("sonido: falta ", ruta)
	return null


func cargar_sonidos():
	for clave in VARIANTES:
		var mezcla = AudioStreamRandomizer.new()
		mezcla.random_pitch = 1.0 + CAMBIO_TONO.get(clave, 0.0)
		mezcla.random_volume_offset_db = 1.5
		var hay = false
		for nombre in VARIANTES[clave]:
			var flujo = cargar(nombre)
			if flujo != null:
				mezcla.add_stream(-1, flujo, 1.0)
				hay = true
		if hay:
			sonidos[clave] = mezcla


func con_bucle(flujo):
	if flujo is AudioStreamWAV:
		flujo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		flujo.loop_begin = 0
		flujo.loop_end = int(round(flujo.get_length() * flujo.mix_rate))
	return flujo


func crear_voces():
	ambiente = nuevo_reproductor("Ambiente")
	musica = nuevo_reproductor("Musica")
	intro = nuevo_reproductor("Musica")
	for i in 3:
		voces_ui.append(nuevo_reproductor("SFX"))
	var flujo = cargar("ambiente")
	if flujo != null:
		ambiente.stream = con_bucle(flujo)
		ambiente.play()


func nuevo_reproductor(bus):
	var p = AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


# ------------------------------------------------------------------ conexiones

func conectar():
	var main = get_parent()
	for grupo in ["jugador1", "jugador2"]:
		for nodo in get_tree().get_nodes_in_group(grupo):
			if not nodo in jugadores:
				jugadores.append(nodo)

	for pj in jugadores:
		estado_golpe[pj] = 0
		reloj_paso[pj] = 0.0
		var salud = pj.get_node_or_null("Salud")
		if salud != null:
			vidas[salud] = salud.vida
			salud.cambio.connect(_al_cambiar_salud.bind(salud, pj))
			salud.sin_vida.connect(_al_caer.bind(pj))
		var inv = pj.get_node_or_null("Inventario")
		if inv != null:
			cuantos_items[inv] = inv.items.size()
			inv.cambio.connect(_al_cambiar_inventario.bind(inv, pj))

	for enemigo in get_tree().get_nodes_in_group("enemigo"):
		if enemigo.has_signal("vida_cambio"):
			vidas[enemigo] = enemigo.vida
			enemigo.vida_cambio.connect(_al_cambiar_vida.bind(enemigo))
			enemigo.murio.connect(_al_caer.bind(enemigo))

	partida = get_tree().get_first_node_in_group("partida")

	var caja = main.get_node_or_null("MenuPausa/Fondo/Centro/Letrero/VBox")
	if caja != null:
		for boton in caja.get_children():
			if boton is Button:
				boton.focus_entered.connect(_al_apuntar_boton)
				boton.pressed.connect(_al_pulsar_boton)

	cuenta = main.get_node_or_null("CuentaAtras")
	if cuenta != null:
		cuenta.pelea_empezo.connect(_al_empezar)
		var flujo = cargar("musica_intro")
		if flujo != null:
			intro.stream = flujo
			intro.volume_db = volumen_intro - volumen_musica
			intro.play()
	else:
		_al_empezar()


func _al_empezar():
	if sonidos.has("pelea") and cuenta != null:
		sonar_ui("pelea")
	if intro.playing:
		var t = create_tween()
		t.tween_property(intro, "volume_db", -40.0, 0.6)
		t.tween_callback(intro.stop)
	var flujo = cargar("musica_pelea")
	if flujo != null:
		musica.stream = con_bucle(flujo)
		musica.volume_db = -40.0
		musica.play()
		create_tween().tween_property(musica, "volume_db", 0.0, 1.5)
	if avisar:
		print("sonido: empieza la música de la pelea")


# ----------------------------------------------------------------- vigilantes

func vigilar_cuenta():
	if cuenta == null or not is_instance_valid(cuenta):
		return
	if cuenta.contando and cuenta.restante != cuenta_anterior:
		cuenta_anterior = cuenta.restante
		var tono = 1.0 + 0.12 * (cuenta.numeros - cuenta.restante)
		sonar_ui("tick", tono)


func vigilar_golpe(pj):
	var golpe = pj.get_node_or_null("Golpe")
	if golpe == null:
		return
	var ahora = golpe.estado
	if ahora != estado_golpe[pj]:
		estado_golpe[pj] = ahora
		if ahora == GOLPE_ACTIVE:
			sonar_en(pj, "swing_fuerte" if golpe.paso == 2 else "swing", 1.0, -3.0)


func vigilar_pasos(pj, delta):
	var camina = pj.estado == CAMINAR or pj.estado == CORRER
	if camina and pj.is_on_floor():
		reloj_paso[pj] -= delta
		if reloj_paso[pj] <= 0.0:
			var corre = pj.estado == CORRER
			sonar_en(pj, "paso", 1.15 if corre else 1.0, -7.0)
			reloj_paso[pj] = PASO_CORRER if corre else PASO_CAMINAR
	else:
		reloj_paso[pj] = 0.0     # el primer paso suena apenas empieza a caminar


func vigilar_partida():
	if partida == null or termino:
		return
	if partida.estado != 0:
		termino = true
		if musica.playing:
			var t = create_tween()
			t.tween_property(musica, "volume_db", -40.0, 1.0)
			t.tween_callback(musica.stop)
		sonar_ui("victoria" if partida.ganador != 0 else "derrota")


func cambio_de_pausa(pausado):
	AudioServer.set_bus_effect_enabled(bus_musica, 0, pausado)
	AudioServer.set_bus_volume_db(bus_musica, volumen_musica - (4.0 if pausado else 0.0))
	sin_ui_hasta = Time.get_ticks_msec() + 250     # el menú toma el foco solo al abrirse
	if avisar:
		print("sonido: pausa ", pausado)


# -------------------------------------------------------------------- señales

func _al_cambiar_salud(vida, salud, pj):
	var antes = vidas.get(salud, vida)
	vidas[salud] = vida
	if vida < antes:
		doler(pj)


func _al_cambiar_vida(vida, enemigo):
	var antes = vidas.get(enemigo, vida)
	vidas[enemigo] = vida
	if vida < antes:
		doler(enemigo)


func doler(quien):
	var fuerte = golpe_fuerte_activo()
	sonar_en(quien, "impacto_fuerte" if fuerte else "impacto")
	sonar_en(quien, "dano", 1.0, 0.0)


# El golpe 3 (la patada) es el fuerte. Cuando pega, el que la lanza está en ACTIVE.
func golpe_fuerte_activo():
	for pj in jugadores:
		var golpe = pj.get_node_or_null("Golpe")
		if golpe != null and golpe.estado == GOLPE_ACTIVE and golpe.paso == 2:
			return true
	return false


func _al_caer(quien):
	sonar_en(quien, "ko")


func _al_cambiar_inventario(items, inv, pj):
	var antes = cuantos_items.get(inv, 0)
	cuantos_items[inv] = items.size()
	sonar_en(pj, "recoger" if items.size() > antes else "usar", 1.0, -2.0)


func _al_apuntar_boton():
	if Time.get_ticks_msec() > sin_ui_hasta:
		sonar_ui("ui_hover", 1.0, -8.0)


func _al_pulsar_boton():
	sonar_ui("ui_click")


# ------------------------------------------------------------------ reproducir

# Suena en el personaje o enemigo que lo causa, así se oye de su lado en la pantalla.
func sonar_en(nodo, clave, tono = 1.0, db = 0.0):
	if not sonidos.has(clave) or not is_instance_valid(nodo):
		return
	var lista = voces_de(nodo)
	var voz = lista[turno_3d % lista.size()]
	turno_3d += 1
	voz.stream = sonidos[clave]
	voz.pitch_scale = tono
	voz.volume_db = db
	voz.play()
	if avisar:
		print("sonido ", clave, " en ", nodo.name, " cuadro ", Engine.get_physics_frames())


func voces_de(nodo):
	var id = nodo.get_instance_id()
	if not reproductores.has(id):
		var lista = []
		for i in 4:
			var voz = AudioStreamPlayer3D.new()
			voz.bus = "SFX"
			voz.unit_size = 30.0
			voz.max_distance = 80.0
			nodo.add_child(voz)
			lista.append(voz)
		reproductores[id] = lista
	return reproductores[id]


func sonar_ui(clave, tono = 1.0, db = 0.0):
	if not sonidos.has(clave):
		return
	var voz = voces_ui[turno_ui % voces_ui.size()]
	turno_ui += 1
	voz.stream = sonidos[clave]
	voz.pitch_scale = tono
	voz.volume_db = db
	voz.play()
	if avisar:
		print("sonido ", clave, " cuadro ", Engine.get_physics_frames())
