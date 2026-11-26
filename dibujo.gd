extends Control
@export var mostrar_controles = true
@export var margen_lado = 35.0
@export var margen_inferior = 125.0
@export var tam_letra_controles = 13
@export var alto_linea = 17.0

const CONTROLES_P1 = [
	["MOVER", "W A S D"],
	["GOLPEAR", "X"],
	["BLOQUEAR", "C"],
	["CORRER", "V"],
	["OBJETO 1", "R"],
	["OBJETO 2", "T"],
]

const CONTROLES_P2 = [
	["MOVER", "FLECHAS"],
	["GOLPEAR", "K"],
	["BLOQUEAR", "Ñ"],
	["CORRER", "L"],
	["OBJETO 1", "O"],
	["OBJETO 2", "P"],
]

# ================= COLORES =================
const VERDE = Color("01fd99")
const AMARILLO = Color("f9da17")
const ROJO = Color("ca2a2f")
const ROJO_TM = Color("B8322F")             # rojo TransMilenio
const CHASIS = Color(0.08, 0.08, 0.09, 0.8) # fondo oscuro semitransparente
const CREMA = Color("F2E6C9")
const AZUL = Color("3DA5F5")
const NARANJA = Color("FF6B1A")
const BORDE = Color(0.95, 0.95, 0.95)
const APAGADO = Color(0.38, 0.38, 0.40)
const ENERGIA_MAX = 100.0

const COLOR_ITEM = {
	"refajo": Color("f9da17"),
	"yox": Color("ff7a00"),
	"mieltertos": Color("01fd99"),
	"empanada": Color("d08a3a"),
}

# ================= SE AJUSTA EN EL INSPECTOR =================
@export var fuente_hud: Font
@export var carpeta_iconos = "res://ui/items/"   # aquí van refajo.png, yox.png, etc.
@export var margen = Vector2(22, 16)     # distancia a los bordes de la pantalla
@export var largo_vida = 380.0
@export var alto_vida = 22.0
@export var sesgo = 14.0                 # qué tan inclinadas son las barras
@export var largo_energia = 240.0
@export var alto_energia = 8.0
@export var radio_retrato = 28.0
@export var lado_ranura = 52.0
@export var color_p1 = Color("FFC72C")
@export var color_p2 = Color("3DD6F5")

# ================= VARIABLES =================
var jugador1 = null
var jugador2 = null
var salud = null
var salud2 = null
var inv = null
var inv2 = null
var partida = null
var activo = false
var iconos = {}       # se cargan una sola vez y se guardan aquí

# Lo que se muestra de cada lado (va persiguiendo a los valores reales)
var lados = {
	1: {"primera": true, "suave": 0.0, "rastro": 0.0, "espera": 0.0, "ultima": 0.0, "energia": 0.0},
	2: {"primera": true, "suave": 0.0, "rastro": 0.0, "espera": 0.0, "ultima": 0.0, "energia": 0.0},
}

@onready var fuente = ThemeDB.fallback_font


# ================= ARRANQUE =================
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Protección contra HUD duplicados: si este no tiene fuente, es el de sobra
	if fuente_hud == null:
		visible = false
		set_process(false)
		print("HUD duplicado apagado: ", get_path())
		return
	fuente = fuente_hud
	activo = true

	jugador1 = get_tree().get_first_node_in_group("jugador1")
	if jugador1 != null:
		salud = jugador1.get_node_or_null("Salud")
		inv = jugador1.get_node_or_null("Inventario")
	else:
		print("HUD: no encontré al jugador 1")

	jugador2 = get_tree().get_first_node_in_group("jugador2")
	if jugador2 != null:
		salud2 = jugador2.get_node_or_null("Salud")
		inv2 = jugador2.get_node_or_null("Inventario")
	else:
		print("HUD: no encontré al jugador 2")

	await get_tree().process_frame
	partida = get_tree().get_first_node_in_group("partida")


# ================= CADA CUADRO: animar los valores =================
func _process(delta):
	for lado in [1, 2]:
		var sal = salud if lado == 1 else salud2
		if sal == null:
			continue
		var d = lados[lado]
		var v = float(sal.vida)
		if d.primera:
			d.suave = v
			d.rastro = v
			d.ultima = v
			d.primera = false

		# Si la vida bajó, la estela blanca espera un momento antes de bajar
		if v < d.ultima:
			d.espera = 0.45
		d.ultima = v

		d.suave = lerpf(d.suave, v, minf(1.0, 18.0 * delta))
		if d.rastro > v:
			d.espera -= delta
			if d.espera <= 0.0:
				d.rastro = move_toward(d.rastro, v, maxf(sal.vida_inicial, 1) * 0.6 * delta)
		else:
			d.rastro = v

		var pj = jugador1 if lado == 1 else jugador2
		var e = 0.0
		if pj != null and pj.get("emputez") != null:
			e = float(pj.emputez)
		d.energia = lerpf(d.energia, e, minf(1.0, 10.0 * delta))
	queue_redraw()


