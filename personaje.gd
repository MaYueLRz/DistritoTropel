extends Character

enum Estado { QUIETO, CAMINAR, CORRER, BLOQUEANDO }
const RUIDO = [0.0, 2.0, 6.0, 1.0]

enum Prueba { NINGUNA, AVANZAR_60_CUADROS, MANTENER_ACCION_2S }

@export var prueba: Prueba = Prueba.NINGUNA
@export var accion_prueba = ""

var cuadros_prueba = 0

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25

@onready var anim = $Modelo/AnimationPlayer


var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""

var avance = Vector3.ZERO
var estado = Estado.QUIETO
var ruido = 0.0
var cuadro = 0

func _physics_process(delta):
	velocity += get_gravity() * delta
	

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	
	cuadros_prueba += 1
	if prueba == Prueba.AVANZAR_60_CUADROS and cuadros_prueba <= 60:
		direction = Vector3(0, 0, -1)
	elif prueba == Prueba.MANTENER_ACCION_2S and accion_prueba != "":
		if cuadros_prueba <= 120:
			Input.action_press(accion_prueba)
		elif cuadros_prueba == 121:
			Input.action_release(accion_prueba)
	

	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar
	

	var objetivo = direction * speed * multiplicador
	var paso = (speed / tiempo_arranque) * delta
	avance = avance.move_toward(objetivo, paso)
	
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z
	
	if direction.length() > 0:
		basis = Basis.looking_at(direction)
		
	move_and_slide()
	
	
	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
		
	animar()

func elegir_estado():
	if not is_on_floor():
		return Estado.QUIETO
		

		
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
