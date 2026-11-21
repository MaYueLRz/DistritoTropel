class_name EmbersetEffect
extends Node3D
## Root of every Emberset effect scene.
##
## Drop a scene from addons/emberset/effects into your level and it plays.
## From code: [code]var fx = preload("...tscn").instantiate(); add_child(fx)[/code].
## One-shot effects emit [signal finished] when they are done; looping effects
## run until [method stop] and emit it once they have died out.

signal finished
## Emitted once per play() at the moment of impact (see [member impact_time]): hook camera shake or sound here.
signal impact

## Start playing as soon as the effect enters the tree.
@export var autoplay := true
## True for bursts (impacts, explosions), false for loops (fire, portals).
@export var one_shot := false
## One-shot: seconds until [signal finished]. Loop: seconds to die out after stop().
@export var duration := 1.0
## Seconds after play() at which [signal impact] fires. Negative: the effect has no impact moment.
@export var impact_time := -1.0
## Free the node when it finishes.
@export var auto_free := false
## Playback speed. Set before play().
@export_range(0.1, 4.0) var speed_scale := 1.0
## Overall size of the effect. Use this instead of scaling the node: particles keep their own
## size when a node is scaled, so a scaled effect falls apart. Set before the effect enters the tree.
@export_range(0.05, 20.0, 0.01, "or_greater") var size := 1.0
## Rotates every colour of the effect around the colour wheel (0.5 turns fire blue).
@export_range(-1.0, 1.0) var hue_shift := 0.0
## Multiplies every colour of the effect (grey smoke with a sand tint gives sandy smoke).
@export var tint := Color.WHITE

var playing := false

var _time := 0.0
var _ending := false
var _run := 0
var _particles: Array[GPUParticles3D] = []
var _meshes: Array[MeshInstance3D] = []
var _lights: Array[Light3D] = []
var _energy := {}
var _tween: Tween
var _fade := 0.0
var _impact_sent := false
# Process materials this instance replaced with its own copy. They must outlive the copy: Godot
# shares one particle shader between materials with the same settings and frees it with the
# original, which leaves the copy drawing unprocessed particles.
var _originals: Array[Material] = []


func _ready() -> void:
	_collect(self)
	if hue_shift != 0.0 or tint != Color.WHITE:
		_apply_hue()
	if size != 1.0:
		_apply_size()
	if autoplay:
		play()
	else:
		for p in _particles:
			p.emitting = false
		_set_fade(0.0)
		for l in _lights:
			l.light_energy = 0.0


## Starts the effect, or restarts it if it is already running.
func play() -> void:
	_run += 1
	_time = 0.0
	_ending = false
	_impact_sent = false
	playing = true
	var run := _run
	for p in _particles:
		p.speed_scale = speed_scale
		var delay: float = p.get_meta("delay", 0.0) / speed_scale
		if delay > 0.0:
			p.emitting = false
			get_tree().create_timer(delay, false).timeout.connect(func() -> void:
				if run == _run:
					p.restart())
		else:
			p.restart()
	_fade_to(1.0, 0.25 / speed_scale)
	for l in _lights:
		l.light_energy = _energy[l]
		var flash: float = l.get_meta("flash", 0.0)
		if flash > 0.0:
			create_tween().tween_property(l, "light_energy", 0.0, flash / speed_scale)


## Stops emitting and lets what is on screen die out. One-shot effects end on their own.
func stop() -> void:
	if not playing or _ending:
		return
	_ending = true
	_time = 0.0
	for p in _particles:
		p.emitting = false
	_fade_to(0.0, minf(duration, 0.5) / speed_scale)
	for l in _lights:
		create_tween().tween_property(l, "light_energy", 0.0, minf(duration, 0.5) / speed_scale)


