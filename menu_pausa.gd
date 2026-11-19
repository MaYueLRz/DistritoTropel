extends CanvasLayer

const CONSEJOS = [
	"No dé papaya.",
	"El que se arrima a la baranda, se lo lleva el articulado.",
	"Primero se mira, después se tira.",
	"Bloquear también es de varones.",
]

@onready var consejos = $Fondo/Consejos
@onready var boton_reanudar = $Fondo/Centro/Letrero/VBox/BotonReanudar


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for boton in $Fondo/Centro/Letrero/VBox.get_children():
		if boton is Button:
			# 1. Usar el estilo Normal en todos los estados
			var estilo = boton.get_theme_stylebox("normal")
			for estado in ["hover", "pressed", "hover_pressed", "disabled"]:
				boton.add_theme_stylebox_override(estado, estilo)
			boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			# 2. Usar el mismo color de letra en todos los estados
			var color = boton.get_theme_color("font_color")
			for c in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
				boton.add_theme_color_override(c, color)
			# 3. Animación al señalarlo
			boton.focus_entered.connect(_resaltar.bind(boton, true))
			boton.focus_exited.connect(_resaltar.bind(boton, false))
			boton.mouse_entered.connect(boton.grab_focus)


func _unhandled_input(event):
	if event.is_action_pressed("pausa"):
		alternar()
		get_viewport().set_input_as_handled()


func alternar():
	var pausar = not get_tree().paused
	get_tree().paused = pausar
	visible = pausar
	if pausar:
		consejos.text = CONSEJOS.pick_random()
		boton_reanudar.grab_focus()


func _resaltar(boton, activo):
	boton.pivot_offset = boton.size / 2
	var t = create_tween().set_parallel()
	t.tween_property(boton, "scale", Vector2(1.06, 1.06) if activo else Vector2.ONE, 0.12)
	t.tween_property(boton, "modulate", Color(1.12, 1.12, 1.12) if activo else Color.WHITE, 0.12)


func _on_boton_reanudar_pressed():
	alternar()


func _on_boton_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_boton_localidad_pressed():
	print("Aquí irá la selección de localidad")


func _on_boton_salir_pressed():
	get_tree().quit()
