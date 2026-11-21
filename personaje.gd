extends Character

enum Estado { QUIETO, CAMINAR, CORRER, BLOQUEANDO }
enum Rumbo { ADELANTE, ATRAS, LADO }
const RUIDO = [0.0, 2.0, 6.0, 1.0]
@export var velocidad_anim: Array[float] = [1.0, 1.2, 1.5]
@onready var escudo = get_node_or_null("Escudo")

enum Prueba { NINGUNA, AVANZAR_60_CUADROS, MANTENER_ACCION_2S }

@export var prueba: Prueba = Prueba.NINGUNA
@export var accion_prueba = ""
@export var mirar_al_rival = true


var cuadros_prueba = 0

@export var camara: Camera3D
@export var speed_caminar = 3.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25
@export var sufijo = ""

@onready var anim = $Modelo/AnimationPlayer
@export var animacion_dano = "Reaction/mixamo_com"
@export var cuadros_reaccion = 18
var reloj_reaccion = 0
@export var animacion_bloqueo = "Bloqueo/mixamo_com"
@export var pose_bloqueo = 1.3  
var bloqueando = false


var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
@export var rival: Node3D
@export var color_golpe = Color("#C1121F")
@export var tiempo_destello = 0.18
@export var frenado_empuje = 14.0

var mallas = []
var reloj_destello = 0.0


var avance = Vector3.ZERO
var estado = Estado.QUIETO
var ruido = 0.0
var cuadro = 0
var rumbo = Rumbo.ADELANTE

@export var reduccion_bloqueo = 0.2      
@export var empuje_bloqueado = 0.25     
@export var cuadros_guardia_rota = 24

var reloj_guardia_rota = 0

func _ready():
	mallas = $Modelo.find_children("*", "MeshInstance3D", true, false)
	if sufijo == "":
		return
	$Golpe.tecla += sufijo
	$Inventario.tecla_1 += sufijo
	$Inventario.tecla_2 += sufijo

func _physics_process(delta):
	velocity += get_gravity() * delta
	

	var input_dir = Input.get_vector(
		"move_left" + sufijo, "move_right" + sufijo,
		"move_up" + sufijo, "move_down" + sufijo)
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	


	var giro_cam = camara.global_rotation.y if camara else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	var golpeando = $Golpe.esta_golpeando
	if golpeando:
		direction = Vector3.ZERO
	if reloj_guardia_rota > 0:
		reloj_guardia_rota -= 1

	var quiere_bloquear = Input.is_action_pressed("bloquear" + sufijo) \
		and not golpeando and is_on_floor() and reloj_guardia_rota == 0

	if quiere_bloquear != bloqueando:
		bloqueando = quiere_bloquear
		if escudo != null:
			if bloqueando:
				escudo.play()
			else:
				escudo.stop()

	if bloqueando:
		direction = Vector3.ZERO
	
	cuadros_prueba += 1
	if prueba == Prueba.AVANZAR_60_CUADROS and cuadros_prueba <= 60:
		direction = Vector3(0, 0, -1)
	elif prueba == Prueba.MANTENER_ACCION_2S and accion_prueba != "":
		if cuadros_prueba <= 120:
			Input.action_press(accion_prueba)
		elif cuadros_prueba == 121:
			Input.action_release(accion_prueba)
	

	var corre = Input.is_action_pressed("correr" + sufijo)
	var speed = speed_correr if corre else speed_caminar
	

	var objetivo = direction * speed * multiplicador
	var paso = (speed / tiempo_arranque) * delta
	avance = avance.move_toward(objetivo, paso)
	
	empuje = empuje.move_toward(Vector3.ZERO, frenado_empuje * delta)

	if reloj_destello > 0.0:
		reloj_destello -= delta
		if reloj_destello <= 0.0:
			pintar(null)
	if reloj_reaccion > 0:
		reloj_reaccion -= 1

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
	if reloj_reaccion > 0:
		return
	if bloqueando:
		if anim.has_animation(animacion_bloqueo):
			anim.speed_scale = 1.0
			anim.play(animacion_bloqueo)
			anim.seek(pose_bloqueo, true)
		return
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
			
func recibir_danio(cantidad):
	$Salud.recibir_golpe(cantidad)
	destellar()
	reloj_reaccion = cuadros_reaccion
	if anim.has_animation(animacion_dano):
		anim.speed_scale = 1.0
		anim.play(animacion_dano)
		anim.seek(0.0, true)


func recibir_empuje(fuerza):
	empuje += fuerza


func destellar():
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color_golpe.r, color_golpe.g, color_golpe.b, 0.6)
	pintar(mat)
	reloj_destello = tiempo_destello


func pintar(mat):
	for m in mallas:
		m.material_overlay = mat

func recibir_golpe(cantidad, fuerza_empuje, imparable, desde, punto):
	var parado = bloqueando and not imparable

	if parado:
		cantidad = maxi(int(cantidad * reduccion_bloqueo), 1)
		fuerza_empuje *= empuje_bloqueado
		if escudo != null and escudo.has_method("hit"):
			escudo.hit(punto)
	else:
		if bloqueando:
			romper_guardia()
		destellar()
		reloj_reaccion = cuadros_reaccion
		if anim.has_animation(animacion_dano):
			anim.speed_scale = 1.0
			anim.play(animacion_dano)
			anim.seek(0.0, true)

	$Salud.recibir_golpe(cantidad)

	if fuerza_empuje > 0.0:
		var lejos = global_position - desde
		lejos.y = 0.0
		if lejos.length() > 0.01:
			empuje += lejos.normalized() * fuerza_empuje


func romper_guardia():
	bloqueando = false
	reloj_guardia_rota = cuadros_guardia_rota
	if escudo != null:
		escudo.stop()
