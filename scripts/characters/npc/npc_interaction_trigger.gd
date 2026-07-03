# NPCInteractionTrigger
# Script que maneja la interacción NPC-Jugador.
#
# Responsabilidades:
# - Detectar cuando el jugador entra/sale del área de interacción.
# - Escuchar el input E (interact).
# - Cambiar el NPC al estado DIALOGUE cuando se cumplen ambas condiciones.
extends Node


#region Exportaciones

# Referencia al Area2D que detectará la proximidad del jugador.
@export var interaction_area_path: NodePath = GameConstants.node_npc_interaction_area()

# Grupo que identifica al jugador para la detección.
@export var player_group: StringName = GameConstants.group_player()
# Nombre del Area2D del jugador usado como zona de interacción.
@export var player_interact_area_name: StringName = GameConstants.node_player_interact_area_name()

# Nombre del estado de diálogo en la máquina de estados del NPC.
@export var dialogue_state_name: String = "NpcStateDialogue"

#endregion


#region Variables

# Area2D que detecta la proximidad del jugador.
@onready var interaction_area: Area2D = get_node_or_null(interaction_area_path)

# Referencia a la máquina de estados del NPC.
var state_machine: NPCStateMachine = null

# Indica si el jugador está actualmente dentro del área de interacción.
var player_in_range: bool = false

#endregion


#region Ciclo de vida del nodo

# Resuelve nodos requeridos y conecta señales del área de interacción.
func _ready() -> void:
	state_machine = get_node_or_null("NPCStateMachine") as NPCStateMachine

	if interaction_area == null:
		push_warning("NPCInteractionTrigger: InteractionArea no encontrado como hijo de " + name)
		return

	if state_machine == null:
		push_warning("NPCInteractionTrigger: NPCStateMachine no encontrado en " + name)
		return

	# Asegurar que el área esté activa antes de conectar señales.
	interaction_area.monitoring = true
	interaction_area.monitorable = true

	if not interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		interaction_area.area_entered.connect(_on_interaction_area_entered)

	if not interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		interaction_area.area_exited.connect(_on_interaction_area_exited)

#endregion


#region Input

# Escucha la acción "interact" y dispara el diálogo si el jugador está en rango.
func _input(event: InputEvent) -> void:
	if not player_in_range:
		return

	if event.is_action_pressed("interact"):
		_trigger_dialogue()

#endregion


#region Detección del jugador

# Marca la entrada del jugador al área de interacción.
func _on_interaction_area_entered(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		player_in_range = true
		print("[NPC Interacción] Jugador entra en rango de " + name)


# Marca la salida del jugador del área de interacción.
func _on_interaction_area_exited(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		player_in_range = false
		print("[NPC Interacción] Jugador sale del rango de " + name)


# Verifica si el área detectada pertenece al jugador.
# Comprueba grupo del área, grupo del owner, grupo del padre y nombre del área.
func _is_player_interaction_area(area: Area2D) -> bool:
	if area == null:
		return false

	if area.is_in_group(player_group):
		return true

	var owner_node := area.owner
	if owner_node != null and owner_node.is_in_group(player_group):
		return true

	var parent_node := area.get_parent()
	if parent_node != null and parent_node.is_in_group(player_group):
		return true

	# Fallback: comparar por nombre de área si está configurado.
	if player_interact_area_name != &"" and area.name == String(player_interact_area_name):
		return true

	return false

#endregion


#region Utilidades internas

# Solicita a la máquina de estados la transición al estado de diálogo configurado.
# No hace nada si el NPC ya está en ese estado.
func _trigger_dialogue() -> void:
	if state_machine == null:
		push_warning("NPCInteractionTrigger: state_machine no disponible en " + name)
		return

	# Evitar transición redundante si ya estamos en el estado de diálogo.
	if state_machine.current_state != null and state_machine.current_state.name == dialogue_state_name:
		return

	if state_machine.get_node_or_null(dialogue_state_name) == null:
		push_warning("NPCInteractionTrigger: estado '%s' no encontrado en %s" % [dialogue_state_name, name])
		return

	state_machine.request_interaction_transition(dialogue_state_name)

#endregion
