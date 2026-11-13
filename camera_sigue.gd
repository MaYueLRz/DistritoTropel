extends Camera3D

@export var objetivo: Node3D
@export var rival: Node3D
@export var distancia = Vector3(1.2, 2.2, 4.5)
@export var suavizado = 3.0
@export var limite_min = Vector2(-15, -15)
@export var limite_max = Vector2(15, 15)

func _ready():
	top_level = true
	

func _physics_process(delta):
	if objetivo == null or  rival == null :
		return
	var foco = objetivo.global_position
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z =clamp(foco.z ,limite_min.y , limite_max.y)
	var hacia_rival = rival.global_position - objetivo.global_position
	hacia_rival.y = 0.0
	hacia_rival= hacia_rival.normalized()
	var derecha = hacia_rival.cross(Vector3.UP)
	var destino = foco -(hacia_rival*distancia.z)+(Vector3.UP*distancia.y)+(derecha*distancia.x)
	global_position = global_position.lerp(destino, suavizado * delta)
	var punto_medio = (objetivo.global_position + rival.global_position)/2.0 + Vector3(0,1.2,0)
	look_at(punto_medio)
