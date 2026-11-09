class_name LuzJugador
extends SpotLight3D
# Taller 4 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 2: además de seguir al jugador, decide si da sombra (cada sombra cuesta).

@export var rango := 6.0
@export var altura := 4.0
# Tabla de sombras de mi zona (ver documento): solo el sol da sombra. El foco NO:
# su sombra cae justo debajo del luchador (la cámara lateral casi no la ve) y cuesta 4 draw calls
# en la medida. El aura naranja tampoco (no hay nada que tape).
@export var con_sombra := false


func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot_range = rango
	spot_attenuation = 2.0
	shadow_enabled = con_sombra
	print(atenuacion(1.0), " ", atenuacion(2.0), " ", atenuacion(4.0))


static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)
