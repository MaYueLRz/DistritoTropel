extends CanvasLayer
# Entrega21 - lo que se ve cuando termina una ronda y cuando termina el combate.
# Partida lo crea solo (no hay que agregar nodos a main.tscn) y le avisa con dos señales:
#   ronda_terminada -> cartel "K.O." / "¡TIEMPO!" / "EMPATE" atravesando la pantalla
#   combate_terminado -> pantalla de victoria con el estilo del menú de pausa
# El estilo sale de lo que ya hay: letrero metálico, grafitis, botones oxidados, fuente Anton,
# y el display de un bus de TransMilenio con el texto corriendo.

const AMARILLO = Color("f9da17")
const ROJO_KO = Color("e63a2e")
const ROJO_TM = Color("B8322F")
const CREMA = Color("F2E6C9")
const NARANJA = Color("FF6B1A")
const AMBAR = Color("FFB000")
const COLOR_J = [Color("FFC72C"), Color("3DD6F5")]   # los mismos colores de P1 y P2 del HUD

const IMAGENES = "res://Animaciones y Personajes/"
const LETRERO_ANCHO = 948.0
const LETRERO_ALTO = 1009.0

@export var frases: Array[String] = [
	"¡QUÉ CHIMBA DE PELEA, PARCE!",
	"¡NI EL TRANSMILENIO LO FRENÓ!",
	"¡DE LA PLAZA IMPERIAL A LA GLORIA!",
	"¡ESO, PARCE! ¡QUÉ NIVEL!",
	"¡PELEA MÁS BERRACA QUE UN TRANCÓN EN LA 80!",
	"¡ESTO ES DISTRITO TROPEL!",
]
@export var velocidad_letrero_led = 110.0

var partida = null
var fuente = null
var banner = null
var victoria = null
var victoria_activa = false
var texto_led = null
var frase = ""


func _ready():
	layer = 8      # encima del HUD (1) y la cuenta atrás (5), debajo del menú de pausa (10)
	process_mode = Node.PROCESS_MODE_ALWAYS
	fuente = load("res://Anton-Regular.ttf")
	if partida == null:
		partida = get_tree().get_first_node_in_group("partida")
	if partida == null:
		return
	partida.ronda_terminada.connect(_al_terminar_ronda)
	partida.combate_terminado.connect(_al_terminar_combate)


func _process(delta):
	if texto_led == null:
		return
	texto_led.position.x -= velocidad_letrero_led * delta
	if texto_led.position.x < -texto_led.size.x * 0.5:
		texto_led.position.x += texto_led.size.x * 0.5


# Mientras se ve la victoria, Esc no puede quitarle la pausa al juego.
func _input(event):
	if victoria_activa and event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()


# ============================================================ cartel entre rondas

func _al_terminar_ronda(ganador, como):
	var vista = get_viewport().get_visible_rect().size
	banner = Control.new()
	anclar(banner, 0.0, 0.0, 1.0, 1.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	# Destello blanco al golpe del cartel
	var destello = ColorRect.new()
	anclar(destello, 0.0, 0.0, 1.0, 1.0)
	destello.color = Color(1, 1, 1, 0.55)
	destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(destello)
	create_tween().tween_property(destello, "color:a", 0.0, 0.35).set_delay(0.12)

	# La banda negra, un poquito inclinada, con franjas de peligro arriba y abajo
	var alto = vista.y * 0.40
	var banda = Control.new()
	banda.size = Vector2(vista.x * 1.2, alto)
	banda.position = Vector2(-vista.x * 1.4, vista.y * 0.28)
	banda.pivot_offset = banda.size / 2.0
	banda.rotation_degrees = -3.0
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banda)

	var fondo = ColorRect.new()
	anclar(fondo, 0.0, 0.0, 1.0, 1.0)
	fondo.color = Color(0.04, 0.04, 0.05, 0.9)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banda.add_child(fondo)
	var franja_alta = franja_peligro(banda.size.x, alto * 0.07)
	banda.add_child(franja_alta)
	var franja_baja = franja_peligro(banda.size.x, alto * 0.07)
	franja_baja.position.y = alto - alto * 0.07
	banda.add_child(franja_baja)

	# Texto grande
	var grande = "K.O."
	var color = ROJO_KO
	if como == "tiempo":
		grande = "¡TIEMPO!"
		color = AMARILLO
	elif como == "empate":
		grande = "EMPATE"
		color = CREMA
	var texto = etiqueta(grande, int(alto * 0.58), color)
	centrar_en_banda(texto, banda, alto * 0.38)
	banda.add_child(texto)

	# Quién ganó la ronda
	var chico = ""
	var color_chico = CREMA
	if ganador == 0:
		chico = "SE REPITE LA RONDA"
	else:
		color_chico = COLOR_J[ganador - 1]
		if partida.campeon != 0:
			chico = "JUGADOR " + str(ganador) + "  GANA EL COMBATE"
		else:
			chico = "JUGADOR " + str(ganador) + "  GANA LA RONDA " + str(partida.ronda)
	var sub = etiqueta(chico, int(alto * 0.14), color_chico)
	centrar_en_banda(sub, banda, alto * 0.80)
	banda.add_child(sub)

	# Animación: la banda entra de golpe, el texto cae grande y se asienta
	texto.scale = Vector2(3.2, 3.2)
	texto.modulate.a = 0.0
	sub.modulate.a = 0.0
	var t = create_tween().set_parallel()
	t.tween_property(banda, "position:x", -vista.x * 0.1, 0.28) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(texto, "modulate:a", 1.0, 0.1).set_delay(0.14)
	t.tween_property(texto, "scale", Vector2.ONE, 0.38).set_delay(0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sub, "modulate:a", 1.0, 0.25).set_delay(0.55)
	var temblor = create_tween()
	temblor.tween_interval(0.5)
	for g in [-2.0, 1.4, -0.8, 0.0]:
		temblor.tween_property(banda, "rotation_degrees", -3.0 + g, 0.04)
	sonar("anuncio", -2.0)


