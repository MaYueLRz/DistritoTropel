class_name LuzJugador
extends SpotLight3D
# Taller 4 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 1: el foco de ring que acompaña al luchador del jugador (SpotLight3D blanca hacia abajo).

@export var rango := 6.0           # m: hasta dónde alumbra (el foco está a 4 m del piso)
@export var altura := 4.0          # m sobre los pies del jugador


func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)       # hija del jugador: se mueve con él
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # un SpotLight3D alumbra hacia su -Z: -90° en X = hacia abajo
	spot_range = rango                           # en un OmniLight3D sería omni_range
	spot_attenuation = 2.0                       # la que se parece a 1/d²
	print(atenuacion(1.0), " ", atenuacion(2.0), " ", atenuacion(4.0))


# Función pura: cuánta luz llega a la distancia d si a 1 m llega 1.
static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)