func _draw():
	if not activo:
		return
	dibujar_lado(1)
	dibujar_lado(2)
	dibujar_reloj()
	dibujar_controles()
	dibujar_ranuras()
	dibujar_resultado()


# ================= VIDA, ENERGÍA, NOMBRE Y RONDAS =================
func dibujar_lado(lado):
	var izq = lado == 1
	var W = get_viewport_rect().size.x
	var d = lados[lado]
	var sal = salud if izq else salud2
	var maxima = float(maxi(sal.vida_inicial, 1)) if sal else 1.0
	var vida = int(sal.vida) if sal else 0
	var acento = color_p1 if izq else color_p2
	var r = radio_retrato

	# --- Retrato (circulito con P1 / P2) ---
	var c = Vector2(margen.x + r, margen.y + r + 4) if izq else Vector2(W - margen.x - r, margen.y + r + 4)
	draw_circle(c, r + 4, Color.BLACK)
	draw_circle(c, r, CHASIS)
	draw_arc(c, r + 1, 0, TAU, 48, acento, 3.0, true)
	texto(c + Vector2(-r, 8), "P" + str(lado), 22, acento, HORIZONTAL_ALIGNMENT_CENTER, r * 2)

	# --- Barra de vida ---
	var y = margen.y + 24
	var x = c.x + r + 12 if izq else c.x - r - 12 - largo_vida
	draw_colored_polygon(forma(x - 3, y - 3, largo_vida + 6, alto_vida + 6, izq), Color.BLACK)
	draw_colored_polygon(forma(x, y, largo_vida, alto_vida, izq), CHASIS)
	var f_rastro = clampf(d.rastro / maxima, 0.0, 1.0)
	var f = clampf(d.suave / maxima, 0.0, 1.0)
	tramo(x, y, largo_vida, alto_vida, f_rastro, Color(1, 1, 1, 0.85), izq)   # estela blanca
	tramo(x, y, largo_vida, alto_vida, f, color_vida(f), izq)                # vida
	tramo(x, y + 2, largo_vida, 4, f, Color(1, 1, 1, 0.25), izq)              # brillo

	# --- Número de vida ADENTRO de la barra ---
	var numeros = "%d/%d" % [vida, int(maxima)]
	var yt = y + alto_vida - 5
	if izq:
		texto(Vector2(x + sesgo + 8, yt), numeros, 15, Color.WHITE)
	else:
		texto(Vector2(x, yt), numeros, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, largo_vida - sesgo - 8)

	# --- Rayas de peligro al final de la barra ---
	for i in 3:
		var xr = (x + largo_vida + 8 + i * 9) if izq else (x - 14 - i * 9)
		draw_colored_polygon(forma(xr, y, 6, alto_vida, izq, 6),
			AMARILLO if i % 2 == 0 else Color.BLACK)

	# --- Nombre encima de la barra ---
	var yn = y - 6
	var nombre = "JUGADOR " + str(lado)
	if izq:
		texto(Vector2(x + sesgo, yn), nombre, 16, CREMA)
	else:
		texto(Vector2(x, yn), nombre, 16, CREMA, HORIZONTAL_ALIGNMENT_RIGHT, largo_vida - sesgo)

	# --- Rombitos de rondas ganadas ---
	if partida != null and partida.has_method("victorias_de"):
		var n = 2
		if partida.get("rondas_para_ganar") != null:
			n = partida.rondas_para_ganar
		var ganadas = partida.victorias_de(lado)
		for i in n:
			var px = (x + largo_vida - 10 - i * 18) if izq else (x + 10 + i * 18)
			rombo(Vector2(px, yn - 6), 6, AMARILLO if i < ganadas else Color(0, 0, 0, 0.6))

	# --- Barra de energía (debajo) ---
	var y2 = y + alto_vida + 7
	var xe = x + 10 if izq else x + largo_vida - 10 - largo_energia
	draw_colored_polygon(forma(xe - 2, y2 - 2, largo_energia + 4, alto_energia + 4, izq, 6), Color.BLACK)
	draw_colored_polygon(forma(xe, y2, largo_energia, alto_energia, izq, 5), CHASIS)
	var fe = clampf(d.energia / ENERGIA_MAX, 0.0, 1.0)
	tramo(xe, y2, largo_energia, alto_energia, fe, NARANJA if fe >= 1.0 else AZUL, izq, 5)


