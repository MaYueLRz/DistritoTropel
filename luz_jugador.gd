class_name LuzJugador
extends SpotLight3D
# Taller 4 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 3: lo que cuesta la luz y el brillo (Blinn-Phong a mano).

@export var rango := 6.0
@export var altura := 4.0
@export var con_sombra := false   # ver tabla de sombras (nivel 2)


func _ready() -> void:
	position = Vector3(0.0, altura, 0.0)
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot_range = rango
	spot_attenuation = 2.0
	shadow_enabled = con_sombra
	print(atenuacion(1.0), " ", atenuacion(2.0), " ", atenuacion(4.0))
	# Prueba de Blinn-Phong con los números de la guía:
	var n := Vector3(0.0, 1.0, 0.0)
	var l := Vector3(0.0, 1.0, 1.0)
	print(blinn_phong(n, l, Vector3(0.0, 1.0, -1.0), 32.0))   # reflejo perfecto
	print(blinn_phong(n, l, Vector3(0.0, 1.0, 0.0), 32.0))    # ojo arriba del punto


static func atenuacion(d: float, exponente: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exponente)


# Brillo de una superficie lisa: max(0, n · h)^brillo, con h el vector medio entre la luz y el ojo.
static func blinn_phong(normal: Vector3, hacia_luz: Vector3,
		hacia_ojo: Vector3, brillo: float) -> float:
	var n := normal.normalized()                       # 1. normalizar los tres vectores
	var l := hacia_luz.normalized()                    #    (si no, puede dar más de 1)
	var v := hacia_ojo.normalized()
	var h := (l + v).normalized()                      # 2. vector medio
	return pow(maxf(0.0, n.dot(h)), brillo)            # 3. max(0, n · h) elevado al brillo
