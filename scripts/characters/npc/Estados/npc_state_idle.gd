# NPCStateIdle: estado de reposo/espera del NPC.
# El NPC permanece parado en su ubicación actual, mostrando animación de espera.
# Después de un tiempo aleatorio, transiciona al estado de patrulla/movimiento.
extends NPCStateBase

#region Exportaciones
# Tiempo de espera en estado idle antes de pasar a moving.
@export var wait_time_min: float = 1.0
@export var wait_time_max: float = 3.0

# Ruta al AnimatedSprite2D del NPC.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Variables de estado
var is_waiting: bool = false
#endregion

#region Ciclo de vida del estado
func start() -> void:
	# Al entrar en IDLE: detener y mostrar animación de espera.
	print("[NPC Estado] IDLE")
	_stop_npc()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	
	# Inicia el temporizador de espera.
	is_waiting = true
	var wait_duration = randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(wait_duration).timeout
	is_waiting = false
	
	# Transiciona al estado de movimiento/patrulla.
	# El nombre debe coincidir exactamente con el nodo hijo en NPCStateMachine.
	if state_machine:
		state_machine.change_to("NPCStateRandomMove")
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	# Mantener el NPC parado mientras espera.
	_stop_npc()
#endregion

