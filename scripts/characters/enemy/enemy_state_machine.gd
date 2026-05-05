# EnemyStateMachine: orquestador de la máquina de estados para el enemigo básico.
# Sigue la misma lógica que NPCStateMachine:
# - Los estados son nodos hijos que extienden EnemyStateBase.
# - La transición se solicita con change_to(nombre_estado).
# Además, detecta al jugador mediante el DetectionArea del enemigo
# y mantiene la referencia player_ref actualizada para los estados.
class_name EnemyStateMachine extends Node

# Nodo CharacterBody2D que esta máquina controla.
@onready var controlled_node: Node = self.owner

# Estado inicial configurado desde el inspector.
@export var default_state: EnemyStateBase

# Estado activo en este momento.
var current_state: EnemyStateBase = null

# Referencia al nodo del jugador cuando está dentro del área de detección.
var player_ref: Node = null

# Posición de origen del enemigo (guardada al inicio para el estado Return).
var origin_position: Vector2 = Vector2.ZERO


# Arranca la máquina diferida y conecta las señales de detección.
func _ready() -> void:
	call_deferred("_state_default_start")

	var detection_area := controlled_node.get_node_or_null("DetectionArea") as Area2D
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	else:
		push_warning("EnemyStateMachine: DetectionArea no encontrado en " + controlled_node.name)


# Guarda el origen y activa el estado por defecto.
func _state_default_start() -> void:
	if controlled_node is Node2D:
		origin_position = (controlled_node as Node2D).global_position

	if default_state == null:
		push_warning("EnemyStateMachine: default_state no asignado en " + name)
		return

	current_state = default_state
	_state_start()


# Inicializa el estado activo: inyecta dependencias y llama a start().
func _state_start() -> void:
	if current_state == null:
		return

	print("EnemyStateMachine ", controlled_node.name, " start state: ", current_state.name)
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.player_ref = player_ref
	current_state.start()


# Solicita transición a un estado por nombre de nodo hijo.
func change_to(new_state: String) -> void:
	var next := get_node_or_null(new_state) as EnemyStateBase
	if next == null:
		push_warning("EnemyStateMachine: estado no encontrado -> " + new_state)
		return

	if current_state and current_state.has_method("end"):
		current_state.end()

	var previous_name := "<none>"
	if current_state:
		previous_name = current_state.name

	print("EnemyStateMachine ", controlled_node.name, " cambio de estado: ", previous_name, " -> ", next.name)
	current_state = next
	_state_start()


#region Detección del jugador

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		if current_state:
			current_state.player_ref = player_ref
		print("EnemyStateMachine: jugador detectado por ", controlled_node.name)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null
		if current_state:
			current_state.player_ref = null
		print("EnemyStateMachine: jugador salió del rango de ", controlled_node.name)

#endregion

#region Delegación de callbacks al estado activo

func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)


func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(delta)

#endregion
