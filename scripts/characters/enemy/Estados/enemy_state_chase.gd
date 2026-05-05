# EnemyStateChase: estado de persecución del jugador.
# El enemigo sigue al jugador mientras esté dentro del área de detección.
# Si el jugador entra en el rango de ataque, transiciona a ATTACK.
# Si el jugador sale del área de detección, transiciona a RETURN.
extends EnemyStateBase

#region Exportaciones
# Velocidad de movimiento al perseguir al jugador.
@export var speed: float = 150.0

# Distancia mínima al jugador para activar el estado de ataque.
@export var attack_range: float = 40.0

# Nombre del estado de ataque.
@export var attack_state_name: String = "EnemyStateAttack"

# Nombre del estado de retorno al origen.
@export var return_state_name: String = "EnemyStateReturn"

# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Ciclo de vida del estado
func start() -> void:
	print("[Enemy Estado] CHASE")


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

	var player_pos := (player_ref as Node2D).global_position
	var distance := enemy.global_position.distance_to(player_pos)

	# Jugador en rango de ataque → atacar.
	if distance <= attack_range:
		state_machine.change_to(attack_state_name)
		return

	# Mover hacia el jugador.
	var direction := (player_pos - enemy.global_position).normalized()
	enemy.velocity = direction * speed
	enemy.move_and_slide()
	_play_animation_by_direction(animation_player_path, direction)
#endregion
