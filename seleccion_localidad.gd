extends Control

func escoger(nombre, numero):
	$Panel/VBox/Nombre.text = nombre.to_upper()
	$Panel/VBox/Numero.text = "%02d" % int(numero)
	var juego = get_node_or_null("/root/Juego")
	if juego:
		juego.localidad = nombre

func pelear():
	get_tree().change_scene_to_file("res://main.tscn")
