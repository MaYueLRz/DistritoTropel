extends Camera3D

@export var objetivo: Node3D
@export var rival: Node3D

@export var distancia_base = 5.0           
@export var distancia_por_separacion = 0.7 
@export var distancia_max = 13.0
@export var altura = 2.6
@export var altura_mirada = 1.2
@export var suavizado = 3.0
@export var limite_min = Vector2(-15, -15)
@export var limite_max = Vector2(15, 15)


func _ready():
	top_level = true


func _physics_process(delta):
	if objetivo == null or rival == null:
		return


	var medio = (objetivo.global_position + rival.global_position) * 0.5
	medio.x = clampf(medio.x, limite_min.x, limite_max.x)
	medio.z = clampf(medio.z, limite_min.y, limite_max.y)

	var entre = rival.global_position - objetivo.global_position
	entre.y = 0.0
	var separacion = entre.length()
	if separacion < 0.01:
		return

	
	var lado = entre.normalized().cross(Vector3.UP)
	
	if lado.dot(global_position - medio) < 0.0:
		lado = -lado

	var atras = minf(distancia_base + separacion * distancia_por_separacion, distancia_max)
	var destino = medio + lado * atras + Vector3.UP * altura

	global_position = global_position.lerp(destino, suavizado * delta)

	var mirada = medio + Vector3(0, altura_mirada, 0)
	if global_position.distance_to(mirada) > 0.05:
		look_at(mirada)
