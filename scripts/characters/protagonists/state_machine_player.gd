# PlayerStateMachine: orquestador de la máquina de estados del jugador.
# Cada estado es un nodo hijo que extiende StateBase.
# Para cambiar de estado se usa change_to() pasando el nombre del nodo destino.
class_name PlayerStateMachine extends Node


#region Exportaciones

# Referencia al nodo que esta máquina controla (normalmente CharacterBody2D).
@onready var controlled_node: Node = self.owner

# Estado inicial que se activará al arrancar la escena.
@export var default_state: StateBase

# Estado usado para bloquear movimiento mientras hay diálogo activo.
@export var dialogue_state_name: String = "PlayerStateDialogue"

# Estado al que vuelve el jugador cuando termina el diálogo.
@export var post_dialogue_state_name: String = "PlayerStateIdle"

# Nombre del estado de inventario y tecla para abrirlo/cerrarlo.
@export var inventory_state_name: String = "PlayerStateEnterInventory"
@export var inventory_toggle_key: Key = KEY_I

#endregion


#region Variables de estado interno

# Estado actualmente activo.
var current_state: StateBase = null

# Estado al que se volverá al cerrar el inventario.
var _previous_state_before_inventory: String = ""

# Referencia al singleton de DialogueManager.
var _dialogue_manager: Node = null

#endregion


#region Variables de party / seguimiento

# Indica si este personaje actúa como seguidor dentro del grupo.
var is_party_follower: bool = false

# Datos del objetivo al que seguir (posición, dirección, velocidad, movimiento).
var _has_follow_target: bool = false
var _follow_target_position: Vector2 = Vector2.ZERO
var _follow_target_facing: Vector2 = Vector2.DOWN
var _follow_target_speed: float = 0.0
var _follow_target_is_moving: bool = false

# Parámetros de distancia y velocidad para la lógica de chase del grupo.
var _party_stop_distance: float = 10.0
var _party_resume_distance: float = 18.0
var _party_catch_up_multiplier: float = 1.15

# Contadores de frames para confirmar transiciones chase ↔ idle sin jitter.
var _party_stop_confirmation_frames: int = 4
var _party_resume_confirmation_frames: int = 2
var _frames_within_stop_distance: int = 0
var _frames_outside_resume_distance: int = 0

#endregion


#region Ciclo de vida del nodo

# Inicializa física, señales de diálogo y arranca el estado por defecto.
func _ready() -> void:
	_configure_character_body_physics()
	_bind_dialogue_signals()
	# call_deferred garantiza que todos los nodos hijos estén listos antes de arrancar.
	call_deferred("_state_default_start")


# Desconecta señales al salir del árbol para evitar referencias colgantes.
func _exit_tree() -> void:
	_unbind_dialogue_signals()

#endregion


#region Gestión de estados

# Asigna y arranca el estado inicial configurado en el inspector.
func _state_default_start() -> void:
	current_state = default_state
	_state_start()


# Inyecta dependencias en el estado actual y ejecuta su entrada.
func _state_start() -> void:
	if current_state == null:
		push_warning("PlayerStateMachine: current_state es null en " + name)
		return

	current_state.controlled_node = controlled_node
	current_state.state_machine = self as Node
	current_state.start()


# Cambia al estado solicitado por nombre de nodo hijo.
# El nombre debe coincidir exactamente con el nodo hijo dentro de esta máquina.
func change_to(new_state: String) -> void:
	var next := get_node_or_null(new_state) as StateBase
	if next == null:
		push_warning("PlayerStateMachine: estado no encontrado -> " + new_state)
		return

	if current_state and current_state.has_method("end"):
		current_state.end()

	current_state = next
	_state_start()

#endregion


#region Delegación de callbacks de Godot al estado activo
# Cada método comprueba si el estado activo implementa el callback antes de llamarlo,
# de modo que los estados solo definen los métodos que realmente necesitan.

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)


# Reenvía _physics_process al estado activo cuando existe.
func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)


# Reenvía _input al estado activo. Bloqueado en modo seguidor.
func _input(_event: InputEvent) -> void:
	if is_party_follower:
		return
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)


# Reenvía _unhandled_input al estado activo. Bloqueado en modo seguidor.
func _unhandled_input(_event: InputEvent) -> void:
	if is_party_follower:
		return
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)


