# EnemyStateIdle: estado de reposo del enemigo.
# El enemigo espera en su posición. Si el jugador entra en rango, transiciona a CHASE.
# Opcionalmente realiza pequeños movimientos de patrulla alrededor del origen.
extends EnemyStateBase

#region Exportaciones
# Tiempo de espera antes de hacer un pequeño movimiento de patrulla.
@export var idle_time_min: float = 1.5
@export var idle_time_max: float = 3.5

# Rango máximo del movimiento de patrulla alrededor del origen.
@export var patrol_range: float = 60.0

# Velocidad de movimiento durante la pequeña patrulla.
@export var patrol_speed: float = 60.0

# Distancia mínima al destino de patrulla para considerarla alcanzada.
@export var arrival_distance: float = 10.0

# Nombre del estado de persecución.
@export var chase_state_name: String = "EnemyStateChase"

# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Variables de estado
var _is_waiting: bool = false
var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false
var _idle_timer: SceneTreeTimer = null
#endregion

#region Ciclo de vida del estado
func start() -> void:
	print("[Enemy Estado] IDLE")
	_stop_enemy()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	_start_idle_wait()


func end() -> void:
	_is_waiting = false
	_idle_timer = null
	_stop_enemy()
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	var enemy := controlled_node as CharacterBody2D
	if enemy == null:
		return

	# Si el jugador entró en rango, transicionar a CHASE inmediatamente.
	if player_ref != null:
		state_machine.change_to(chase_state_name)
		return

	if _is_waiting or not _has_destination:
		_stop_enemy()
		return

	# Mover hacia el destino de patrulla.
	var direction := _destination - enemy.global_position
	if direction.length() <= arrival_distance:
		_has_destination = false
		_stop_enemy()
		_play_animation(animation_player_path, ANIMATION_IDLE)
		_start_idle_wait()
		return

	var dir_normalized := direction.normalized()
	enemy.velocity = dir_normalized * patrol_speed
	enemy.move_and_slide()
	_play_animation_by_direction(animation_player_path, dir_normalized)
#endregion

#region Helpers
func _start_idle_wait() -> void:
	_is_waiting = true
	_idle_timer = get_tree().create_timer(randf_range(idle_time_min, idle_time_max))
	_idle_timer.timeout.connect(_on_idle_timer_timeout, CONNECT_ONE_SHOT)


func _on_idle_timer_timeout() -> void:
	_idle_timer = null
	_is_waiting = false
	if state_machine == null or state_machine.current_state != self:
		return

	# Generar destino aleatorio alrededor del origen.
	var origin := state_machine.origin_position
	_destination = origin + Vector2(
		randf_range(-patrol_range, patrol_range),
		randf_range(-patrol_range, patrol_range)
	)
	_has_destination = true
#endregion
