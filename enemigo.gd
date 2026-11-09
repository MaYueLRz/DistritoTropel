extends Character


func _ready():
	add_to_group("enemigo")


func _physics_process(delta):
	# Sin IA: no se mueve ni ataca, solo cae al suelo.
	velocity += get_gravity() * delta
	move_and_slide()

	# Prueba temporal: Enter le quita vida.
	# Borrar cuando esté la hitbox (jueves 12).
	if Input.is_action_just_pressed("ui_accept"):
		recibir_danio(8)
