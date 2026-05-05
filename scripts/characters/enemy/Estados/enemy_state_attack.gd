# EnemyStateAttack: estado de ataque del enemigo.
# El enemigo se detiene y ataca al jugador con un cooldown.
# Si el jugador se aleja del rango de ataque, transiciona a CHASE.
# Si el jugador sale del área de detección, transiciona a RETURN.
extends EnemyStateBase

#region Exportaciones
# Distancia máxima al jugador para seguir en estado de ataque.
@export var attack_range: float = 40.0

# Tiempo en segundos entre ataques consecutivos.
@export var attack_cooldown: float = 1.0

# Daño que inflige cada ataque (se notifica al jugador via take_damage()).
@export var damage: int = 10

# Nombre del estado de persecución (si el jugador sale del rango de ataque).
@export var chase_state_name: String = "EnemyStateChase"

# Nombre del estado de retorno (si el jugador sale del área de detección).
@export var return_state_name: String = "EnemyStateReturn"

# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Variables de estado
var _attack_timer: float = 0.0
var _can_attack: bool = true
#endregion

#region Ciclo de vida del estado
func start() -> void:
	print("[Enemy Estado] ATTACK")
	_stop_enemy()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	_attack_timer = 0.0
	_can_attack = true


func end() -> void:
	_stop_enemy()
#endregion

#region Física
func on_physics_process(delta: float) -> void:
	var enemy := controlled_node as CharacterBody2D
	if enemy == null:
		return

	# Sin jugador → volver al origen.
	if player_ref == null:
		state_machine.change_to(return_state_name)
		return

	var player_pos := (player_ref as Node2D).global_position
	var distance := enemy.global_position.distance_to(player_pos)

	# Jugador fuera del rango de ataque → perseguir.
	if distance > attack_range:
		state_machine.change_to(chase_state_name)
		return

	_stop_enemy()

	# Gestionar cooldown de ataque.
	if not _can_attack:
		_attack_timer += delta
		if _attack_timer >= attack_cooldown:
			_can_attack = true
			_attack_timer = 0.0
		return

	# Ejecutar ataque.
	_can_attack = false
	_attack_timer = 0.0
	print("[Enemy Attack] ", controlled_node.name, " ataca al jugador — daño: ", damage)
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)
#endregion
