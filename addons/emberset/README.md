# Emberset Combat (free sample)

9 of the 315 scenes in the full pack (303 effects + 12 frosted glass materials), free to use. Same files, same licence.

Full pack (303 effects + 12 glass materials): https://jv18creator.itch.io/emberset-combat · All Emberset packs: https://jv18creator.itch.io

Everything is procedural: shaders, five small noise textures and a few tiny meshes, all generated in code.
No sprite sheets, no plugins to enable, no autoloads.

It installs into the same `addons/emberset` folder as the first Emberset pack and shares its runtime script,
so the two packs work side by side and neither needs the other.

## Install

1. Copy the `addons/emberset` folder into your project (keep the path, the scenes point at it). If you already
   have Emberset, merge the folders and let the newer files replace the older ones.
2. Drag any scene from `addons/emberset/effects/` into your level. It plays.

To browse every effect first, open this folder as a Godot project and press Play: `demo/gallery.tscn`
lists them all with an orbit camera. The `demo` folder is not needed in your game.

## Elements

Slashes, hits, explosions, shields and charge-ups are named `<design>_<element>.tscn`. An element is not a
recolour: each one brings its own layers.

| Element | What it adds |
|---|---|
| steel | sparks with ribbon trails, glints |
| fire | flame puffs, embers, heat haze that bends the scene |
| ice | crystal shards, frost mist, snow |
| shock | lightning arcs, trailing sparks |
| void | dark smoke, motes pulled inwards |

`hue_shift` and `tint` still work on top, so a fire slash can be turned green.

## Use from code

```gdscript
const Slash := preload("res://addons/emberset/effects/slash/swing_fire.tscn")

func attack() -> void:
    var fx := Slash.instantiate()
    fx.auto_free = true                      # frees itself when it is done
    fx.impact.connect(camera_shake)          # fires at the moment of impact
    add_child(fx)                            # as a child of the attacker: it faces -Z like the attacker does
```

Every effect scene has the root script `EmbersetEffect`:

| Member | What it does |
|---|---|
| `autoplay` | Play when the node enters the tree. On by default. |
| `one_shot` | True for bursts, false for loops (shields, status effects). |
| `duration` | One-shot: seconds until `finished`. Loop: seconds it takes to die out after `stop()`. |
| `auto_free` | Free the node when it finishes. |
| `speed_scale` | Playback speed, 0.1 to 4. Set before `play()`. |
| `size` | Overall size of the effect (2 = twice as big). Use this instead of scaling the node: particles keep their own size when a node is scaled. Set before adding the node to the tree. |
| `hue_shift` | Rotates every colour of the effect. Set before adding the node to the tree. |
| `tint` | Multiplies every colour of the effect. Set before adding the node to the tree. |
| `impact_time` | Seconds after `play()` at which `impact` fires. Negative: no impact moment. |
| `play()` | Start, or restart from the beginning. |
| `stop()` | Stop emitting and let what is on screen die out. |
| `finished` | Signal. One-shots emit it after `duration`; loops emit it after `stop()` has died out. |
| `impact` | Signal. Emitted once per `play()` at the moment of impact: hook camera shake, sound or damage here. Charge-ups fire it at the release. |

### Shields react to hits

Shield scenes have the root script `EmbersetShield`. Tell it where it was hit and a ripple runs out from that point:

```gdscript
shield.hit(collision_point)   # world position; up to 4 ripples at once
```

`ripple_time` sets how long a ripple lasts. On Forward+ and Mobile (Godot 4.4 or newer) the shield also glows
where it meets other geometry.

### Status effects coat the character

Status scenes have the root script `EmbersetStatus`. Put the scene at the character's feet and hand it the
character's meshes; it sets their Material Overlay and removes it again when it stops or is freed:

```gdscript
var fx := preload("res://addons/emberset/effects/status/frozen.tscn").instantiate()
character.add_child(fx)
fx.attach(character.get_node("Body"))   # any MeshInstance3D; call once per mesh
...
fx.stop()                                # particles die out, the overlay fades and is removed
```

The overlay materials are also saved on their own in `addons/emberset/overlays/`, one per status, if you
would rather assign them yourself. They are made for a character about 1.8 m tall (`height` on the material).

The `ablaze_*` scenes in `effects/flame/` work the same way: one per flame style, each sets a character on
fire in that style.

### Frosted glass

`addons/emberset/glass/` holds twelve glass materials (clear, frosted, privacy, ice, winter window, rippled,
pebbled, smoked, amber, bottle, rose, cracked). Put one on any mesh: a window pane, a block of ice, a screen.

```gdscript
$Window.material_override = preload("res://addons/emberset/glass/frosted.tres")
```

The shader (`shaders/fx_glass.gdshader`) blurs and tints what is behind the mesh and grows frost on it;
`blur`, `frost`, `edge_frost`, `tint`, `frost_color`, `distortion` and `rim` are on the material.
The scenes in `effects/glass/` are a pane with each material, so they show up in the demo.

## Which way effects point

- **Slashes**: the caster stands at the node's origin and looks along **-Z**. Add the scene as a child of the
  attacker at about chest height. `flying_crescent` and `flying_cross` do not move on their own: move the node.
