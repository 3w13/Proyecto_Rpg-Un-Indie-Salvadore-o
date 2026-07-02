# EnemyStateMachine: orquestador de la máquina de estados para el enemigo básico.
# Sigue la misma lógica que NPCStateMachine:
# - Los estados son nodos hijos que extienden EnemyStateBase.
# - La transición se solicita con change_to(nombre_estado).
# Además, detecta al jugador mediante el DetectionArea del enemigo
# y mantiene la referencia player_ref actualizada para los estados.
class_name EnemyStateMachine extends Node


#region Exportaciones

# Nodo CharacterBody2D que esta máquina controla.
@onready var controlled_node: Node = self.owner

# Estado inicial configurado desde el inspector.
@export var default_state: EnemyStateBase

# Activa logs de depuración para ver el flujo de estados del enemigo.
@export var debug_state_logs: bool = true

@export_group("Enemy Movement")
# Velocidad de persecución del enemigo en píxeles por segundo.
@export_range(0.0, 1000.0, 1.0) var chase_speed: float = 150.0
# Velocidad de retorno al origen en píxeles por segundo.
@export_range(0.0, 1000.0, 1.0) var return_speed: float = 100.0

# Grupo que identifica al jugador para la detección.
@export var player_group: StringName = GameConstants.group_player()
# Ruta al Area2D usado como DetectionArea del enemigo.
@export var detection_area_path: NodePath = GameConstants.node_enemy_detection_area()

#endregion


#region Variables

# Estado activo en este momento.
var current_state: EnemyStateBase = null
# Referencia al jugador cuando está dentro del área de detección. Null si no hay jugador.
var player_ref: Node = null
# Posición de origen del enemigo, guardada al inicio para el estado Return.
var origin_position: Vector2 = Vector2.ZERO

#endregion


#region Ciclo de vida del nodo

# Configura física, arranca el estado por defecto y conecta señales de detección.
func _ready() -> void:
	_configure_character_body_physics()
	# call_deferred garantiza que todos los nodos hijos estén listos antes de arrancar.
	call_deferred("_state_default_start")

	var detection_area := controlled_node.get_node_or_null(detection_area_path) as Area2D
	if detection_area:
		detection_area.collision_mask = GameConstants.PHYSICS_MASK_PLAYER_PRESENCE
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	else:
		push_warning("EnemyStateMachine: DetectionArea no encontrado en " + controlled_node.name)

#endregion


#region Gestión de estados

# Guarda el origen del enemigo y activa el estado por defecto.
func _state_default_start() -> void:
	if controlled_node is Node2D:
		origin_position = (controlled_node as Node2D).global_position

	if default_state == null:
		push_warning("EnemyStateMachine: default_state no asignado en " + name)
		return

	current_state = default_state
	_log_initial_state(current_state)
	_state_start()


# Inyecta dependencias en el estado activo y ejecuta su entrada.
func _state_start() -> void:
	if current_state == null:
		return

	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.player_ref = player_ref
	current_state.start()


# Solicita transición a un estado por nombre de nodo hijo.
# Llama a end() en el estado saliente antes de iniciar el nuevo.
func change_to(new_state: String) -> void:
	var next := get_node_or_null(new_state) as EnemyStateBase
	if next == null:
		push_warning("EnemyStateMachine: estado no encontrado -> " + new_state)
		return

	# Evitar transición al mismo estado que ya está activo.
	if current_state == next:
		return

	if current_state and current_state.has_method("end"):
		current_state.end()

	var previous_name := "<none>"
	if current_state:
		previous_name = current_state.name

	_log_state_change(previous_name, next.name)
	current_state = next
	_state_start()

#endregion


#region Detección del jugador

# Asigna player_ref cuando el jugador entra al área de detección.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		player_ref = body
		if current_state:
			current_state.player_ref = player_ref
		print("[DetectionArea] Player dentro del area de deteccion de ", controlled_node.name)


# Limpia player_ref cuando el jugador sale del área de detección.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group):
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


#region Física y utilidades

# Configura las capas de colisión del CharacterBody2D según las constantes del juego.
func _configure_character_body_physics() -> void:
	var body := controlled_node as CharacterBody2D
	if body == null:
		return
	body.collision_layer = GameConstants.PHYSICS_LAYER_CHARACTER_BODY
	body.collision_mask = GameConstants.PHYSICS_MASK_WORLD_ONLY


# Devuelve la velocidad de chase configurada, o el valor por defecto si es 0.
func get_chase_speed(default_speed: float) -> float:
	if chase_speed > 0.0:
		return chase_speed
	return default_speed


# Devuelve la velocidad de retorno configurada, o el valor por defecto si es 0.
func get_return_speed(default_speed: float) -> float:
	if return_speed > 0.0:
		return return_speed
	return default_speed

#endregion


#region Logs de depuración

# Imprime el estado inicial del enemigo si debug_state_logs está activo.
func _log_initial_state(state: EnemyStateBase) -> void:
	if not debug_state_logs or state == null:
		return
	print("[Enemy Estado] ", controlled_node.name, " inicia en ", state.name)


# Imprime la transición entre estados si debug_state_logs está activo.
func _log_state_change(previous_state_name: String, next_state_name: String) -> void:
	if not debug_state_logs:
		return
	print("[Enemy Estado] ", controlled_node.name, ": ", previous_state_name, " -> ", next_state_name)

#endregion
