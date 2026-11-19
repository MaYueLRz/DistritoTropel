extends CanvasLayer
const CONSEJOS = [
	"No dé papaya.",
	"El que se arrima a la baranda, se lo lleva el articulado.",
	"Primero se mira, después se tira.",
	"Bloquear también es de varones.",
]
@onready var consejos = $Fondo/Centro/Letrero/VBox/Consejos
@onready var boton_reanudar =$Fondo/Centro/Letrero/VBox/BotonReanudar
# Called when the node enters the scene tree for the first time.
func _ready() :
	process_mode=Node.PROCESS_MODE_ALWAYS
	visible = false
func _unhandled_input(event):
	if event.is_action_pressed("pausa"):
		alternar()
		get_viewport().set_input_as_handled()
func alternar():
	var pausar = not get_tree().paused
	get_tree().paused= pausar
	visible=pausar
	if pausar:
		consejos.text = CONSEJOS.pick_random()
		boton_reanudar.grab_focus()




func _on_boton_reanudar_pressed() :
	alternar()


func _on_boton_reiniciar_pressed() -> void:
	get_tree().paused=false
	get_tree().reload_current_scene()
	


func _on_boton_salir_pressed() -> void:
	get_tree().quit()
