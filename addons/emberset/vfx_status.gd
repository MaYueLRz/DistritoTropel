class_name EmbersetStatus
extends EmbersetEffect
## Root of the Emberset status scenes (burning, frozen, poisoned ...). Put the scene on a character
## like any other effect; [method attach] also lays the matching overlay material over the
## character's mesh for as long as the effect plays.

## Material for the target's Material Overlay slot. Its colours follow hue_shift and tint.
@export var overlay: ShaderMaterial
## Seconds the overlay takes to appear and to clear.
@export_range(0.0, 3.0) var overlay_fade := 0.35

var _targets: Array[GeometryInstance3D] = []
var _coat: ShaderMaterial
var _coat_tween: Tween


## Puts the overlay on a mesh (call it once per mesh of the character). It fades in now if the
## effect is playing, fades out on stop() and is taken off again when the effect leaves the tree.
func attach(target: GeometryInstance3D) -> void:
	if overlay == null:
		return
	if _coat == null:
		_coat = overlay.duplicate()
		for u in _coat.shader.get_shader_uniform_list():
			var v: Variant = _coat.get_shader_parameter(u.name)
			if v is Color:
				_coat.set_shader_parameter(u.name, _shift(v, true))
		_coat.set_shader_parameter("fade", 0.0)
	target.material_overlay = _coat
	_targets.append(target)
	if playing and not _ending:
		_coat_to(1.0)


## Takes the overlay off every mesh it was attached to.
func detach() -> void:
	for t in _targets:
		if is_instance_valid(t) and t.material_overlay == _coat:
			t.material_overlay = null
	_targets.clear()


func play() -> void:
	super()
	_coat_to(1.0)


func stop() -> void:
	super()
	_coat_to(0.0)


func _exit_tree() -> void:
	detach()


func _coat_to(value: float) -> void:
	if _coat == null:
		return
	if _coat_tween:
		_coat_tween.kill()
	_coat_tween = create_tween()
	var from: float = _coat.get_shader_parameter("fade")
	_coat_tween.tween_method(func(v: float) -> void: _coat.set_shader_parameter("fade", v), from, value,
		maxf(overlay_fade / speed_scale, 0.01))
