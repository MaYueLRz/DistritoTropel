extends CharacterBody3D

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25

@onready var anim = $Modelo/AnimationPlayer

# Enchufes para los demás integrantes (NO BORRAR)
var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""

# Inercia / Aceleración progresiva (Nivel 2)
var avance = Vector3.ZERO
var cuadro = 0

func _physics_process(delta):
	velocity += get_gravity() * delta
	
	# Entrada de teclado
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Giro horizontal corregido según la cámara
	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	# Selección de velocidad (Shift para correr)
	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar
	
	# Aceleración y frenado progresivo con move_toward (Nivel 2)
	var objetivo = direction * speed * multiplicador
	var paso = (speed / tiempo_arranque) * delta
	avance = avance.move_toward(objetivo, paso)
	
	# Aplicación de velocidad respetando el empuje de la Tarea B
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z
	
	if direction.length() > 0:
		basis = Basis.looking_at(direction)
		

	if accion != "":
		anim.play(accion)
	elif avance.length() > speed_caminar + 0.1:
		anim.play("sprint")
	elif avance.length() > 0.1:
		anim.play("walk")
	else:
		anim.play("idle")
		
	move_and_slide()
	_prueba()


func _prueba():
	cuadro += 1
	var rapidez = Vector2(velocity.x, velocity.z).length()
	
	if rapidez > 0.1:
		print("cuadro ", cuadro, " | rapidez: ", snapped(rapidez, 0.01), " | pos Z: ", snapped(global_position.z, 0.01), " | anim: ", anim.current_animation)
