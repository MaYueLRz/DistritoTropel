extends Node
# Taller 9 - Tarea C - Nicolás Daza (ndaza654)
# Nivel 1: el patrón de la CPU. Se recorre con un índice y un %.

enum Accion { ATACAR, CARGAR, DEFENDER }

@export var ritmo = 0.5            # segundos entre turnos (combo de 3 con 0.5 s)
@export var danio = 8              # daño del golpe (Documento de concepto)
@export var cuantos_turnos = 8
# 0 = ATACAR, 1 = CARGAR, 2 = DEFENDER -> combo de 3 golpes y guardia
@export var patron: Array[int] = [0, 0, 0, 2]

var indice = 0
var turno_numero = 0
var reloj = 0.0


func _ready():
	reloj = ritmo


func _physics_process(delta):
	if turno_numero >= cuantos_turnos:
		return
	reloj -= delta
	if reloj <= 0.001:
		reloj = ritmo
		jugar_turno()


func jugar_turno():
	turno_numero += 1
	var accion = patron[indice]
	indice = (indice + 1) % patron.size()
	print("turno ", turno_numero, ": ", Accion.keys()[accion])
	match accion:
		Accion.ATACAR:
			print("     ataca: ", danio, " de daño")
		Accion.CARGAR:
			print("     carga fuerzas")
		Accion.DEFENDER:
			print("     se defiende")