# ============================================================ pantalla de victoria

func _al_terminar_combate(campeon):
	if banner != null:
		var t = create_tween()
		t.tween_property(banner, "modulate:a", 0.0, 0.25)
		t.tween_callback(banner.queue_free)
		banner = null
	armar_victoria(campeon)


func armar_victoria(campeon):
	victoria_activa = true
	frase = frases[randi() % frases.size()]
	var vista = get_viewport().get_visible_rect().size
	var color = COLOR_J[campeon - 1]

	victoria = Control.new()
	anclar(victoria, 0.0, 0.0, 1.0, 1.0)
	victoria.mouse_filter = Control.MOUSE_FILTER_STOP     # nada de clics al juego de atrás
	add_child(victoria)

	# 1. El juego de fondo, borroso y tintado, igual que en la pausa
	var fondo = ColorRect.new()
	anclar(fondo, 0.0, 0.0, 1.0, 1.0)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra = load("res://desenfoque.gdshader")
	if sombra != null:
		var material = ShaderMaterial.new()
		material.shader = sombra
		fondo.material = material
	else:
		fondo.color = Color(0, 0, 0, 0.75)
	fondo.modulate.a = 0.0
	victoria.add_child(fondo)
	create_tween().tween_property(fondo, "modulate:a", 1.0, 0.5)

	# 2. El logo con el TransMilenio, a la izquierda
	var logo = textura("logo.png")
	if logo != null:
		anclar(logo, 0.0, 0.31, 0.38, 0.6)
		logo.modulate.a = 0.0
		victoria.add_child(logo)
		create_tween().tween_property(logo, "modulate:a", 1.0, 0.5).set_delay(0.5)

	# 3. El letrero metálico en el centro
	var alto = vista.y * 0.84
	var ancho = alto * LETRERO_ANCHO / LETRERO_ALTO
	var escala = alto / LETRERO_ALTO
	var letrero = Control.new()
	letrero.size = Vector2(ancho, alto)
	var x_final = vista.x * 0.605 - ancho / 2.0
	var y_final = vista.y - alto - vista.y * 0.045
	letrero.position = Vector2(x_final, -alto - 40.0)
	letrero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victoria.add_child(letrero)

	var chapa = textura("letrero.png")
	anclar(chapa, 0.0, 0.0, 1.0, 1.0)
	letrero.add_child(chapa)

	# El letrero trae "PAUSA" escrito: se tapa con un parche del mismo metal y se escribe encima
	var parche = TextureRect.new()
	var recorte = AtlasTexture.new()
	recorte.atlas = load(IMAGENES + "letrero.png")
	recorte.region = Rect2(52, 16, 235, 128)
	parche.texture = recorte
	parche.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parche.stretch_mode = TextureRect.STRETCH_SCALE
	parche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anclar(parche, 48.0 / LETRERO_ANCHO, 12.0 / LETRERO_ALTO, 900.0 / LETRERO_ANCHO, 150.0 / LETRERO_ALTO)
	letrero.add_child(parche)
	var titulo = etiqueta("¡VICTORIA!", int(112.0 * escala), CREMA, 0)
	centrar_en(titulo, letrero, 81.0 / LETRERO_ALTO, 48.0 / LETRERO_ANCHO, 900.0 / LETRERO_ANCHO)

	# Los cuatro huecos del letrero: ganador, marcador, Revancha y Salir
	var hueco1 = hueco(letrero, 245.0, 388.0)
	var nombre = etiqueta("JUGADOR " + str(campeon), int(74.0 * escala), color, 5)
	centrar_en(nombre, hueco1, 0.36)
	var gana = etiqueta("¡GANA EL COMBATE!", int(34.0 * escala), CREMA, 3)
	centrar_en(gana, hueco1, 0.80)

	var hueco2 = hueco(letrero, 417.0, 548.0)
	var marcador = RichTextLabel.new()
	marcador.bbcode_enabled = true
	marcador.scroll_active = false
	marcador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marcador.add_theme_font_override("normal_font", fuente)
	var tam_marcador = int(80.0 * escala)
	marcador.add_theme_font_size_override("normal_font_size", tam_marcador)
	marcador.add_theme_constant_override("outline_size", 6)
	marcador.add_theme_color_override("font_outline_color", Color.BLACK)
	marcador.text = "[center][color=#%s]%d[/color]  -  [color=#%s]%d[/color][/center]" % [
		COLOR_J[0].to_html(false), partida.victorias_de(1),
		COLOR_J[1].to_html(false), partida.victorias_de(2)]
	var alto_marcador = fuente.get_height(tam_marcador)
	anclar(marcador, 0.0, 0.40, 1.0, 0.40)
	marcador.offset_top = -alto_marcador / 2.0
	marcador.offset_bottom = alto_marcador / 2.0
	hueco2.add_child(marcador)
	var rondas = etiqueta("RONDAS GANADAS", int(28.0 * escala), CREMA, 3)
	centrar_en(rondas, hueco2, 0.84)

	var boton_revancha = boton(letrero, 584.0, 713.0, "REVANCHA", "boton_rojo.png", escala)
	var boton_salir = boton(letrero, 750.0, 878.0, "SALIR", "boton_verde.png", escala)
	boton_revancha.pressed.connect(_al_pulsar_revancha)
	boton_salir.pressed.connect(_al_pulsar_salir)
	boton_revancha.focus_neighbor_bottom = boton_salir.get_path()
	boton_salir.focus_neighbor_top = boton_revancha.get_path()

	# 4. El marco de grafitis, encima del letrero (igual que la pausa)
	var marco = textura("marco_grafiti.png")
	anclar(marco, 0.0, 0.0, 1.0, 1.0)
	victoria.add_child(marco)

	# 5. El display del bus de TransMilenio, arriba, sin que los grafitis lo tapen
	armar_display(vista, campeon)

	# 6. Confeti con los colores de la ciudad
	victoria.add_child(confeti(vista))

	# Entrada: el letrero cae y rebota
	var t = create_tween()
	t.tween_property(letrero, "position:y", y_final, 0.75).set_delay(0.3) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_callback(boton_revancha.grab_focus)
	sonar("ovacion", 0.0)
	print("pantalla de victoria: jugador ", campeon, " · marcador ", partida.victorias_de(1), " - ", partida.victorias_de(2))


