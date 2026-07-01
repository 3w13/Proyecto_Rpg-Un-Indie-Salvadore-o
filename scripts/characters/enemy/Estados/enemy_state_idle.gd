# EnemyStateIdle: estado de reposo del enemigo.
# El enemigo se mantiene quieto hasta detectar al jugador en su DetectionArea.
# Cuando detecta al jugador, transiciona inmediatamente a CHASE.
extends EnemyStateBase


#region Exportaciones

# Nombre del estado de persecución.
@export var chase_state_name: String = "EnemyStateChase"
# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

#endregion


#region Ciclo de vida del estado

# Al entrar, detiene al enemigo y muestra animación de reposo.
func start() -> void:
	print("[Enemy Estado] IDLE")
	_stop_enemy()
	_play_animation(animation_player_path, ANIMATION_IDLE)

# Al salir, asegura que el enemigo quede inmóvil.
func end() -> void:
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

	# Sin jugador detectado: mantener al enemigo quieto.
	_stop_enemy()

#endregion
