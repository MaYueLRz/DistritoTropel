extends Control

const VERDE = Color("01fd99")
const AMARILLO = Color("f9da17")
const ROJO = Color("ca2a2f")
const CHASIS = Color(0.10, 0.10, 0.11)
const RIEL = Color(0.20, 0.20, 0.22)
const BORDE = Color(0.95, 0.95, 0.95)
const APAGADO = Color(0.38, 0.38, 0.40)

const COLOR_ITEM = {
	"refajo": Color("f9da17"),
	"yox": Color("ff7a00"),
	"mieltertos": Color("01fd99"),
	"empanada": Color("d08a3a"),
}

@export var origen = Vector2(34.0, 48.0)
@export var ancho = 420.0
@export var alto = 34.0
@export var sesgo = 16.0
@export var lado_ranura = 64.0
@export var margen_abajo = 34.0

var salud = null
var inv = null
var salud2 = null
var partida = null
var ultimo_segundo = -1
var ultimo_mensaje = ""

@onready var fuente = ThemeDB.fallback_font


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

	var pj1 = get_tree().get_first_node_in_group("jugador1")
	if pj1 != null:
		salud = pj1.get_node_or_null("Salud")
		inv = pj1.get_node_or_null("Inventario")
		if salud != null:
			salud.cambio.connect(_al_cambiar)
		if inv != null and inv.has_signal("cambio"):
			inv.cambio.connect(_al_cambiar)
	else:
		print("HUD: no encontré al jugador 1")

	var pj2 = get_tree().get_first_node_in_group("jugador2")
	if pj2 != null:
		salud2 = pj2.get_node_or_null("Salud")
		if salud2 != null:
			salud2.cambio.connect(_al_cambiar)
	else:
		print("HUD: no encontré al jugador 2")

	await get_tree().process_frame
	partida = get_tree().get_first_node_in_group("partida")
	queue_redraw()

func _process(_delta):
	if partida == null:
		return
	if partida.mensaje_final != ultimo_mensaje:
		ultimo_mensaje = partida.mensaje_final
		queue_redraw()
	var segundos = int(ceil(partida.tiempo))
	if segundos != ultimo_segundo:
		ultimo_segundo = segundos
		queue_redraw()


func _al_cambiar(_lo_que_sea):
	queue_redraw()


func _draw():
	dibujar_vida()
	dibujar_vida_enemigo()
	dibujar_contador()
	dibujar_ranuras()
	dibujar_resultado()

func dibujar_resultado():
	if partida == null or partida.mensaje_final == "":
		return

	var ancho_caja = 560.0
	var alto_caja = 96.0
	var x = (get_viewport_rect().size.x - ancho_caja) / 2.0
	var y = get_viewport_rect().size.y * 0.33

	draw_polygon(pieza(x - 7, y - 7, ancho_caja + 14, alto_caja + 14, 20),
		PackedColorArray([CHASIS]))
	var caja = pieza(x, y, ancho_caja, alto_caja, 20)
	draw_polygon(caja, PackedColorArray([RIEL]))
	contorno(caja, BORDE, 3.0)

	draw_string(fuente, Vector2(x, y + alto_caja - 32), partida.mensaje_final,
		HORIZONTAL_ALIGNMENT_CENTER, ancho_caja, 42, Color.WHITE)

# Un rectángulo inclinado: el borde de arriba corrido a la derecha.
func pieza(x, y, w, h, s):
	return PackedVector2Array([
		Vector2(x + s, y),
		Vector2(x + w, y),
		Vector2(x + w - s, y + h),
		Vector2(x, y + h),
	])


func contorno(puntos, color, grosor):
	var cerrado = PackedVector2Array(puntos)
	cerrado.append(puntos[0])
	draw_polyline(cerrado, color, grosor, true)


func color_vida(fraccion):
	if fraccion > 0.5:
		return VERDE
	if fraccion > 0.2:
		return AMARILLO
	return ROJO


