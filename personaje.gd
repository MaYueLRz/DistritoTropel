extends CharacterBody3D

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0

@onready var anim = $Modelo/AnimationPlayer

# Enchufes para los demás integrantes (NO BORRAR)
var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""

var cuadro = 0

func _physics_process(delta):
	velocity += get_gravity() * delta
	
	# Entrada de teclado
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Giro horizontal corregido según la cámara
	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	# Acción de correr con Shift
	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar
	
	# Aplicación de velocidad con multiplicador y empuje
	velocity.x = direction.x * speed * multiplicador + empuje.x
	velocity.z = direction.z * speed * multiplicador + empuje.z
	
	if direction.length() > 0:
		basis = Basis.looking_at(direction)
		
	# Animaciones del Nivel 1
	if accion != "":
		anim.play(accion)
	elif direction.length() > 0 and corre:
		anim.play("sprint")
	elif direction.length() > 0:
		anim.play("walk")
	else:
		anim.play("idle")
		
	move_and_slide()
	_prueba()

# Imprime en consola CADA VEZ que el personaje se esté moviendo
func _prueba():
	cuadro += 1
	var rapidez = Vector2(velocity.x, velocity.z).length()
	
	if rapidez > 0.1:
		print("cuadro ", cuadro, " | rapidez: ", snapped(rapidez, 0.01), " | pos Z: ", snapped(global_position.z, 0.01), " | anim: ", anim.current_animation)