func hueco(letrero, y0, y1):
	var c = Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anclar(c, 150.0 / LETRERO_ANCHO, y0 / LETRERO_ALTO, 806.0 / LETRERO_ANCHO, y1 / LETRERO_ALTO)
	letrero.add_child(c)
	return c


# Botón con la textura oxidada del menú de pausa, con la misma animación al señalarlo.
func boton(letrero, y0, y1, texto, imagen, escala):
	var b = Button.new()
	b.text = texto
	anclar(b, 150.0 / LETRERO_ANCHO, y0 / LETRERO_ALTO, 806.0 / LETRERO_ANCHO, y1 / LETRERO_ALTO)
	var estilo = StyleBoxTexture.new()
	estilo.texture = load(IMAGENES + imagen)
	estilo.texture_margin_left = 18.0
	estilo.texture_margin_top = 18.0
	estilo.texture_margin_right = 18.0
	estilo.texture_margin_bottom = 18.0
	for nombre in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(nombre, estilo)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", fuente)
	b.add_theme_font_size_override("font_size", int(62.0 * escala))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.focus_entered.connect(_resaltar.bind(b, true))
	b.focus_exited.connect(_resaltar.bind(b, false))
	b.mouse_entered.connect(b.grab_focus)
	letrero.add_child(b)
	return b


func _resaltar(b, activo):
	if activo:
		sonar("ui_hover", -8.0)
	b.pivot_offset = b.size / 2.0
	var t = create_tween().set_parallel()
	t.tween_property(b, "scale", Vector2(1.06, 1.06) if activo else Vector2.ONE, 0.12)
	t.tween_property(b, "modulate", Color(1.12, 1.12, 1.12) if activo else Color.WHITE, 0.12)