func dibujar_vida():
	var vida = 0
	var maxima = 1
	if salud != null:
		vida = salud.vida
		maxima = maxi(salud.vida_inicial, 1)
	var fraccion = clampf(float(vida) / float(maxima), 0.0, 1.0)

	var x = origen.x
	var y = origen.y

	draw_string(fuente, Vector2(x + sesgo, y - 12), "VIDA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BORDE)

	draw_polygon(pieza(x - 6, y - 6, ancho + 12, alto + 12, sesgo),
		PackedColorArray([CHASIS]))

	var riel = pieza(x, y, ancho, alto, sesgo)
	draw_polygon(riel, PackedColorArray([RIEL]))

	if fraccion > 0.0:
		var w = maxf(ancho * fraccion, sesgo + 2.0)
		draw_polygon(pieza(x, y, w, alto, sesgo),
			PackedColorArray([color_vida(fraccion)]))

	contorno(riel, BORDE, 2.0)

	var texto = str(vida) + " / " + str(maxima)
	draw_string(fuente, Vector2(x + sesgo + 13, y + alto - 9), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0, 0, 0, 0.7))
	draw_string(fuente, Vector2(x + sesgo + 12, y + alto - 10), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)


func dibujar_ranuras():
	var items = []
	var cuantas = 2
	if inv != null:
		items = inv.items
		cuantas = inv.MAXIMO

	var y = get_viewport_rect().size.y - lado_ranura - margen_abajo
	for i in range(cuantas):
		var x = origen.x + i * (lado_ranura + 14)
		var caja = pieza(x, y, lado_ranura, lado_ranura, 10)
		draw_polygon(caja, PackedColorArray([CHASIS]))

		var hueco = pieza(x + 5, y + 5, lado_ranura - 10, lado_ranura - 10, 8)
		var lleno = i < items.size()
		if lleno:
			var tipo = items[i]
			draw_polygon(hueco, PackedColorArray([COLOR_ITEM.get(tipo, BORDE)]))
			draw_string(fuente, Vector2(x + 9, y + lado_ranura - 13),
				str(tipo).substr(0, 5).to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, lado_ranura - 12, 12, Color.BLACK)
		else:
			draw_polygon(hueco, PackedColorArray([RIEL]))

		contorno(caja, BORDE, 2.0)

		var tecla = "O" if i == 0 else "P"
		draw_string(fuente, Vector2(x + lado_ranura - 18, y + 19), tecla,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BORDE if lleno else APAGADO)


func dibujar_vida_enemigo():
	if salud2 == null:
		return
	var vida = salud2.vida
	var maxima = maxi(salud2.vida_inicial, 1)
	var fraccion = clampf(float(vida) / float(maxima), 0.0, 1.0)

	var x = get_viewport_rect().size.x - ancho - origen.x
	var y = origen.y

	draw_string(fuente, Vector2(x, y - 12), "RIVAL",
		HORIZONTAL_ALIGNMENT_RIGHT, ancho - sesgo, 15, BORDE)

	draw_polygon(pieza(x - 6, y - 6, ancho + 12, alto + 12, sesgo),
		PackedColorArray([CHASIS]))

	var riel = pieza(x, y, ancho, alto, sesgo)
	draw_polygon(riel, PackedColorArray([RIEL]))

	# El relleno del rival se vacía hacia la izquierda, al revés que el tuyo.
	if fraccion > 0.0:
		var w = maxf(ancho * fraccion, sesgo + 2.0)
		draw_polygon(pieza(x + ancho - w, y, w, alto, sesgo),
			PackedColorArray([color_vida(fraccion)]))

	contorno(riel, BORDE, 2.0)

	var texto = str(vida) + " / " + str(maxima)
	draw_string(fuente, Vector2(x, y + alto - 9), texto,
		HORIZONTAL_ALIGNMENT_RIGHT, ancho - sesgo - 11, 19, Color(0, 0, 0, 0.7))
	draw_string(fuente, Vector2(x, y + alto - 10), texto,
		HORIZONTAL_ALIGNMENT_RIGHT, ancho - sesgo - 12, 19, Color.WHITE)


func dibujar_contador():
	if partida == null:
		return
	var segundos = int(ceil(partida.tiempo))
	var ancho_caja = 124.0
	var alto_caja = 54.0
	var x = (get_viewport_rect().size.x - ancho_caja) / 2.0
	var y = origen.y - 16

	draw_polygon(pieza(x - 6, y - 6, ancho_caja + 12, alto_caja + 12, 12),
		PackedColorArray([CHASIS]))

	var caja = pieza(x, y, ancho_caja, alto_caja, 12)
	draw_polygon(caja, PackedColorArray([ROJO if segundos <= 10 else RIEL]))
	contorno(caja, BORDE, 2.0)

	draw_string(fuente, Vector2(x, y + alto_caja - 14), str(segundos),
		HORIZONTAL_ALIGNMENT_CENTER, ancho_caja, 34, Color.WHITE)
