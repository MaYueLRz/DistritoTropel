class_name EmbersetShield
extends EmbersetEffect
## Root of the Emberset shield scenes. Works like any other effect, plus [method hit]:
## [code]shield.hit(collision_point)[/code] sends a ripple across the surface from that point.

## Seconds a ripple takes to cross the shield.
@export_range(0.1, 3.0) var ripple_time := 0.6

const SLOTS := 4

var _shells: Array[MeshInstance3D] = []
var _points: Array[Vector3] = []
var _ages: Array[float] = []


func _ready() -> void:
	super()
	for m in _meshes:
		var mat := m.material_override as ShaderMaterial
		if mat and mat.shader and mat.shader.get_shader_uniform_list().any(func(u: Dictionary) -> bool: return u.name == "hits"):
			_shells.append(m)
	for i in SLOTS:
		_points.append(Vector3.ZERO)
		_ages.append(0.0)


## Starts a ripple at a point given in world space. Up to four ripples run at once; a fifth replaces the oldest.
func hit(world_position: Vector3) -> void:
	var slot := 0
	for i in SLOTS:
		if _ages[i] <= 0.0:
			slot = i
			break
		if _ages[i] > _ages[slot]:
			slot = i
	_points[slot] = world_position
	_ages[slot] = 0.001
	_push()


func _process(delta: float) -> void:
	super(delta)
	var live := false
	for i in SLOTS:
		if _ages[i] > 0.0:
			live = true
			_ages[i] += delta * speed_scale / ripple_time
			if _ages[i] >= 1.0:
				_ages[i] = 0.0
	if live:
		_push()


# The shader wants each hit in the shell's own space, with the age in w (0 = unused).
func _push() -> void:
	for shell in _shells:
		var packed := PackedVector4Array()
		for i in SLOTS:
			var p := shell.to_local(_points[i])
			packed.append(Vector4(p.x, p.y, p.z, _ages[i]))
		(shell.material_override as ShaderMaterial).set_shader_parameter("hits", packed)