- **Hits**: the origin is the point of impact and the blow travels along -Z. `hit_slam` lies on the floor.
- **Explosions**: `ground_blast`, `pillar` and `nova` stand on the floor; `air_burst` and `implosion` are centred on the origin.
- **Shields**: `bubble`, `aegis` and `orbit` are centred on the origin (put them at chest height); `dome` and `ward` stand on the floor; `barrier` is a wall facing +Z.
- **Charge-ups**: `charge_gather` and `charge_spiral` are centred on the origin; `charge_ground_seal` and `charge_aura` stand on the floor at the caster's feet.
- **Status effects**: origin at the character's feet.
- **Flames**: stand on the floor and burn upwards. Three sizes each: `small` about 0.5 m, `medium` 1 m, `large` 2 m. `flame_wall` is a line along X.
- **Electric**: `zap` and `chain` run from the origin along -Z; `sky_strike`, `ground_impact`, `field`, `cage` and `surge` stand on the floor; `ball`, `ball_burst` and `impact` are centred on the origin.
- **Elemental magic**: `<element>_bolt` and `<element>_sphere` fly along -Z and do not move on their own: move the node. `_circle` and `_eruption` lie on the floor, about 3 m across. `_cast` goes at the caster's feet, `_invoke` at hand height, releasing along -Z; both fire `impact` at the release.
- **Dark magic**: `dark_bolt`, `dark_lance` and `dark_swarm` fly along -Z (move the node); `dark_orb`, `dark_eye` and `dark_star` are centred on the origin; `dark_circle`, `dark_pool`, `dark_wisps` and `dark_maelstrom` lie on the floor; `dark_vortex` stands upright, centred 1.4 m above the origin, facing +Z.

## Renderers

| Renderer | Status |
|---|---|
| Forward+ | Every effect rendered and checked. |
| Mobile | Every effect rendered and checked. |
| Compatibility (also web) | Every effect rendered and checked; the browser demo is a Compatibility build. |

Needs Godot 4.3 or newer. Tested in Godot 4.3 and 4.7.2. The effects are drawn additively and are made for a scene with **glow enabled** in the
`WorldEnvironment`; `demo/stage.gd` shows the settings used in the screenshots.

Differences between renderers and versions:

- Screen distortion (shockwaves, heat haze) is left out on Compatibility in Godot 4.3; it works everywhere from 4.4 on.
- Ribbon trails (steel sparks, explosion streamers, the charge spiral) need Forward+ or Mobile. The Compatibility renderer has no particle trails, so there they are drawn as straight streaks, and Godot prints a one-time warning about particle trails that can be ignored.
- The shield's glow line where it meets geometry, and the soft fade of glow sprites at the floor, need Godot 4.4 or newer on Forward+ or Mobile.
- On Godot 4.3 camera-facing sprites do not keep a set angle, so the rays of `dark_star` are drawn as one upright flare there. From 4.4 on it has eight rays.
- On Godot 4.3 the engine's glow is stronger on Forward+, so bright effects bloom more. Lower `glow_intensity` if they look blown out.

## Known limits

- No sound. Use the `impact` signal to play your own.
- The effects use `GPUParticles3D`. There are no `CPUParticles3D` fallbacks.
- No collision or damage logic; these are visuals only.
- Do not scale the root node: Godot particles ignore it. Set `size` instead.
- Frosted glass reads the screen texture: it shows the opaque scene behind it, not other transparent objects or particles, and Godot allows one such read per pixel, so two panes behind each other do not stack. On Compatibility the blur is made of sixteen samples without the screen's mip levels, so strong blur (the `privacy` preset) looks grainy there; in Godot 4.3 on Compatibility the glass is left out.
- Status overlays use the mesh's Material Overlay slot, so a mesh that already uses that slot for something else needs its own solution.

## Effects (9)

`loop` runs until `stop()`. A number is a one-shot and its length in seconds.

**Slash** (`effects/slash/`)

| Design | Type | Scenes |
|---|---|---|
| `swing` | 1.1 s | `swing_fire` |

**Hit** (`effects/hit/`)

| Design | Type | Scenes |
|---|---|---|
| `hit_heavy` | 0.6 s | `hit_heavy_steel` |

**Explosion** (`effects/explosion/`)

| Design | Type | Scenes |
|---|---|---|
| `ground_blast` | 2.5 s | `ground_blast_fire` |

**Shield** (`effects/shield/`)

| Design | Type | Scenes |
|---|---|---|
| `bubble` | loop | `bubble_shock` |

**Charge** (`effects/charge/`)

| Design | Type | Scenes |
|---|---|---|
| `charge_gather` | 2.5 s | `charge_gather_ice` |

**Status** (`effects/status/`)

| Design | Type | Scenes |
|---|---|---|
| `frozen` | loop | `frozen` |

**Electric** (`effects/electric/`)

| Design | Type | Scenes |
|---|---|---|
| `electric_zap` | 0.5 s | `electric_zap_blue` |

**Magic** (`effects/magic/`)

| Design | Type | Scenes |
|---|---|---|
| `magic_bolt` | loop | `fire_bolt` |

**Glass** (`effects/glass/`)

| Design | Type | Scenes |
|---|---|---|
| `glass` | loop | `glass_frosted` |

## Licence

See `LICENSE.txt`. Short version: use the effects in any number of free or commercial games and apps, change them
as you like, no credit needed. Do not resell or redistribute the pack itself, changed or not, as an asset pack.
