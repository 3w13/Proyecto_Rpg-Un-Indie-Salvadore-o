# NPCStateBase: clase base para estados de NPC.
# Define el contrato común que todos los estados de NPC deben extender.
class_name NPCStateBase extends Node


#region Constantes de animación

const ANIMATION_IDLE: String  = "Espera"
const ANIMATION_UP: String    = "Arriba"
const ANIMATION_DOWN: String  = "Abajo"
const ANIMATION_LEFT: String  = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"

#endregion


#region Variables

# Nodo controlado por el estado (normalmente el NPC owner de la máquina).
@onready var controlled_node: Node = self.owner

# Referencia a la máquina de estados del NPC para poder cambiar de estado.
var state_machine: NPCStateMachine

# Si es true, este estado no debe activarse por rotación/auto-transición.
# Solo debería activarse por un disparador explícito (por ejemplo, interacción del jugador).
@export var manual_trigger_only: bool = false

# Última dirección de movimiento registrada.
# Usada por estados como WAITING para probar si el camino sigue bloqueado.
var last_movement_direction: Vector2 = Vector2.ZERO

#endregion


#region Métodos virtuales — sobreescribir en estados concretos

# Se ejecuta una vez al entrar al estado.
func start() -> void:
	pass

# Se ejecuta una vez al salir del estado.
func end() -> void:
	pass

#endregion


#region Helpers reutilizables

# Detiene por completo al NPC: velocidad a cero y aplica física.
func _stop_npc() -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()


# Reproduce la animación indicada en el AnimatedSprite2D del NPC.
# No hace fallback: si la animación no existe, AnimatedSprite2D lanzará un error.
func _play_animation(animation_player_path: NodePath, animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)


# Mapea una dirección de movimiento al nombre de animación cardinal correspondiente.
# Usa threshold para determinar el eje dominante. Por defecto devuelve ANIMATION_IDLE.
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


# Atajo que combina _get_animation_by_direction y _play_animation en una sola llamada.
func _play_animation_by_direction(animation_player_path: NodePath, dir: Vector2, threshold: float = 0.5) -> void:
	var animation_name := _get_animation_by_direction(dir, threshold)
	_play_animation(animation_player_path, animation_name)

#endregion