func color_vida(fraccion):
	if fraccion > 0.5:
		return VERDE
	if fraccion > 0.2:
		return AMARILLO
	return ROJO


# ================= RELOJ Y RONDA (centro) =================
func dibujar_reloj():
	if partida == null:
		return
	var W = get_viewport_rect().size.x
	var w = 92.0
	var h = 54.0
	var x = (W - w) / 2.0
	var y = margen.y
	draw_colored_polygon(pieza(x - 3, y - 3, w + 6, h + 6, 12), Color.BLACK)
	draw_colored_polygon(pieza(x, y, w, h, 12), CHASIS)
	draw_rect(Rect2(x + 6, y + h - 5, w - 16, 3), AMARILLO)
	var seg = int(ceil(partida.tiempo))
	texto(Vector2(x, y + h - 12), str(seg), 40, ROJO if seg <= 10 else CREMA,
		HORIZONTAL_ALIGNMENT_CENTER, w)

	var ronda = partida.ronda_actual() if partida.has_method("ronda_actual") else 1
	var tw = 84.0
	var th = 20.0
	var tx = (W - tw) / 2.0
	var ty = y + h + 6
	draw_colored_polygon(pieza(tx - 2, ty - 2, tw + 4, th + 4, 8), Color.BLACK)
	draw_colored_polygon(pieza(tx, ty, tw, th, 8), ROJO_TM)
	texto(Vector2(tx, ty + th - 4), "RONDA " + str(ronda), 14, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, tw)


# ================= OBJETOS (esquinas de abajo) =================
func dibujar_ranuras():
	var vista = get_viewport_rect().size
	for lado in [1, 2]:
		var izq = lado == 1
		var el_inv = inv if izq else inv2
		var items = el_inv.items if el_inv != null else []
		var y = vista.y - lado_ranura - margen.y
		for i in 2:
			var x = (margen.x + i * (lado_ranura + 10)) if izq \
				else (vista.x - margen.x - lado_ranura - i * (lado_ranura + 10))
			draw_colored_polygon(forma(x - 3, y - 3, lado_ranura + 6, lado_ranura + 6, izq, 10), Color.BLACK)
			draw_colored_polygon(forma(x, y, lado_ranura, lado_ranura, izq, 10), CHASIS)
			var lleno = i < items.size()
			if lleno:
				var tipo = items[i]
				var tex = icono(tipo)
				if tex != null:
					# Con ícono: fondito del color del objeto y el dibujo encima
					var fondo = COLOR_ITEM.get(tipo, BORDE)
					fondo.a = 0.35
					draw_colored_polygon(forma(x + 4, y + 4, lado_ranura - 8, lado_ranura - 8, izq, 8), fondo)
					draw_texture_rect(tex, Rect2(x + 6, y + 6, lado_ranura - 12, lado_ranura - 12), false)
				else:
					# Sin ícono: como antes, color y nombre
					draw_colored_polygon(forma(x + 5, y + 5, lado_ranura - 10, lado_ranura - 10, izq, 8),
						COLOR_ITEM.get(tipo, BORDE))
					draw_string(fuente, Vector2(x + 4, y + lado_ranura - 9),
						str(tipo).substr(0, 5).to_upper(), HORIZONTAL_ALIGNMENT_CENTER,
						lado_ranura - 8, 11, Color.BLACK)
			texto(Vector2(x + (lado_ranura - 16 if izq else 6), y + 15),
				letra_de(el_inv, i), 13, Color.WHITE if lleno else APAGADO)


# uso de pngs para los consumibles
func icono(tipo):
	if iconos.has(tipo):
		return iconos[tipo]
	var ruta = carpeta_iconos + str(tipo) + ".png"
	var tex = load(ruta) if ResourceLoader.exists(ruta) else null
	iconos[tipo] = tex
	return tex


