extends Node

@export var cuadros = 60
@export var direccion = Vector3(0, 0, -3)

@onready var pj = get_parent()

var restan = 0


func _ready():
	restan = cuadros


func _physics_process(_delta):
	if restan > 0:
		restan -= 1
		pj.empuje = direccion
	else:
		pj.empuje = Vector3.ZERO
