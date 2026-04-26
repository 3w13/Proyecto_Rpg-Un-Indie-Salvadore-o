# NPCStateWaiting: estado de pausa del NPC.
# Detiene al NPC entre 2 y 5 segundos y luego pasa al siguiente estado disponible en la máquina.
extends NPCStateBase

#region Exportaciones
@export var wait_time_min: float = 2.0
@export var wait_time_max: float = 5.0

# Distancia de prueba para detectar si el camino sigue bloqueado al retomar.
@export var collision_probe_distance: float = 16.0
#endregion

#region Variables de estado
var is_waiting: bool = false
#endregion

#region Ciclo de vida del estado
func start() -> void:
	print("[NPC Estado] WAITING")
	_stop_npc()
	is_waiting = true

	var wait_duration := randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(wait_duration).timeout

	if not is_waiting:
		return
	if state_machine == null:
		return
	if state_machine.current_state != self:
		return

	var next_state := _get_next_available_state()
	if next_state != "":
		# Antes de retomar, comprobar que el camino no esté bloqueado.
		if _is_path_blocked():
			# Camino bloqueado: reiniciar el temporizador de espera.
			var extra_wait := randf_range(wait_time_min, wait_time_max)
			await get_tree().create_timer(extra_wait).timeout
			if not is_waiting or state_machine == null or state_machine.current_state != self:
				return
		state_machine.change_to(next_state)


func end() -> void:
	is_waiting = false
	_stop_npc()
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
	_stop_npc()
#endregion

#region Helpers
func _get_next_available_state() -> String:
	if state_machine == null:
		return ""

	var states: Array[NPCStateBase] = []
	for child in state_machine.get_children():
		if child is NPCStateBase:
			states.append(child)

	if states.size() <= 1:
		return ""

	var current_index := states.find(self)
	if current_index == -1:
		return ""

	var next_index := (current_index + 1) % states.size()
	return states[next_index].name


# Comprueba si la dirección de la última ruta sigue bloqueada.
# Usa test_move() para no mover físicamente al NPC.
func _is_path_blocked() -> bool:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return false
	if last_movement_direction == Vector2.ZERO:
		return false
	return npc.test_move(npc.global_transform, last_movement_direction * collision_probe_distance)
#endregion