func letra_de(el_inv, i):
	var por_defecto = ["O", "P"][i]
	if el_inv == null:
		return por_defecto
	var accion = el_inv.get("tecla_1" if i == 0 else "tecla_2")
	if accion == null or not InputMap.has_action(accion):
		return por_defecto
	for ev in InputMap.action_get_events(accion):
		if ev is InputEventKey:
			var k = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			return acortar(OS.get_keycode_string(k))
	return por_defecto


# Nombres largos de teclas → algo que quepa en el cuadrito
func acortar(nombre):
	var cortos = {
		"Kp Multiply": "*", "Kp Divide": "/", "Kp Add": "+", "Kp Subtract": "-",
		"Kp Enter": "ENT", "Kp Period": ".", "Space": "ESP", "Enter": "ENT",
		"Shift": "SHF", "Ctrl": "CTL", "Alt": "ALT", "Tab": "TAB",
	}
	if cortos.has(nombre):
		return cortos[nombre]
	if nombre.begins_with("Kp "):
		return nombre.substr(3)          # "Kp 1" → "1"
	return nombre.substr(0, 3)


# ================= MENSAJE FINAL =================
func dibujar_resultado():
	if partida == null or partida.mensaje_final == "":
		return
	var ancho_caja = 560.0
	var alto_caja = 96.0
	var x = (get_viewport_rect().size.x - ancho_caja) / 2.0
	var y = get_viewport_rect().size.y * 0.33
	draw_colored_polygon(pieza(x - 4, y - 4, ancho_caja + 8, alto_caja + 8, 20), Color.BLACK)
	draw_colored_polygon(pieza(x, y, ancho_caja, alto_caja, 20), CHASIS)
	draw_rect(Rect2(x + 20, y + alto_caja - 8, ancho_caja - 40, 4), AMARILLO)
	texto(Vector2(x, y + alto_caja - 32), partida.mensaje_final, 42, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, ancho_caja)


# ================= AYUDANTES DE DIBUJO =================
# Paralelogramo inclinado. Del lado izquierdo se inclina hacia la derecha;
# del lado derecho, al revés (espejo), como en Naruto.
func forma(x, y, w, h, izq, s = -1.0):
	if s < 0.0:
		s = sesgo
	if izq:
		return pieza(x, y, w, h, s)
	return PackedVector2Array([
		Vector2(x, y),
		Vector2(x + w - s, y),
		Vector2(x + w, y + h),
		Vector2(x + s, y + h),
	])


# Parte llena de una barra: desde la izquierda en P1, desde la derecha en P2
func tramo(x, y, w, h, frac, color, izq, s = -1.0):
	if s < 0.0:
		s = sesgo
	if frac <= 0.0:
		return
	var ww = maxf(w * frac, s + 2.0)
	if izq:
		draw_colored_polygon(forma(x, y, ww, h, true, s), color)
	else:
		draw_colored_polygon(forma(x + w - ww, y, ww, h, false, s), color)


func pieza(x, y, w, h, s):
	return PackedVector2Array([
		Vector2(x + s, y),
		Vector2(x + w, y),
		Vector2(x + w - s, y + h),
		Vector2(x, y + h),
	])


func rombo(c, r, color):
	var p = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(p, color)
	p.append(p[0])
	draw_polyline(p, Color.BLACK, 2.0, true)


func texto(pos, t, tam, color, alin = HORIZONTAL_ALIGNMENT_LEFT, ancho_t = -1.0):
	draw_string_outline(fuente, pos, t, alin, ancho_t, tam, 5, Color.BLACK)
	draw_string(fuente, pos, t, alin, ancho_t, tam, color)
	
func dibujar_controles():
	if not mostrar_controles:
		return
	var vista = get_viewport_rect().size
	var base_y = vista.y - margen_inferior
	lista_controles(CONTROLES_P1, Vector2(margen_lado, base_y), "JUGADOR 1")
	lista_controles(CONTROLES_P2, Vector2(vista.x - margen_lado - 170.0, base_y), "JUGADOR 2")


func lista_controles(lista, abajo_izq, titulo):
	var n = lista.size()
	var y = abajo_izq.y - n * alto_linea
	texto(Vector2(abajo_izq.x, y - alto_linea), titulo, tam_letra_controles, AMARILLO)
	for i in n:
		var fila = lista[i]
		var yy = y + i * alto_linea
		texto(Vector2(abajo_izq.x, yy), fila[0], tam_letra_controles, Color(1, 1, 1, 0.6))
		texto(Vector2(abajo_izq.x + 105.0, yy), fila[1], tam_letra_controles, Color(1, 1, 1, 0.95))
