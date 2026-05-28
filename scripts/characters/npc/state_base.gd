# NPCStateBase: clase base para estados de NPC.
# Define el contrato común que todos los estados de NPC deben extender.
class_name NPCStateBase extends Node

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"
const DEFAULT_PHYSICS_TICKS_PER_SECOND: float = 60.0
const DEFAULT_MOVEMENT_SEGMENT_PX: float = 8.0

# Nodo controlado por el estado (normalmente el NPC owner de la máquina).
@onready var controlled_node: Node = self.owner

# Referencia a la máquina de estados del NPC para poder cambiar de estado.
var state_machine: NPCStateMachine
var _physics_ticks_per_second_cache: float = -1.0

# Si es true, este estado no debe activarse por rotación/auto-transición.
# Solo debería activarse por un disparador explícito (por ejemplo, interacción del jugador).
@export var manual_trigger_only: bool = false

# Última dirección de movimiento registrada.
# Se usa para que estados como WAITING puedan probar si el camino sigue bloqueado.
var last_movement_direction: Vector2 = Vector2.ZERO

#region Métodos virtuales — sobreescribir en estados concretos

func start() -> void:
	pass

# Se ejecuta una vez al salir del estado actual.
func end() -> void:
	pass

# Detiene por completo al NPC y aplica movimiento nulo.
func _stop_npc() -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()

# Reproduce la animación indicada del `AnimatedSprite2D` del NPC.
func _play_animation(animation_player_path: NodePath, animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)

# Mapea una dirección de movimiento al nombre de animación correspondiente.
func _get_animation_by_direction(dir: Vector2, threshold: float = 0.5) -> String:
	if dir.x < -threshold:
		return ANIMATION_LEFT
	if dir.x > threshold:
		return ANIMATION_RIGHT
	if dir.y < -threshold:
		return ANIMATION_UP
	if dir.y > threshold:
		return ANIMATION_DOWN
	return ANIMATION_IDLE

# Reproduce la animación resultante para la dirección dada.
func _play_animation_by_direction(animation_player_path: NodePath, dir: Vector2, threshold: float = 0.5) -> void:
	var animation_name := _get_animation_by_direction(dir, threshold)
	_play_animation(animation_player_path, animation_name)


# Convierte una dirección en velocidad de semi-grid (segmentos por tick de física).
func _get_semi_grid_velocity(direction: Vector2, movement_segment_px: float = DEFAULT_MOVEMENT_SEGMENT_PX) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized() * movement_segment_px * _get_physics_ticks_per_second()


func _get_physics_ticks_per_second() -> float:
	if _physics_ticks_per_second_cache > 0.0:
		return _physics_ticks_per_second_cache

	_physics_ticks_per_second_cache = float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second",
		DEFAULT_PHYSICS_TICKS_PER_SECOND
	))
	return _physics_ticks_per_second_cache

#endregion
