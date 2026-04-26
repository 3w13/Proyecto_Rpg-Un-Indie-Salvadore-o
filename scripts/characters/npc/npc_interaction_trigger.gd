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
	if not interaction_area.body_entered.is_connected(_on_area_body_entered):
		interaction_area.body_entered.connect(_on_area_body_entered)
	
	if not interaction_area.body_exited.is_connected(_on_area_body_exited):
		interaction_area.body_exited.connect(_on_area_body_exited)


func _input(event: InputEvent) -> void:
	# Solo procesar input E si el jugador está en rango.
	if not player_in_range:
		return
	
	# Detectar cuando se presiona la tecla E (acción "interact").
	if event.is_action_pressed("interact"):
		_trigger_dialogue()


func _on_area_body_entered(body: Node2D) -> void:
	# Verificar si es el jugador (asume que el jugador tiene un nombre específico o grupo).
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		print("[NPC Interacción] Jugador entra en rango de " + name)


func _on_area_body_exited(body: Node2D) -> void:
	# Verificar si es el jugador.
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		print("[NPC Interacción] Jugador sale del rango de " + name)


func _trigger_dialogue() -> void:
	# Cambiar al estado de diálogo si la máquina está lista.
	if state_machine == null:
		push_warning("NPCInteractionTrigger: state_machine no disponible en " + name)
		return
	
	if state_machine.get_node_or_null(dialogue_state_name) == null:
		push_warning("NPCInteractionTrigger: estado '%s' no encontrado en %s" % [dialogue_state_name, name])
		return
	
	state_machine.change_to(dialogue_state_name)
