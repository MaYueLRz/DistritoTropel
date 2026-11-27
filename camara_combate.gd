extends Camera3D

# --- Encuadre normal ---
@export var distancia_min = 4.0
@export var distancia_max = 20.0
@export var margen = 2.5            # espacio a los lados de los jugadores
@export var altura = 3.2            # más arriba, como en Naruto
@export var altura_mirada = 0.9
@export var angulo = 10.0
@export var suavidad = 4.0
@export var fov_base = 60.0

# --- Arena ---
@export var centro_arena = Vector3.ZERO
@export var radio_arena = 1000.0    # 1000 = sin límite; luego lo ajustamos
@export var subir_por_metro = 0.8

# --- Cuando alguien pega ---
@export var tiempo_foco = 1.2       # segundos que la cámara favorece al que pega
@export var giro_foco = 0.4         # qué tanto se va detrás del que pega (0 a 1)
@export var zoom_foco = 0.75        # se acerca a este porcentaje
@export var fuerza_temblor = 0.35
@export var pausa_golpe = 0.06      # congelada del golpe, en segundos

var j1
var j2
var lado = Vector3.ZERO
var mirada = Vector3.ZERO
var direccion = Vector3.ZERO        # hacia dónde está la cámara ahora (suave)
var atacante = null
var reloj_foco = 0.0
var temblor = 0.0


func _ready():
	current = true
	fov = fov_base
	j1 = get_tree().get_first_node_in_group("jugador1")
	j2 = get_tree().get_first_node_in_group("jugador2")
	if j1 and j2:
		print("J1 = ", j1.name, "   J2 = ", j2.name)
		lado = calcular_lado()
		direccion = direccion_deseada()
		mirada = punto_medio()
		global_position = destino()


func _physics_process(delta):
	if j1 == null or j2 == null:
		return
	lado = calcular_lado()
	reloj_foco = max(reloj_foco - delta, 0.0)
	var trazo = 1.0 - exp(-suavidad * delta)

	direccion = direccion.lerp(direccion_deseada(), trazo)
	if direccion.length() < 0.01:
		direccion = direccion_deseada()
	direccion = direccion.normalized()

	global_position = global_position.lerp(destino(), trazo)
	mirada = mirada.lerp(punto_medio(), trazo)
	look_at(mirada + Vector3.UP * altura_mirada)

	# Temblor: mueve la imagen sin mover la cámara de verdad
	temblor = move_toward(temblor, 0.0, delta * 2.5)
	var fuerza = temblor * temblor
	h_offset = randf_range(-1, 1) * fuerza * fuerza_temblor
	v_offset = randf_range(-1, 1) * fuerza * fuerza_temblor
	fov = lerpf(fov, fov_base, trazo)


func punto_medio():
	return (j1.global_position + j2.global_position) / 2


func separacion():
	var a = j1.global_position
	var b = j2.global_position
	a.y = 0
	b.y = 0
	return a.distance_to(b)


func calcular_lado():
	var linea = j2.global_position - j1.global_position
	linea.y = 0
	if linea.length() < 0.1:
		return lado
	var nuevo = linea.normalized().cross(Vector3.UP)
	var hacia_camara = global_position - punto_medio()
	hacia_camara.y = 0
	if nuevo.dot(hacia_camara) < 0:
		nuevo = -nuevo
	return nuevo


# De lado normalmente; detrás del que pega cuando hay golpe
func direccion_deseada():
	var d = lado.rotated(Vector3.UP, deg_to_rad(angulo))
	if reloj_foco > 0.0 and atacante:
		var victima = j2 if atacante == j1 else j1
		var atras = atacante.global_position - victima.global_position
		atras.y = 0
		if atras.length() > 0.1:
			d = d.lerp(atras.normalized(), giro_foco).normalized()
	return d


func distancia_necesaria():
	var pantalla = get_viewport().get_visible_rect().size
	var aspecto = pantalla.x / pantalla.y
	var fov_horizontal = 2.0 * atan(tan(deg_to_rad(fov_base) / 2.0) * aspecto)
	var mitad = separacion() / 2.0 + margen
	return clamp(mitad / tan(fov_horizontal / 2.0), distancia_min, distancia_max)


func destino():
	var dist = distancia_necesaria()
	if reloj_foco > 0.0:
		dist = max(dist * zoom_foco, distancia_min)
	var pos = punto_medio() + direccion * dist
	var extra = 0.0

	var desde_centro = pos - centro_arena
	desde_centro.y = 0
	if desde_centro.length() > radio_arena:
		extra = (desde_centro.length() - radio_arena) * subir_por_metro
		desde_centro = desde_centro.normalized() * radio_arena
		pos.x = centro_arena.x + desde_centro.x
		pos.z = centro_arena.z + desde_centro.z

	pos.y = punto_medio().y + altura + extra
	return pos


# --- Esto lo llama el personaje cuando recibe un golpe ---
func impacto(victima, bloqueado = false):
	atacante = j2 if victima == j1 else j1
	reloj_foco = tiempo_foco
	if bloqueado:
		temblor = max(temblor, 0.4)    # bloqueo: tiembla poquito
	else:
		temblor = 1.0                  # golpe limpio: temblor fuerte,
		fov = fov_base - 5.0           # zoom rapidito
		congelar()                     # y congelada


func congelar():
	Engine.time_scale = 0.05
	await get_tree().create_timer(pausa_golpe, true, false, true).timeout
	Engine.time_scale = 1.0
