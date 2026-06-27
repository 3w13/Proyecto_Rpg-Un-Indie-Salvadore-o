extends Node

## Registrado como autoload (singleton) `OcclusionManager`, instanciado desde
## `scenes/system/OcclusionManager.tscn` para que sus variables `@export` sean
## editables desde el inspector del editor de Godot (abre esa escena para
## ajustarlas). No usa `class_name` para no chocar con el nombre del singleton.
##
## Sistema modular de "Dynamic Occlusion" (occlusión dinámica) basado en un
## RADIO circular alrededor del actor (por defecto, los nodos del grupo
## `player`). Cualquier nodo de los grupos `wall` o `structure` se vuelve
## semi-transparente SOLO en los píxeles que caen dentro del círculo: cuanto más
## cerca del jugador, más transparente; recupera la opacidad de forma gradual
## hacia el borde del círculo (transición suave, sin cortes abruptos).
##
## El efecto se logra con un shader (`shaders/dynamic_occlusion.gdshader`) que
## calcula la distancia por píxel al actor más cercano. Esto es lo que permite
## un círculo real incluso sobre un `TileMapLayer` completo, en lugar de
## desvanecer la capa entera. Un único `ShaderMaterial` compartido se asigna a
## todos los occluders y sus uniforms se actualizan cada frame.
##
## Funciona en todos los mapas sin configuración por escena: basta con añadir
## los nodos (TileMapLayer, Sprite2D, etc.) a los grupos `wall` / `structure`.
## Los nombres de grupo provienen de `GameConstants`, según la convención del
## proyecto.

# Debe coincidir con `MAX_ACTORS` del shader.
const MAX_ACTORS: int = 16
const SHADER_PATH: String = "res://shaders/dynamic_occlusion.gdshader"

# --- Parámetros configurables (editables en el inspector) ------------------

## Radio (px) del círculo de detección alrededor del actor.
@export var detection_radius: float = 96.0:
	set(value):
		detection_radius = maxf(0.0, value)
		_push_static_uniforms()
## Alpha mínimo (más transparente) en el centro del círculo.
@export_range(0.0, 1.0, 0.01) var min_alpha: float = 0.25:
	set(value):
		min_alpha = clampf(value, 0.0, 1.0)
		_push_static_uniforms()
## Intervalo (s) entre re-escaneos de occluders (para mapas recién cargados).
@export var rescan_interval: float = 0.5
## Grupos cuyos nodos actúan como occluders (se desvanecen).
@export var occluder_groups: Array[StringName] = [
	GameConstants.GROUP_WALL,
	GameConstants.GROUP_STRUCTURE,
]
## Grupos cuyos nodos definen el centro del círculo y deben permanecer visibles.
@export var occludee_groups: Array[StringName] = [GameConstants.GROUP_PLAYER]

# --- Estado interno --------------------------------------------------------

var _material: ShaderMaterial
var _rescan_accum: float = 0.0
## instance_ids de los occluders a los que ya les asignamos el material.
var _assigned: Dictionary = {}


func _ready() -> void:
	# El manager debe seguir corriendo aunque el árbol esté pausado por menús.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	_push_static_uniforms()
	_rescan_accum = rescan_interval


func _process(delta: float) -> void:
	# Las posiciones de los actores se actualizan cada frame (movimiento fluido).
	_update_actor_uniforms()

	# Los occluders se re-escanean con menor frecuencia (cambios de escena).
	_rescan_accum += delta
	if _rescan_accum >= rescan_interval:
		_rescan_accum = 0.0
		_assign_material_to_occluders()


# --- API pública (modular / reciclable) -----------------------------------

## Permite que otros sistemas registren grupos adicionales de occluders.
func add_occluder_group(group: StringName) -> void:
	if not occluder_groups.has(group):
		occluder_groups.append(group)


## Permite ampliar qué actores definen el círculo (p. ej. enemigos importantes).
func add_occludee_group(group: StringName) -> void:
	if not occludee_groups.has(group):
		occludee_groups.append(group)


# --- Actualización de uniforms --------------------------------------------

func _push_static_uniforms() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("detection_radius", detection_radius)
	_material.set_shader_parameter("min_alpha", min_alpha)


func _update_actor_uniforms() -> void:
	if _material == null:
		return
	var positions: PackedVector2Array = PackedVector2Array()
	for group in occludee_groups:
		for node in get_tree().get_nodes_in_group(group):
			var actor := node as Node2D
			if actor == null or not actor.is_visible_in_tree():
				continue
			positions.append(actor.global_position)
			if positions.size() >= MAX_ACTORS:
				break
		if positions.size() >= MAX_ACTORS:
			break
	_material.set_shader_parameter("actor_positions", positions)
	_material.set_shader_parameter("actor_count", positions.size())


# --- Asignación del material a los occluders ------------------------------

func _assign_material_to_occluders() -> void:
	if _material == null:
		return
	for group in occluder_groups:
		for node in get_tree().get_nodes_in_group(group):
			var occluder := node as CanvasItem
			if occluder == null:
				continue
			var id := occluder.get_instance_id()
			if _assigned.has(id):
				continue
			# No pisamos un material propio del nodo (p. ej. otro shader).
			if occluder.material != null and occluder.material != _material:
				push_warning("OcclusionManager: '%s' ya tiene un material; se omite." % occluder.name)
				_assigned[id] = true
				continue
			occluder.material = _material
			_assigned[id] = true
