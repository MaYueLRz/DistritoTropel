extends Character


func _ready():
	pass


func _physics_process(delta):
	velocity += get_gravity() * delta
	move_and_slide()