func _al_pulsar_revancha():
	sonar("ui_click")
	partida.revancha()


func _al_pulsar_salir():
	sonar("ui_click")
	get_tree().quit()


# El display de adelante de un bus: fondo negro, letras ámbar corriendo.
func armar_display(vista, campeon):
	var caja = Panel.new()
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.03, 0.035)
	estilo.border_color = ROJO_TM
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(8)
	caja.add_theme_stylebox_override("panel", estilo)
	caja.clip_contents = true
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anclar(caja, 0.2, 0.025, 0.8, 0.025)
	caja.offset_bottom = 46.0
	victoria.add_child(caja)

	var campo = "TRANSMILENIO  •  ESTACIÓN: VICTORIA  •  GANA EL JUGADOR %d  •  %s  •  PRÓXIMA PARADA: REVANCHA  •  " % [campeon, frase]
	texto_led = etiqueta(campo + campo, 26, AMBAR, 0)
	texto_led.size = Vector2(campo.length() * 2 * 17.0, 40.0)
	texto_led.position = Vector2(20.0, 2.0)
	texto_led.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_led.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caja.add_child(texto_led)


func confeti(vista):
	var c = CPUParticles2D.new()
	c.position = Vector2(vista.x * 0.5, -30.0)
	c.amount = 120
	c.lifetime = 5.0
	c.preprocess = 0.0
	c.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	c.emission_rect_extents = Vector2(vista.x * 0.5, 4.0)
	c.direction = Vector2(0, 1)
	c.spread = 25.0
	c.gravity = Vector2(0, 240)
	c.initial_velocity_min = 80.0
	c.initial_velocity_max = 230.0
	c.angular_velocity_min = -320.0
	c.angular_velocity_max = 320.0
	c.scale_amount_min = 6.0
	c.scale_amount_max = 13.0
	var g = Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	g.colors = PackedColorArray([ROJO_TM, AMARILLO, CREMA, NARANJA, COLOR_J[1]])
	c.color_initial_ramp = g
	c.emitting = true
	return c


# ============================================================ ayudantes

func anclar(nodo, x0, y0, x1, y1):
	nodo.anchor_left = x0
	nodo.anchor_top = y0
	nodo.anchor_right = x1
	nodo.anchor_bottom = y1
	nodo.offset_left = 0.0
	nodo.offset_top = 0.0
	nodo.offset_right = 0.0
	nodo.offset_bottom = 0.0


# Un texto no puede ser más bajo que su letra, así que se centra por su altura real.
func centrar_en(l, padre, cy, x0 = 0.0, x1 = 1.0):
	var h = altura_de(l)
	anclar(l, x0, cy, x1, cy)
	l.offset_top = -h / 2.0
	l.offset_bottom = h / 2.0
	padre.add_child(l)


func centrar_en_banda(l, banda, cy):
	var h = altura_de(l)
	l.size = Vector2(banda.size.x, h)
	l.position = Vector2(0.0, cy - h / 2.0)
	l.pivot_offset = l.size / 2.0


func altura_de(l):
	return fuente.get_height(l.get_theme_font_size("font_size"))


func textura(archivo):
	var ruta = IMAGENES + archivo
	if not ResourceLoader.exists(ruta):
		print("pantalla_ronda: falta ", ruta)
		return null
	var t = TextureRect.new()
	t.texture = load(ruta)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func etiqueta(texto, tam, color, contorno = 14):
	var l = Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fuente != null:
		l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if contorno > 0:
		l.add_theme_constant_override("outline_size", contorno)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
	return l


# Franja diagonal amarilla y negra, como en las barras del HUD y del letrero.
func franja_peligro(ancho, alto):
	var c = Control.new()
	c.size = Vector2(ancho, alto)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var x = -alto
		var i = 0
		while x < ancho:
			var col = AMARILLO if i % 2 == 0 else Color.BLACK
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(x, alto), Vector2(x + alto, alto),
				Vector2(x + alto * 2.0, 0.0), Vector2(x + alto, 0.0)]), col)
			x += alto
			i += 1)
	return c


func sonar(nombre, db = 0.0):
	var ruta = "res://sonidos/" + nombre + ".wav"
	if not ResourceLoader.exists(ruta):
		return
	var voz = AudioStreamPlayer.new()
	voz.stream = load(ruta)
	voz.volume_db = db
	if AudioServer.get_bus_index("SFX") != -1:
		voz.bus = "SFX"
	add_child(voz)
	voz.finished.connect(voz.queue_free)
	voz.play()
