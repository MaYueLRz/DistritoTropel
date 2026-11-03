extends CharacterBody3D

enum Estado { QUIETO, CAMINAR, CORRER, BLOQUEANDO }
const RUIDO = [0.0, 2.0, 6.0, 1.0]

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25

@onready var anim = $Modelo/AnimationPlayer

# Enchufes para los demás integrantes (NO BORRAR)
var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""

# Variables de movimiento y estado
var avance = Vector3.ZERO
var estado = Estado.QUIETO
var ruido = 0.0
var cuadro = 0

func _physics_process(delta):
	velocity += get_gravity() * delta
	
	# Entrada de teclado
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Giro horizontal corregido según la cámara
	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	# Selección de velocidad
	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar
	
	# Aceleración progresiva
	var objetivo = direction * speed * multiplicador
	var paso = (speed / tiempo_arranque) * delta
	avance = avance.move_toward(objetivo, paso)
	
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z
	
	if direction.length() > 0:
		basis = Basis.looking_at(direction)
		
	move_and_slide()
	
	# Gestión de máquina de estados
	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	
	# Imprime cuando cambia el estado
	if estado != antes:
		print("cuadro ", cuadro, " | Cambio a estado: ", Estado.keys()[estado], " | Ruido: ", ruido, " m")
		
	animar()
	_prueba()

func elegir_estado():
	if not is_on_floor():
		return Estado.QUIETO
		
	# Tecla L configurada en el Mapa de Entradas
	if Input.is_action_pressed("bloquear"):
		return Estado.BLOQUEANDO
		
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CORRER
	return Estado.CAMINAR

func animar():
	if accion != "":
		anim.play(accion)
		return
		
	match estado:
		Estado.QUIETO:
			anim.play("idle")
		Estado.CAMINAR:
			anim.play("walk")
		Estado.CORRER:
			anim.play("sprint")
		Estado.BLOQUEANDO:
			anim.play("crouch")

# Imprime en consola cuando el personaje se mueve
func _prueba():
	cuadro += 1
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez > 0.1:
		print("cuadro ", cuadro, " | rapidez: ", snapped(rapidez, 0.01), " | pos Z: ", snapped(global_position.z, 0.01), " | estado: ", Estado.keys()[estado])
