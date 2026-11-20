extends Node
# Entrega20 - destello rojo en los jugadores cuando reciben daño (igual al del enemigo).
# Un solo nodo hijo de Main: escucha la señal cambio de la Salud de cada jugador,
# así no hay que tocar personaje.gd ni salud.gd.

@export var color_golpe = Color("#C1121F")   # el mismo rojo de enemigo.gd
@export var opacidad = 0.6
@export var tiempo_destello = 0.2
@export var avisar = false                  # true imprime cada destello en la Salida

var jugadores = []
var mallas = {}
var vidas = {}
var relojes = {}
var material = null


func _ready():
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color_golpe.r, color_golpe.g, color_golpe.b, opacidad)
	call_deferred("conectar")


func _physics_process(delta):
	# Con el hitstop (time_scale 0) delta vale 0 y el destello espera, igual que en el enemigo.
	for pj in relojes.keys():
		relojes[pj] -= delta
		if relojes[pj] <= 0.0:
			pintar(pj, null)
			relojes.erase(pj)


func conectar():
	for grupo in ["jugador1", "jugador2"]:
		for pj in get_tree().get_nodes_in_group(grupo):
			if pj in jugadores:
				continue
			jugadores.append(pj)
			var modelo = pj.get_node_or_null("Modelo")
			if modelo != null:
				mallas[pj] = modelo.find_children("*", "MeshInstance3D", true, false)
			else:
				mallas[pj] = []
			var salud = pj.get_node_or_null("Salud")
			if salud != null:
				vidas[salud] = salud.vida
				salud.cambio.connect(_al_cambiar_salud.bind(salud, pj))
	if avisar:
		print("destello: jugadores ", jugadores.size())


func _al_cambiar_salud(vida, salud, pj):
	var antes = vidas.get(salud, vida)
	vidas[salud] = vida
	# Solo cuando baja: al reaparecer la vida sube y no debe destellar.
	if vida < antes:
		destellar(pj)


func destellar(pj):
	pintar(pj, material)
	relojes[pj] = tiempo_destello
	if avisar:
		print("destello en ", pj.name, " cuadro ", Engine.get_physics_frames())


func pintar(pj, mat):
	if not is_instance_valid(pj):
		return
	for m in mallas[pj]:
		m.material_overlay = mat
