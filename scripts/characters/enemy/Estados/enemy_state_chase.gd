# EnemyStateChase: estado de persecución del jugador.
# El enemigo sigue al jugador mientras esté dentro del área de detección.
# Si el jugador sale del área de detección, transiciona a RETURN.
extends EnemyStateBase

#region Exportaciones
# Velocidad de movimiento al perseguir al jugador.
@export var speed: float = 150.0
@export var movement_segment_px: float = 8.0

# Distancia mínima al jugador para disparar el encuentro de batalla.
@export var battle_trigger_distance: float = 16.0

# Nombre del estado de combate cercano.
@export var combat_state_name: String = "EnemyStateCombat"

# Nombre del estado de retorno al origen.
@export var return_state_name: String = "EnemyStateReturn"

# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

# Evita disparar el encuentro más de una vez mientras este estado esté activo.
var _battle_requested: bool = false

#region Ciclo de vida del estado
func start() -> void:
	print("[Enemy Estado] CHASE")
	_battle_requested = false


func end() -> void:
	_stop_enemy()
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	var enemy := controlled_node as CharacterBody2D
	if enemy == null:
		return

	# Sin jugador → volver al origen.
	if player_ref == null:
		state_machine.change_to(return_state_name)
		return

	var player_node := player_ref as Node2D
	if player_node == null:
		state_machine.change_to(return_state_name)
		return

	var to_player := player_node.global_position - enemy.global_position
	if not _battle_requested and to_player.length() <= battle_trigger_distance:
		_request_battle_transition(player_node)
		state_machine.change_to(combat_state_name)
		return

	var player_pos := player_node.global_position
	# Mover hacia el jugador.
	var direction := (player_pos - enemy.global_position).normalized()
	enemy.velocity = _get_semi_grid_velocity(direction, _resolve_movement_segment_px())
	enemy.move_and_slide()
	_play_animation_by_direction(animation_player_path, direction)
#endregion

#region Helpers
func _request_battle_transition(player_node: Node) -> void:
	_battle_requested = true

	# Delegamos el print al player para mantener el flujo preparado para el cambio de escena.
	if player_node != null and player_node.has_method("notify_enemy_encounter"):
		player_node.call("notify_enemy_encounter")
		return

	var player_state_machine := player_node.get_node_or_null(GameConstants.node_player_state_machine())
	if player_state_machine != null and player_state_machine.has_method("notify_enemy_encounter"):
		player_state_machine.call("notify_enemy_encounter")
		return

	# Fallback por si aún no existe método en el player.
	print("Cambio a esena de batalla")


func _resolve_movement_segment_px() -> float:
	if movement_segment_px > 0.0:
		return movement_segment_px
	if speed <= 0.0:
		return DEFAULT_MOVEMENT_SEGMENT_PX
	return max(speed / _get_physics_ticks_per_second(), 0.001)
#endregion
