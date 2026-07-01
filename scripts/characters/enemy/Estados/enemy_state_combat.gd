# EnemyStateCombat: estado de contacto con el jugador.
# El enemigo permanece quieto mientras el jugador siga dentro del rango de combate.
# Si el jugador se aleja, vuelve a CHASE. Si lo pierde, pasa a RETURN.
extends EnemyStateBase


#region Exportaciones

# Distancia máxima para considerar que el jugador sigue en combate cercano.
@export var combat_distance: float = 24.0
# Nombre del estado de persecución si el jugador se aleja.
@export var chase_state_name: String = "EnemyStateChase"
# Nombre del estado de retorno si el jugador se pierde por completo.
@export var return_state_name: String = "EnemyStateReturn"
# Ruta al AnimatedSprite2D del enemigo.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

#endregion


#region Ciclo de vida del estado

# Al entrar, detiene al enemigo y muestra animación de reposo.
func start() -> void:
	print("[Enemy Estado] COMBAT")
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

	# Sin jugador válido → abandonar combate y volver al origen.
	if player_ref == null:
		state_machine.change_to(return_state_name)
		return
	var player_node := player_ref as Node2D
	if player_node == null:
		state_machine.change_to(return_state_name)
		return

	var distance_to_player := enemy.global_position.distance_to(player_node.global_position)

	# Si el jugador se alejó del rango de combate, volver a perseguirlo.
	if distance_to_player > combat_distance:
		state_machine.change_to(chase_state_name)
		return

	# Jugador dentro del rango: mantener al enemigo quieto en animación de reposo.
	_stop_enemy()
	_play_animation(animation_player_path, ANIMATION_IDLE)

#endregion