# Gestiona la hotkey de inventario con prioridad; el resto lo reenvía al estado activo.
# Bloqueado en modo seguidor.
func _unhandled_key_input(_event: InputEvent) -> void:
	if is_party_follower:
		return
	if _is_inventory_toggle_event(_event):
		_toggle_inventory_state()
		return
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)

#endregion


#region Inventario

# Detecta si el evento corresponde a la tecla configurada para el inventario.
func _is_inventory_toggle_event(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event == null:
		return false
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode == inventory_toggle_key


# Alterna entre el estado actual y el estado de inventario.
# Guarda el estado previo para poder volver correctamente al cerrar.
func _toggle_inventory_state() -> void:
	if inventory_state_name == "":
		return

	var inventory_state := get_node_or_null(inventory_state_name) as StateBase
	if inventory_state == null:
		return

	# Si no hay estado activo, entrar directamente al inventario.
	if current_state == null:
		change_to(inventory_state_name)
		print("[SPRITE] Entrada inventario")
		return

	# Si no estamos en el inventario, guardamos el estado actual y entramos.
	if String(current_state.name) != inventory_state_name:
		_previous_state_before_inventory = String(current_state.name)
		change_to(inventory_state_name)
		print("[SPRITE] Entrada inventario")
		return

	# Estamos en el inventario: volver al estado previo o al default como fallback.
	var return_state_name := _previous_state_before_inventory
	if return_state_name == "" or return_state_name == inventory_state_name or get_node_or_null(return_state_name) == null:
		if default_state != null:
			return_state_name = String(default_state.name)

	if return_state_name != "" and get_node_or_null(return_state_name) != null:
		change_to(return_state_name)
		print("[SPRITE] Salida inventario")

#endregion


#region Diálogo

# Conecta las señales globales de inicio y fin de diálogo al DialogueManager.
func _bind_dialogue_signals() -> void:
	if _dialogue_manager == null:
		_dialogue_manager = Engine.get_singleton("DialogueManager")
	if _dialogue_manager == null:
		return

	if not _dialogue_manager.dialogue_started.is_connected(_on_dialogue_started):
		_dialogue_manager.dialogue_started.connect(_on_dialogue_started)

	if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


# Desconecta las señales del DialogueManager previamente enlazadas.
func _unbind_dialogue_signals() -> void:
	if _dialogue_manager == null:
		return

	if _dialogue_manager.dialogue_started.is_connected(_on_dialogue_started):
		_dialogue_manager.dialogue_started.disconnect(_on_dialogue_started)

	if _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.disconnect(_on_dialogue_ended)


# Fuerza la transición al estado de diálogo cuando comienza una conversación.
func _on_dialogue_started(_resource) -> void:
	if dialogue_state_name == "":
		return
	if current_state == null:
		return
	if current_state.name == dialogue_state_name:
		return
	if get_node_or_null(dialogue_state_name) == null:
		return
	change_to(dialogue_state_name)


# Devuelve al estado configurado (post_dialogue o default) al terminar el diálogo.
func _on_dialogue_ended(_resource) -> void:
	if current_state == null:
		return
	if current_state.name != dialogue_state_name:
		return

	if post_dialogue_state_name != "" and get_node_or_null(post_dialogue_state_name) != null:
		change_to(post_dialogue_state_name)
		return

	if default_state != null:
		var default_state_name := String(default_state.name)
		if get_node_or_null(NodePath(default_state_name)) != null:
			change_to(default_state_name)

#endregion


#region Party / Seguimiento

# Activa o desactiva el modo seguidor de grupo.
# Si se desactiva, limpia el objetivo y reinicia los contadores de chase.
func set_party_follower(is_follower: bool) -> void:
	is_party_follower = is_follower
	if not is_node_ready():
		call_deferred("set_party_follower", is_follower)
		return
	if not is_inside_tree():
		return

	var body := controlled_node as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO

	if not is_party_follower:
		clear_follow_target()
		_reset_chase_transition_counters()
		return

	# Como seguidor, arrancar en el estado de reposo configurado.
	if post_dialogue_state_name != "" and get_node_or_null(post_dialogue_state_name) != null:
		if current_state == null or String(current_state.name) != post_dialogue_state_name:
			change_to(post_dialogue_state_name)
		return

	if current_state == null and default_state != null:
		current_state = default_state
		_state_start()


# Configura las distancias y el multiplicador de velocidad del grupo.
func set_party_follow_parameters(stop_distance: float, resume_distance: float, catch_up_multiplier: float) -> void:
	_party_stop_distance = maxf(stop_distance, 0.0)
	_party_resume_distance = maxf(resume_distance, _party_stop_distance)
	_party_catch_up_multiplier = maxf(catch_up_multiplier, 1.0)


# Actualiza la posición, dirección, velocidad y estado de movimiento del objetivo.
func set_follow_target(target_position: Vector2, facing_direction: Vector2 = Vector2.DOWN, target_speed: float = 0.0, target_is_moving: bool = false) -> void:
	_follow_target_position = target_position
	if facing_direction != Vector2.ZERO:
		_follow_target_facing = facing_direction.normalized()
	_follow_target_speed = maxf(target_speed, 0.0)
	_follow_target_is_moving = target_is_moving
	_has_follow_target = true


# Elimina el objetivo de seguimiento y reinicia los contadores de chase.
func clear_follow_target() -> void:
	_has_follow_target = false
	_follow_target_speed = 0.0
	_follow_target_is_moving = false
	_reset_chase_transition_counters()


func has_follow_target() -> bool:
	return _has_follow_target

func get_follow_target_position() -> Vector2:
	return _follow_target_position

func get_follow_target_facing() -> Vector2:
	return _follow_target_facing

func get_follow_target_speed() -> float:
	return _follow_target_speed

func is_follow_target_moving() -> bool:
	return _follow_target_is_moving

func get_party_catch_up_multiplier() -> float:
	return _party_catch_up_multiplier

func get_party_stop_distance() -> float:
	return _party_stop_distance

func get_party_resume_distance() -> float:
	return _party_resume_distance


# Devuelve true si el seguidor debe iniciar el chase hacia el objetivo.
# Requiere que el seguidor esté fuera de _party_resume_distance durante
# al menos _party_resume_confirmation_frames frames consecutivos.
func can_start_chase(from_position: Vector2) -> bool:
	if not is_party_follower or not _has_follow_target:
		_frames_outside_resume_distance = 0
		return false

	_frames_within_stop_distance = 0
	if from_position.distance_to(_follow_target_position) < _party_resume_distance:
		_frames_outside_resume_distance = 0
		return false

	_frames_outside_resume_distance += 1
	return _frames_outside_resume_distance >= _party_resume_confirmation_frames


# Devuelve true si el seguidor debe detenerse (está dentro de _party_stop_distance).
# Requiere confirmación durante _party_stop_confirmation_frames frames consecutivos.
func should_stop_chase(from_position: Vector2) -> bool:
	if not _has_follow_target:
		_frames_within_stop_distance = 0
		return true

	_frames_outside_resume_distance = 0
	if from_position.distance_to(_follow_target_position) > _party_stop_distance:
		_frames_within_stop_distance = 0
		return false

	_frames_within_stop_distance += 1
	return _frames_within_stop_distance >= _party_stop_confirmation_frames


# Reinicia los contadores de confirmación de transición chase ↔ idle.
func _reset_chase_transition_counters() -> void:
	_frames_within_stop_distance = 0
	_frames_outside_resume_distance = 0

#endregion


#region Física y utilidades

# Configura las capas de colisión del CharacterBody2D según las constantes del juego.
func _configure_character_body_physics() -> void:
	var body := controlled_node as CharacterBody2D
	if body == null:
		return
	body.collision_layer = GameConstants.PHYSICS_LAYER_CHARACTER_BODY
	body.collision_mask = GameConstants.PHYSICS_MASK_WORLD_ONLY


# Devuelve el nombre del nodo controlado, o el de esta máquina como fallback.
func _get_controlled_node_name() -> String:
	if controlled_node != null:
		return String(controlled_node.name)
	return String(name)


# Hook temporal para la transición a escena de batalla al ser alcanzado por un enemigo.
# TODO: reemplazar por un estado dedicado cuando se implemente el sistema de batalla.
func notify_enemy_encounter() -> void:
	print("Cambio a esena de batalla")

#endregion
