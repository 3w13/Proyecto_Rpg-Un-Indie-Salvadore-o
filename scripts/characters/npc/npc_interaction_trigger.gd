# NPCInteractionTrigger
# Script que maneja la interacción NPC-Jugador.
#
# Responsabilidades:
# - Detectar cuando el jugador entra/sale del área de interacción.
# - Escuchar el input E (interact).
# - Cambiar el NPC al estado DIALOGUE cuando se cumplen ambas condiciones.

extends Node

# Referencia al Area2D que detectará la proximidad del jugador.
@onready var interaction_area: Area2D = get_node_or_null("InteractionArea")

# Nombre del estado de diálogo en la máquina de estados.
@export var dialogue_state_name: String = "NpcStateDialogue"

# Referencia a la máquina de estados del NPC.
var state_machine: NPCStateMachine = null

# Flag que indica si el jugador está dentro del área de interacción.
var player_in_range: bool = false


# Resuelve nodos requeridos y conecta señales del área de interacción.
func _ready() -> void:
	# Obtener la máquina de estados del NPC (nodo hijo del mismo NPC).
	state_machine = get_node_or_null("NPCStateMachine") as NPCStateMachine
	
	if interaction_area == null:
		push_warning("NPCInteractionTrigger: InteractionArea no encontrado como hijo de " + name)
		return
	
	if state_machine == null:
		push_warning("NPCInteractionTrigger: NPCStateMachine no encontrado en " + name)
		return
	
	# Conectar señales del Area2D para detectar al jugador.
	interaction_area.monitoring = true
	interaction_area.monitorable = true

	if not interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		interaction_area.area_entered.connect(_on_interaction_area_entered)
	
	if not interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		interaction_area.area_exited.connect(_on_interaction_area_exited)


# Procesa el input para disparar interacción cuando el jugador está en rango.
func _input(event: InputEvent) -> void:
	# Solo procesar input E si el jugador está en rango.
	if not player_in_range:
		return
	
	# Detectar cuando se presiona la tecla E (acción "interact").
	if event.is_action_pressed("interact"):
		_trigger_dialogue()


# Marca entrada del jugador al rango de interacción.
func _on_interaction_area_entered(area: Area2D) -> void:
	# Verificar si el área que entra pertenece al jugador (por ejemplo, InteractArea del Player).
	if _is_player_interaction_area(area):
		player_in_range = true
		print("[NPC Interacción] Jugador entra en rango de " + name)


# Marca salida del jugador del rango de interacción.
func _on_interaction_area_exited(area: Area2D) -> void:
	# Verificar si el área que sale pertenece al jugador.
	if _is_player_interaction_area(area):
		player_in_range = false
		print("[NPC Interacción] Jugador sale del rango de " + name)


# Verifica si el área detectada pertenece al player.
func _is_player_interaction_area(area: Area2D) -> bool:
	if area == null:
		return false

	if area.is_in_group("player"):
		return true

	var owner_node := area.owner
	if owner_node != null and owner_node.is_in_group("player"):
		return true

	var parent_node := area.get_parent()
	if parent_node != null and parent_node.is_in_group("player"):
		return true

	if area.name == "InteractArea":
		return true

	return false


# Solicita transición del NPC al estado de diálogo configurado.
func _trigger_dialogue() -> void:
	# Cambiar al estado de diálogo si la máquina está lista.
	if state_machine == null:
		push_warning("NPCInteractionTrigger: state_machine no disponible en " + name)
		return

	if state_machine.current_state != null and state_machine.current_state.name == dialogue_state_name:
		return
	
	if state_machine.get_node_or_null(dialogue_state_name) == null:
		push_warning("NPCInteractionTrigger: estado '%s' no encontrado en %s" % [dialogue_state_name, name])
		return

	state_machine.request_interaction_transition(dialogue_state_name)
