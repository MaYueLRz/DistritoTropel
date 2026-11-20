extends Node
# Entrega20 - animación de muerte de los jugadores (usa Dying.fbx, la misma del enemigo).
# Un solo nodo hijo de Main. Cuando a un jugador se le acaba la vida (Salud.cambio con 0)
# aparece un cuerpo que cae donde murió y el jugador de verdad se oculta y se congela.
# Si todavía le quedan reapariciones, reaparece en el punto de inicio cuando el cuerpo termina
# de caer. Si era la última vida, sigue oculto y el cuerpo cae aunque la partida esté en pausa.

@export var libreria = "res://Animaciones y Personajes/Dying.fbx"
@export var animacion = "Muerte/mixamo_com"
@export var velocidad = 1.5          # 1.0 es la velocidad original (4,4 s); más alto, cae más rápido
@export var tiempo_en_piso = 1.0     # segundos tendido después de caer, antes de reaparecer o reiniciar
@export var gracia = 1.0             # segundos sin recibir daño al reaparecer, además de los de Salud
@export var avisar = false           # true imprime cada muerte en la Salida

# Nodos del jugador que leen la entrada o mueven al personaje (todos en _physics_process).
const CONTROLES = ["Golpe", "Inventario", "Interactuar"]

var jugadores = []
var vidas = {}
var biblioteca = null


func _ready():
	if ResourceLoader.exists(libreria):
		biblioteca = load(libreria)
	call_deferred("conectar")


func conectar():
	for grupo in ["jugador1", "jugador2"]:
		for pj in get_tree().get_nodes_in_group(grupo):
			if pj in jugadores:
				continue
			jugadores.append(pj)
			var salud = pj.get_node_or_null("Salud")
			if salud != null:
				vidas[salud] = salud.vida
				salud.cambio.connect(_al_cambiar_salud.bind(salud, pj))


# cambio(0) sale antes que sin_vida, o sea antes de que Salud lo mande al punto de inicio.
func _al_cambiar_salud(vida, salud, pj):
	var antes = vidas.get(salud, vida)
	vidas[salud] = vida
	if vida == 0 and antes > 0:
		caer(pj, salud, salud.reapariciones <= 0)


func caer(pj, salud, definitiva):
	var modelo = pj.get_node_or_null("Modelo")
	if modelo == null or biblioteca == null or modelo.scene_file_path == "":
		return
	var cuerpo = load(modelo.scene_file_path).instantiate()
	get_parent().add_child(cuerpo)
	cuerpo.global_transform = modelo.global_transform
	cuerpo.process_mode = Node.PROCESS_MODE_ALWAYS     # sigue animándose con la partida en pausa

	var ap = cuerpo.get_node_or_null("AnimationPlayer")
	if ap == null:
		cuerpo.queue_free()
		return
	if not ap.has_animation_library("Muerte"):
		ap.add_animation_library("Muerte", biblioteca)
	var caida = 0.0
	if ap.has_animation(animacion):
		ap.get_animation(animacion).loop_mode = Animation.LOOP_NONE
		ap.play(animacion, -1.0, velocidad)
		ap.advance(0.0)
		caida = ap.get_animation(animacion).length / velocidad
	if avisar:
		print("muerte de ", pj.name, " · última vida ", definitiva, " · cae en ", snappedf(caida, 0.1), " s · cuadro ", Engine.get_physics_frames())

	# El jugador de verdad no se ve mientras cae el cuerpo (si no, se ven dos).
	modelo.visible = false
	if definitiva:
		call_deferred("alargar_espera", caida + tiempo_en_piso)
	else:
		congelar(pj, true)
		get_tree().create_timer(caida + tiempo_en_piso).timeout.connect(reaparecer.bind(pj, salud, cuerpo))


func reaparecer(pj, salud, cuerpo):
	if is_instance_valid(cuerpo):
		cuerpo.queue_free()
	if not is_instance_valid(pj):
		return
	pj.get_node("Modelo").visible = true
	congelar(pj, false)
	salud.reloj = maxf(salud.reloj, gracia)
	if avisar:
		print("reaparece ", pj.name, " cuadro ", Engine.get_physics_frames())


# Mientras está congelado no se mueve, no pega, no recibe golpes y no estorba.
func congelar(pj, si):
	pj.set_physics_process(not si)
	for nombre in CONTROLES:
		var nodo = pj.get_node_or_null(nombre)
		if nodo != null:
			nodo.set_physics_process(not si)
	var hurtbox = pj.get_node_or_null("Hurtbox")
	if hurtbox != null:
		hurtbox.set_deferred("monitorable", not si)
	var cuerpo_fisico = pj.get_node_or_null("CollisionShape3D")
	if cuerpo_fisico != null:
		cuerpo_fisico.set_deferred("disabled", si)
	if si:
		pj.velocity = Vector3.ZERO
		var hitbox = pj.get_node_or_null("Hitbox")
		if hitbox != null:
			hitbox.apagar()


# partida pone su espera cuando termina (después de este aviso), por eso se ajusta al final del cuadro.
func alargar_espera(segundos):
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and partida.estado != 0:
		partida.reloj = maxf(partida.reloj, segundos)
