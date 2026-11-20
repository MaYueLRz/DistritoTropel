extends CanvasLayer
# Entrega20 - cuenta atrás de la ronda: 3, 2, 1, ¡PELEA!
# Mientras cuenta, los peleadores y la partida quedan quietos y la cámara entra
# desde lejos y desde arriba hasta el encuadre normal de camera_sigue.gd.
# No toca personaje.gd, camera_sigue.gd ni partida.gd: solo los apaga y los prende.

signal pelea_empezo

@export var numeros = 3
@export var segundos_por_numero = 1.0
@export var texto_final = "¡PELEA!"
@export var tiempo_texto_final = 0.9
@export var tamano_letra = 220
# 3 en blanco, 2 en amarillo, 1 en naranja y ¡PELEA! en rojo, a juego con la plaza.
@export var colores: Array[Color] = [Color("f2f2f2"), Color("f9da17"), Color("ff7a00")]
@export var color_final = Color("d62828")

# Dónde arranca la cámara respecto al punto medio de los dos peleadores.
@export var intro_distancia = 16.0
@export var intro_altura = 9.0
@export var intro_desplazamiento = 6.0
@export var suavizado_intro = 1.4

@export var barras = true
@export var alto_barras = 90.0

var congelados = []
var camara = null
var suavizado_normal = 0.0
var restante = 0
var reloj = 0.0
var contando = true
var etiqueta = null
var barra_arriba = null
var barra_abajo = null
var animacion = null


func _ready():
	layer = 5      # encima del HUD (1) y debajo del menú de pausa (10)
	armar_pantalla()
	congelar()
	preparar_camara()
	restante = numeros
	reloj = segundos_por_numero
	mostrar(str(restante), color_del_numero(restante), false)
	print("cuenta ", restante, " cuadro ", Engine.get_physics_frames())


func _physics_process(delta):
	if not contando:
		return
	reloj -= delta
	if reloj > 0.001:
		return
	restante -= 1
	if restante > 0:
		reloj = segundos_por_numero
		mostrar(str(restante), color_del_numero(restante), false)
		print("cuenta ", restante, " cuadro ", Engine.get_physics_frames())
	else:
		empezar()


func empezar():
	contando = false
	if camara != null and suavizado_normal > 0.0:
		camara.suavizado = suavizado_normal
	for nodo in congelados:
		if is_instance_valid(nodo):
			nodo.set_physics_process(true)
	print(texto_final, " cuadro ", Engine.get_physics_frames())
	pelea_empezo.emit()
	mostrar(texto_final, color_final, true)
	retirar_barras()
	await get_tree().create_timer(tiempo_texto_final).timeout
	queue_free()


# Quita el control a todos los que se mueven o golpean y los deja en su pose quieta.
func congelar():
	var hijos = ["Golpe", "Inventario", "Interactuar"]
	for grupo in ["jugador1", "jugador2", "enemigo", "partida"]:
		for nodo in get_tree().get_nodes_in_group(grupo):
			if nodo in congelados:
				continue
			congelados.append(nodo)
			nodo.set_physics_process(false)
			for nombre in hijos:
				var hijo = nodo.get_node_or_null(nombre)
				if hijo != null:
					congelados.append(hijo)
					hijo.set_physics_process(false)
			if grupo.begins_with("jugador"):
				posar(nodo)


# Idle y de frente al rival, porque personaje.gd no corre mientras está congelado.
func posar(pj):
	var anim = pj.get_node_or_null("Modelo/AnimationPlayer")
	if anim != null and anim.has_animation("Idile/mixamo_com"):
		anim.play("Idile/mixamo_com")
	var rival = pj.get("rival")
	if rival == null:
		return
	var hacia = rival.global_position - pj.global_position
	hacia.y = 0.0
	if hacia.length() > 0.05:
		pj.basis = Basis.looking_at(hacia.normalized())


# La cámara arranca arriba y lejos, del mismo lado en que ya estaba, y camera_sigue.gd
# la va acercando sola al encuadre normal porque aquí solo se le baja el suavizado.
func preparar_camara():
	camara = get_viewport().get_camera_3d()
	if camara == null:
		return
	var a = camara.get("objetivo")
	var b = camara.get("rival")
	if a == null or b == null:
		camara = null
		return
	suavizado_normal = camara.suavizado
	camara.suavizado = suavizado_intro

	var medio = (a.global_position + b.global_position) * 0.5
	var entre = b.global_position - a.global_position
	entre.y = 0.0
	if entre.length() < 0.01:
		return
	entre = entre.normalized()
	var lado = entre.cross(Vector3.UP)
	if lado.dot(camara.global_position - medio) < 0.0:
		lado = -lado
	camara.global_position = medio + lado * intro_distancia \
		+ entre * intro_desplazamiento + Vector3.UP * intro_altura
	camara.look_at(medio + Vector3(0.0, camara.altura_mirada, 0.0))
	print("camara de entrada a ", snappedf(camara.global_position.distance_to(medio), 0.1), " m")


func color_del_numero(n):
	var i = clampi(numeros - n, 0, colores.size() - 1)
	return colores[i]


func mostrar(texto, color, es_final):
	etiqueta.text = texto
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	etiqueta.scale = Vector2(1.8, 1.8)
	etiqueta.modulate.a = 1.0
	if animacion != null:
		animacion.kill()
	animacion = create_tween().set_parallel()
	animacion.tween_property(etiqueta, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var espera = tiempo_texto_final if es_final else segundos_por_numero
	animacion.tween_property(etiqueta, "modulate:a", 0.0, 0.25) \
		.set_delay(maxf(espera - 0.25, 0.0))


func retirar_barras():
	if not barras:
		return
	var t = create_tween().set_parallel()
	t.tween_property(barra_arriba, "offset_bottom", 0.0, 0.4)
	t.tween_property(barra_abajo, "offset_top", 0.0, 0.4)


func armar_pantalla():
	etiqueta = Label.new()
	etiqueta.set_anchors_preset(Control.PRESET_FULL_RECT)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fuente = load("res://Anton-Regular.ttf")
	if fuente != null:
		etiqueta.add_theme_font_override("font", fuente)
	etiqueta.add_theme_font_size_override("font_size", tamano_letra)
	etiqueta.add_theme_constant_override("outline_size", 18)
	etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(etiqueta)

	if not barras:
		return
	# Capa 0: las barras quedan detrás del HUD (capa 1), así que la vida se sigue viendo.
	var capa_barras = CanvasLayer.new()
	capa_barras.layer = 0
	add_child(capa_barras)

	barra_arriba = ColorRect.new()
	barra_arriba.color = Color.BLACK
	barra_arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_arriba.anchor_right = 1.0
	barra_arriba.offset_bottom = alto_barras
	capa_barras.add_child(barra_arriba)

	barra_abajo = ColorRect.new()
	barra_abajo.color = Color.BLACK
	barra_abajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_abajo.anchor_top = 1.0
	barra_abajo.anchor_right = 1.0
	barra_abajo.anchor_bottom = 1.0
	barra_abajo.offset_top = -alto_barras
	capa_barras.add_child(barra_abajo)
