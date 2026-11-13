extends Character

@export var color_golpe = Color("#C1121F")
@export var tiempo_destello = 0.2
@export var empuje_golpe = 3.0

@onready var anim = $Modelo.get_node_or_null("AnimationPlayer")

var jugador = null
var mallas = []
var reloj_destello = 0.0


func _ready():
	add_to_group("enemigo")
	jugador = get_tree().get_first_node_in_group("jugador")
	mallas = $Modelo.find_children("*", "MeshInstance3D", true, false)


func _physics_process(delta):
	velocity += get_gravity() * delta
	mirar_al_jugador()
	move_and_slide()

	if reloj_destello > 0.0:
		reloj_destello -= delta
		if reloj_destello <= 0.0:
			pintar(null)


func recibir_danio(cantidad):
	super(cantidad)
	if vida > 0:
		destellar()
		reaccionar()


func morir():
	super()
	pintar(null)
	visible = false


func reaccionar():
	if anim != null and anim.has_animation("Reaction/mixamo_com"):
		anim.play("Reaction/mixamo_com")
	if jugador == null:
		return
	var lejos = global_position - jugador.global_position
	lejos.y = 0.0
	velocity += lejos.normalized() * empuje_golpe


func destellar():
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color_golpe.r, color_golpe.g, color_golpe.b, 0.6)
	pintar(mat)
	reloj_destello = tiempo_destello


func pintar(mat):
	for m in mallas:
		m.material_overlay = mat


func mirar_al_jugador():
	if jugador == null:
		return
	var hacia = jugador.global_position - global_position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		basis = Basis.looking_at(hacia.normalized())
