# NPCStateBase: clase base para estados de NPC.
# Define el contrato común que todos los estados de NPC deben extender.
class_name NPCStateBase extends Node

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"

# Nodo controlado por el estado (normalmente el NPC owner de la máquina).
@onready var controlled_node: Node = self.owner

# Referencia a la máquina de estados del NPC para poder cambiar de estado.
var state_machine: NPCStateMachine

# Última dirección de movimiento registrada.
# Se usa para que estados como WAITING puedan probar si el camino sigue bloqueado.
var last_movement_direction: Vector2 = Vector2.ZERO

#region Métodos virtuales — sobreescribir en estados concretos

func start() -> void:
	pass

func end() -> void:
	pass

func _stop_npc() -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()

func _play_animation(animation_player_path: NodePath, animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)

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

func _play_animation_by_direction(animation_player_path: NodePath, dir: Vector2, threshold: float = 0.5) -> void:
	var animation_name := _get_animation_by_direction(dir, threshold)
	_play_animation(animation_player_path, animation_name)

#endregion
