extends Control
const LUGARES ={
	"Santa fe":[
		["Torre Colpatria","res://TorreColpatria.tscn"],
		["Las Cruces",""],
		["La Media Torta",""],
	],
		"Suba":[
		["Portal Suba","res://main.tscn"],
		["Fontanar",""],
		["Coliseo Tibabuyes",""],
	],
		"Kennedy":[
		["Banderas",""],
		["Timiza",""],
		["Alcalida",""],
	],
		"Bosa":[
		["Plaza Fundacional",""],
		["Tibanica",""],
		["Porvenir",""],
	],
		"Engativa":[
		["Puente de Guada",""],
		["Ciudadela Colsubsidio",""],
		["Titan Plaza",""],
	],
		"Usaquen":[
		["Toberin",""],
		["Carrera 7",""],
		["Unicentro",""],
	],	"Barrios Unidos":[
		["Parque de los Novios",""],
		["7 de Agosto",""],
		["Caracas",""],
	],
		"San Cristobal":[
		["Juan Rey ",""],
		["Primera de Mayo",""],
		["Parque Entre Nubes",""],
	],	"Fontibon":[
		["Hayuelos",""],
		["Zona Franca",""],
		["El Recodo",""],
	],
		"Usme":[
		["Yomasa",""],
		["Danubio",""],
		["Via Al Llano",""],
	],
		"Ciudad Bolivar":[
		["Juan Pablo II",""],
		["Quiba",""],
		["Potosi",""],
	],
		"Tunjuelito":[
		["Restrepo",""],
		["Portal Tunal",""],
		["General Santander",""],
	],
		"Teusaquillo":[
		["Universidad Nacional",""],
		["Campin",""],
		["Park Way",""],
	],
		"Puente Aranda":[
		["Montevideo",""],
		["La Modelo",""],
		["Outlets de Las Américas ",""],
	],
		"Antonio Nariño":[
		["Centro Mayor",""],
		["Teatro Villa Mayor",""],
		["Rio Fucha",""],
	],
		"Rafael Uribe Uribe":[
		["Olaya",""],
		["Marruecos",""],
		["Guacamayas",""],
	],
		"Chapinero":[
		["Parque de los Hippies",""],
		["La Javeriana",""],
		["Theatron ",""],
	],
		"La Candelaria":[
		["Chorro de Quevedo",""],
		["Plaza de Bolivar",""],
		["Egipto",""],
	],
		"Los Martires":[
		["San Victorino",""],
		["De la Sabana",""],
		["Ricaurte ",""],
	],
		"Sumapaz":[
		["Laguna de Chisquia",""],
		["Betania",""],
		["San Juan de Sumapaz ",""],
	],
}
@export var canciones: Dictionary[String, AudioStream] = {}
@export var canciones_fondo: Array[AudioStream] = []
@export var volumen = -8.0

@onready var musica = $Musica
@onready var botones = [$Panel/VBox/Lugar1, $Panel/VBox/Lugar2, $Panel/VBox/Lugar3]

var lugares_actuales = []
var fondo: AudioStream


func _ready():
	# Conectar cada botón: al presionarlo llama a ir_a con su número
	for i in 3:
		botones[i].pressed.connect(ir_a.bind(i))
	mostrar_lugares([])
	if canciones_fondo.size() > 0:
		fondo = canciones_fondo.pick_random()
		poner(fondo)


func escoger(nombre, numero):
	nombre = str(nombre)
	$Panel/VBox/Nombre.text = nombre.to_upper()
	$Panel/VBox/Numero.text = "%02d" % int(numero)
	var juego = get_node_or_null("/root/Juego")
	if juego:
		juego.localidad = nombre
	mostrar_lugares(LUGARES.get(nombre, []))
	poner(canciones.get(nombre, fondo))


func mostrar_lugares(lista):
	lugares_actuales = lista
	for i in 3:
		var b = botones[i]
		var nombre = ""
		var escena = ""
		if i < lista.size():
			nombre = lista[i][0]
			escena = lista[i][1]
		var listo = escena != "" and ResourceLoader.exists(escena)
		if nombre == "":
			b.text = "PRÓXIMAMENTE"
		else:
			b.text = nombre.to_upper()
		b.disabled = not listo


func ir_a(i):
	var lugar = lugares_actuales[i]
	var juego = get_node_or_null("/root/Juego")
	if juego:
		juego.lugar = lugar[0]
	get_tree().change_scene_to_file(lugar[1])


func poner(cancion):
	if cancion == null or musica.stream == cancion:
		return
	musica.stream = cancion
	musica.volume_db = volumen
	musica.play()
