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

@onready var fuente = ThemeDB.fallback_font


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		print("HUD: no encontré al jugador")
		return
	salud = pj.get_node_or_null("Salud")
	if salud != null:
		salud.cambio.connect(_al_cambiar)
	else:
		print("HUD: al Personaje le falta el nodo Salud")
	inv = pj.get_node_or_null("Inventario")
	if inv != null and inv.has_signal("cambio"):
		inv.cambio.connect(_al_cambiar)
	else:
		print("HUD: al Personaje le falta el nodo Inventario")
	await get_tree().process_frame
	queue_redraw()


func _al_cambiar(_lo_que_sea):
	queue_redraw()


func _draw():
	dibujar_vida()
	dibujar_ranuras()


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
