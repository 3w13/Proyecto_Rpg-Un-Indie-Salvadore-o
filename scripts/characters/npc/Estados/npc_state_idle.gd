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

# Si es false, el estado IDLE no hará transición automática.
@export var auto_transition_enabled: bool = true

# Estado al que intentará cambiar al terminar la espera.
# Si no existe en la máquina, se usará un fallback automático.
@export var next_state_name: String = "NPCStateRandomMove"
#endregion

#region Variables de estado
var is_waiting: bool = false
#endregion

#region Ciclo de vida del estado
# Al salir del estado cancela cualquier espera pendiente.
func end() -> void:
	is_waiting = false


func start() -> void:
	# Al entrar en IDLE: detener y mostrar animación de espera.
	print("[NPC Estado] IDLE")
	_stop_npc()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	
	# Inicia el temporizador de espera.
	is_waiting = true
	var wait_duration = randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(wait_duration).timeout

	# El nodo puede haber salido del árbol mientras esperaba (escena descargada, NPC liberado).
	if not is_instance_valid(self) or not is_inside_tree():
		return

	is_waiting = false

	if not auto_transition_enabled:
		return
	
	# Transiciona al estado de movimiento/patrulla.
	# El nombre debe coincidir exactamente con el nodo hijo en NPCStateMachine.
	if state_machine == null:
		return
	if state_machine.current_state != self:
		return

	if next_state_name != "" and state_machine.get_node_or_null(next_state_name) != null:
		state_machine.change_to(next_state_name)
		return

	var fallback_state := _get_next_available_state()
	if fallback_state != "":
		state_machine.change_to(fallback_state)
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	# Mantener el NPC parado mientras espera.
	_stop_npc()
#endregion


func _get_next_available_state() -> String:
	if state_machine == null:
		return ""

	var states: Array[NPCStateBase] = []
	for child in state_machine.get_children():
		if child is NPCStateBase and not child.manual_trigger_only:
			states.append(child)

	if states.size() <= 1:
		return ""

	var current_index := states.find(self)
	if current_index == -1:
		return ""

	var next_index := (current_index + 1) % states.size()
	return states[next_index].name

