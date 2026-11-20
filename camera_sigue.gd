extends Camera3D

@export var objetivo: Node3D
@export var rival: Node3D

@export var distancia_base = 3.5
@export var distancia_por_separacion = 0.9
@export var distancia_max = 13.0
@export var altura = 1.8
@export var altura_mirada = 1.1
@export var suavizado = 4.5

# 0 = de costado puro. 90 = justo detrás de la espalda del que ataca.
@export var angulo_neutral = 10.0
@export var angulo_ataque = 45.0
@export var velocidad_angulo = 2.5

@export var limite_min = Vector2(-15, -15)
@export var limite_max = Vector2(15, 15)

var favorito: Node3D = null
var angulo_actual = 10.0


func _ready():
	top_level = true


func golpeando(quien):
	if quien == null:
		return false
	var g = quien.get_node_or_null("Golpe")
	if g == null:
		return false
	return g.esta_golpeando


func _physics_process(delta):
	if objetivo == null or rival == null:
		return

	# Quien ataca se lleva la cámara a su espalda. Si nadie ataca se queda
	# donde estaba, para que no dé bandazos al terminar cada golpe.
	var ataca_o = golpeando(objetivo)
	var ataca_r = golpeando(rival)
	if ataca_o and not ataca_r:
		favorito = objetivo
	elif ataca_r and not ataca_o:
		favorito = rival
	if favorito == null:
		favorito = objetivo
	var otro = rival if favorito == objetivo else objetivo

	# En neutral se abre de costado; en ofensiva se mete detrás del atacante.
	var meta = angulo_neutral
	if ataca_o or ataca_r:
		meta = angulo_ataque
	angulo_actual = lerpf(angulo_actual, meta, velocidad_angulo * delta)

	var medio = (objetivo.global_position + rival.global_position) * 0.5
	medio.x = clampf(medio.x, limite_min.x, limite_max.x)
	medio.z = clampf(medio.z, limite_min.y, limite_max.y)

	var detras = favorito.global_position - otro.global_position
	detras.y = 0.0
	var separacion = detras.length()
	if separacion < 0.01:
		return
	detras = detras.normalized()

	var lado = detras.cross(Vector3.UP)
	if lado.dot(global_position - medio) < 0.0:
		lado = -lado

	var r = deg_to_rad(angulo_actual)
	var dir = (lado * cos(r) + detras * sin(r)).normalized()

	var atras = minf(distancia_base + separacion * distancia_por_separacion, distancia_max)
	var destino = medio + dir * atras + Vector3.UP * altura

	global_position = global_position.lerp(destino, suavizado * delta)

	var mirada = medio + Vector3(0, altura_mirada, 0)
	if global_position.distance_to(mirada) > 0.05:
		look_at(mirada)
