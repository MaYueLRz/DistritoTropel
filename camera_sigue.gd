extends Node3D

@export var objetivo: Node3D
@export var rival: Node3D

@export var altura_hombro = 1.7
@export var hombro = 0.9        # mueve la cámara de lado: quita la obstrucción
@export var encuadre = 0.25     # h_offset: solo corre la imagen
@export var peso_rival = 0.68

@export var factor_distancia = 0.55
@export var distancia_min = 3.2
@export var distancia_max = 7.5

@export var zoom_combo = 0.85
@export var velocidad_zoom = 4.0

@export var suavizado = 4.0
@export var giro = 5.0

@onready var brazo: SpringArm3D = $SpringArm3D
@onready var cam: Camera3D = $SpringArm3D/Camera3D

var zoom_actual = 1.0


func _ready():
	top_level = true
	# Que el brazo no confunda a los peleadores con una pared.
	if objetivo is CollisionObject3D:
		brazo.add_excluded_object(objetivo.get_rid())
	if rival is CollisionObject3D:
		brazo.add_excluded_object(rival.get_rid())


func peleando():
	for quien in [objetivo, rival]:
		if quien == null:
			continue
		var g = quien.get_node_or_null("Golpe")
		if g != null and g.esta_golpeando:
			return true
	return false


func _physics_process(delta):
	if objetivo == null or rival == null:
		return

	cam.h_offset = encuadre

	var alto_o = objetivo.global_position + Vector3.UP * altura_hombro
	var alto_r = rival.global_position + Vector3.UP * altura_hombro

	# Lo que la cámara mira: entre los dos, cargado hacia el rival.
	var foco = alto_o.lerp(alto_r, peso_rival)

	var plano = alto_r - alto_o
	plano.y = 0.0
	var separacion = plano.length()
	if separacion < 0.01:
		return
	var derecha = plano.normalized().cross(Vector3.UP)

	zoom_actual = lerpf(zoom_actual,
		zoom_combo if peleando() else 1.0, velocidad_zoom * delta)

	var atras = clampf(separacion * factor_distancia,
		distancia_min, distancia_max) * zoom_actual
	brazo.spring_length = lerpf(brazo.spring_length, atras, suavizado * delta)

	# El pivote va al lado del objetivo, no encima: así la cámara sale de la
	# línea que une a los dos y deja de verle la espalda al P1.
	var ancla = alto_o + derecha * hombro
	global_position = global_position.lerp(ancla, suavizado * delta)

	# La rotación tiene su propio suavizado: eso quita los tirones.
	if global_position.distance_to(foco) > 0.05:
		var deseada = global_transform.looking_at(foco, Vector3.UP).basis
		global_transform.basis = global_transform.basis.slerp(deseada, giro * delta)
