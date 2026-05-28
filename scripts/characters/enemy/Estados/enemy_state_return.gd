# EnemyStateReturn: estado de regreso al origen del enemigo.
# El enemigo vuelve a su posición inicial después de perder al jugador.
# Si el jugador reaparece en el área de detección, transiciona a CHASE.
# Al llegar al origen, transiciona a IDLE.
extends EnemyStateBase

#region Exportaciones
# Deprecated: usar movement_segment_px. Se mantiene por compatibilidad.
@export var speed: float = 100.0
@export var movement_segment_px: float = 8.0

# Distancia mínima al origen para considerar que llegó.
@export var arrival_distance: float = 10.0

# Nombre del estado idle al llegar al origen.
@export var idle_state_name: String = "EnemyStateIdle"

# Nombre del estado de persecución si el jugador es detectado de nuevo.
@export var chase_state_name: String = "EnemyStateChase"

# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Ciclo de vida del estado
func start() -> void:
	print("[Enemy Estado] RETURN")


func end() -> void:
	_stop_enemy()
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	var enemy := controlled_node as CharacterBody2D
	if enemy == null:
		return

	# Si el jugador vuelve a entrar en rango, retomar la persecución.
	if player_ref != null:
		state_machine.change_to(chase_state_name)
		return

	var direction := state_machine.origin_position - enemy.global_position

	# Ya llegó al origen → reanudar IDLE.
	if direction.length() <= arrival_distance:
		_stop_enemy()
		_play_animation(animation_player_path, ANIMATION_IDLE)
		state_machine.change_to(idle_state_name)
		return

	# Moverse hacia el origen.
	var dir_normalized := direction.normalized()
	enemy.velocity = _get_semi_grid_velocity(dir_normalized, _resolve_movement_segment_px(movement_segment_px, speed))
	enemy.move_and_slide()
	_play_animation_by_direction(animation_player_path, dir_normalized)
#endregion
