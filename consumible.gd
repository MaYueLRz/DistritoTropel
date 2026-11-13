extends Area3D

signal recogido(tipo)

@export var tipo = "mieltertos"


func _ready():
	add_to_group("objetivos")
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	var inv = cuerpo.get_node_or_null("Inventario")
	if inv == null:
		return
	if not inv.guardar(tipo):
		print(name, " no cabe: ya llevas 2")
		return
	recogido.emit(tipo)
	queue_free()
