extends Character

enum Estado { QUIETO, CAMINAR, CORRER, BLOQUEANDO }
enum Rumbo { ADELANTE, ATRAS, LADO }
const RUIDO = [0.0, 2.0, 6.0, 1.0]
@export var velocidad_anim: Array[float] = [1.0, 1.2, 1.5]

enum Prueba { NINGUNA, AVANZAR_60_CUADROS, MANTENER_ACCION_2S }

@export var prueba: Prueba = Prueba.NINGUNA
@export var accion_prueba = ""
@export var mirar_al_rival = true

var cuadros_prueba = 0

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25

@onready var anim = $Modelo/AnimationPlayer


var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
var rival = null

var avance = Vector3.ZERO
var estado = Estado.QUIETO
var ruido = 0.0
var cuadro = 0
var rumbo = Rumbo.ADELANTE

func _physics_process(delta):
	velocity += get_gravity() * delta
	

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	var golpeando = $Golpe.esta_golpeando
	if golpeando:
		direction = Vector3.ZERO
	
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

	if rival == null:
		rival = get_tree().get_first_node_in_group("enemigo")

	if mirar_al_rival and rival != null and (golpeando or not corre):
		var hacia = rival.global_position - global_position
		hacia.y = 0.0
		if hacia.length() > 0.05:
			basis = Basis.looking_at(hacia.normalized())
	elif direction.length() > 0:
		basis = Basis.looking_at(direction)

	rumbo = Rumbo.ADELANTE
	if direction.length() > 0.1:
		var de_frente = direction.dot(-basis.z)
		var de_lado = direction.dot(basis.x)
		if absf(de_lado) > absf(de_frente):
			rumbo = Rumbo.LADO
		elif de_frente < 0.0:
			rumbo = Rumbo.ATRAS

	move_and_slide()
	
	

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
			anim.speed_scale = 1.0
			anim.play("Idile/mixamo_com")
		Estado.CAMINAR:
			anim.speed_scale = velocidad_anim[rumbo]
			match rumbo:
				Rumbo.ATRAS:
					anim.play("CaminataTrasera/mixamo_com")
				Rumbo.LADO:
					anim.play("Lateral/mixamo_com")
				_:
					anim.play("Walk/mixamo_com")
		Estado.CORRER:
			anim.speed_scale = 1.0
			anim.play("Sprint/mixamo_com")
