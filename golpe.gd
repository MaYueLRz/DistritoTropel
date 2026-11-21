extends Node

enum Estado { LISTA, WINDUP, ACTIVE, RECOVERY }

@export var tecla = "golpe"


@export var animaciones: Array[String] = [
	"Golpe/mixamo_com",
	"Golpe2/mixamo_com",
	"Patada/mixamo_com",
]
@export var cuadros_windup: Array[int] = [12, 12, 20]
@export var cuadros_active: Array[int] = [6, 6, 6]
@export var cuadros_recovery: Array[int] = [16, 16, 34]
@export var empujes: Array[float] = [0.0, 0.0, 7]

@export var alcances: Array[float] = [0.90, 0.95, 1.25]
@export var alturas: Array[float] = [1.15, 1.15, 0.85]
@export var radios: Array[float] = [0.4, 0.4, 0.4]

@export var fuerzas: Array[float] = [1.0, 1.0, 2.0]

@export var rompe_guardia: Array[bool] = [false, false, true]

# Cuadros para encadenar el siguiente golpe antes de que el combo se caiga.
@export var ventana = 22

@onready var pj = get_parent()
@onready var anim = pj.get_node("Modelo/AnimationPlayer")
@onready var hitbox = pj.get_node("Hitbox")

var estado = Estado.LISTA
var cuadros = 0
var paso = 0
var reloj_ventana = 0
var guardado = false
var esta_golpeando = false


func _physics_process(_delta):
	match estado:
		Estado.LISTA:
			if reloj_ventana > 0:
				reloj_ventana -= 1
				if reloj_ventana == 0:
					paso = 0
					print("combo perdido, vuelve al golpe 1")
			if guardado or Input.is_action_just_pressed(tecla):
				cambiar_a(Estado.WINDUP)
		Estado.WINDUP:
			cuadros -= 1
			if cuadros <= 0:
				cambiar_a(Estado.ACTIVE)
		Estado.ACTIVE:
			cuadros -= 1
			if cuadros <= 0:
				cambiar_a(Estado.RECOVERY)
		Estado.RECOVERY:
			cuadros -= 1
			if Input.is_action_just_pressed(tecla):
				guardado = true
			if cuadros <= 0:
				cambiar_a(Estado.LISTA)


func cambiar_a(nuevo):
	estado = nuevo
	match estado:
		Estado.WINDUP:
			guardado = false
			reloj_ventana = 0
			esta_golpeando = true
			cuadros = cuadros_windup[paso]
			hitbox.configurar(alcances[paso], alturas[paso], radios[paso],
				fuerzas[paso], rompe_guardia[paso])
			var pista = animaciones[paso]
			if anim.has_animation(pista):
				ajustar_velocidad(pista)
				pj.accion = pista
			else:
				print("ojo: no existe la animación ", pista)
			print("golpe ", paso + 1, " de ", animaciones.size(),
				" -> WINDUP cuadro ", Engine.get_physics_frames())

			return
		Estado.ACTIVE:
			cuadros = cuadros_active[paso]
			hitbox.encender(empujes[paso])
		Estado.RECOVERY:
			cuadros = cuadros_recovery[paso]
			hitbox.apagar()
		Estado.LISTA:
			cuadros = 0
			esta_golpeando = false
			pj.accion = ""
			anim.speed_scale = 1.0
			paso += 1
			if paso >= animaciones.size():
				paso = 0
				reloj_ventana = 0
			else:
				reloj_ventana = ventana
	print("golpe -> ", Estado.keys()[estado], " cuadro ", Engine.get_physics_frames())


func ajustar_velocidad(pista):
	var animacion = anim.get_animation(pista)
	if animacion == null:
		return
	var total = cuadros_windup[paso] + cuadros_active[paso] + cuadros_recovery[paso]
	anim.speed_scale = animacion.length / (total / 60.0)