func _process(delta: float) -> void:
	if not playing:
		return
	_time += delta * speed_scale
	if not _ending:
		for l in _lights:
			var flicker: float = l.get_meta("flicker", 0.0)
			if flicker > 0.0:
				var wave := sin(_time * 13.0) * 0.5 + sin(_time * 7.3 + 1.7) * 0.3 + sin(_time * 23.0) * 0.2
				l.light_energy = _energy[l] * (1.0 + flicker * wave)
		if impact_time >= 0.0 and not _impact_sent and _time >= impact_time:
			_impact_sent = true
			impact.emit()
	if (one_shot or _ending) and _time >= duration:
		playing = false
		finished.emit()
		if auto_free:
			queue_free()


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles3D:
			_particles.append(child)
			_own_material(child)
			if child.has_meta("trail") and RenderingServer.get_rendering_device() != null:
				# Particle trails exist on Forward+ and Mobile only. On Compatibility the ribbon stays a straight streak.
				child.trail_enabled = true
				child.trail_lifetime = child.get_meta("trail")
		elif child is MeshInstance3D:
			_meshes.append(child)
			_own_material(child)
		elif child is Light3D:
			_lights.append(child)
			_energy[child] = child.light_energy
		_collect(child)


# Each instance fades and recolours on its own, so it needs its own material copy.
func _own_material(node: GeometryInstance3D) -> void:
	if node.material_override:
		node.material_override = node.material_override.duplicate()


func _set_fade(value: float) -> void:
	_fade = value
	for m in _meshes:
		var mat := m.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fade", value)


func _fade_to(value: float, time: float) -> void:
	if _meshes.is_empty():
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_fade, _fade, value, maxf(time, 0.01))


func _apply_hue() -> void:
	for node: GeometryInstance3D in _particles + _meshes:
		var mat := node.material_override as ShaderMaterial
		if mat and mat.shader:
			for u in mat.shader.get_shader_uniform_list():
				var v: Variant = mat.get_shader_parameter(u.name)
				if v is Color:
					# A particle layer takes its tint from the process material below, a mesh layer here: once each.
					mat.set_shader_parameter(u.name, _shift(v, node is MeshInstance3D))
	for p in _particles:
		var pm := p.process_material as ParticleProcessMaterial
		if pm == null:
			continue
		_originals.append(pm)
		pm = pm.duplicate()
		p.process_material = pm
		pm.color = _shift(pm.color, true)
		for prop in ["color_ramp", "color_initial_ramp"]:
			var tex := pm.get(prop) as GradientTexture1D
			if tex:
				tex = tex.duplicate(true)
				var colors := tex.gradient.colors
				for i in colors.size():
					colors[i] = _shift(colors[i])
				tex.gradient.colors = colors
				pm.set(prop, tex)
	for l in _lights:
		l.light_color = _shift(l.light_color, true)


# Lengths a particle process material holds in metres (or metres per second).
const _METRIC := ["scale_min", "scale_max", "initial_velocity_min", "initial_velocity_max", "gravity",
	"linear_accel_min", "linear_accel_max", "radial_accel_min", "radial_accel_max", "tangential_accel_min",
	"tangential_accel_max", "damping_min", "damping_max", "emission_sphere_radius", "emission_box_extents",
	"emission_ring_radius", "emission_ring_inner_radius", "emission_ring_height", "emission_shape_offset"]


func _apply_size() -> void:
	for p in _particles:
		p.position *= size
		p.visibility_aabb = AABB(p.visibility_aabb.position * size, p.visibility_aabb.size * size)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			_originals.append(pm)
			pm = pm.duplicate()
			p.process_material = pm
			# Setting a minimum drags its maximum along (and the other way round), so read
			# everything first and write it twice.
			var values := {}
			for prop: String in _METRIC:
				values[prop] = pm.get(prop) * size
			for pass_ in 2:
				for prop: String in values:
					pm.set(prop, values[prop])
		var mat := p.material_override as ShaderMaterial
		if mat and mat.get_shader_parameter("soft_distance") != null:
			mat.set_shader_parameter("soft_distance", mat.get_shader_parameter("soft_distance") * size)
	for m in _meshes:
		m.position *= size
		m.scale *= size
	for l in _lights:
		l.position *= size
		if l is OmniLight3D:
			l.omni_range *= size


func _shift(c: Color, tinted := false) -> Color:
	var out := Color.from_hsv(fposmod(c.h + hue_shift, 1.0), c.s, c.v, c.a)
	return Color(out.r * tint.r, out.g * tint.g, out.b * tint.b, out.a) if tinted else out
