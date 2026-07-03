## SceneTransitionTrigger
# Trigger reutilizable para cambio de escenas desde un Area2D.
#
# Modos soportados:
# - ON_INTERACT: requiere jugador en rango + tecla de interacción.
# - ON_ENTER: solo requiere que el jugador entre al área.
extends Area2D

class_name SceneTransitionTrigger


#region Enums

enum TransitionMode {
	ON_INTERACT, # Requiere input explícito del jugador para transicionar.
	ON_ENTER,    # Transiciona automáticamente al entrar al área.
}

enum TriggerState {
	IDLE,            # Sin jugador en rango.
	PLAYER_IN_RANGE, # Jugador dentro del área, esperando input.
	COOLDOWN,        # Transición en curso; ignorar nuevas solicitudes.
}

#endregion


#region Exportaciones

@export var next_scene_path: String = ""
@export var transition_mode: TransitionMode = TransitionMode.ON_INTERACT
# Acción de input que dispara la transición en modo ON_INTERACT.
@export var interaction_action: StringName = &"interact"
# Grupo que identifica al jugador para la detección por cuerpo.
@export var player_group: StringName = GameConstants.group_player()
# Nombre de nodo fallback para reconocer al jugador si no tiene grupo asignado.
@export var fallback_player_node_name: StringName = GameConstants.node_player_root_name()
# Nombre del Area2D del jugador fallback para reconocer su zona de interacción.
@export var fallback_player_interact_area_name: StringName = GameConstants.node_player_interact_area_name()
# Tiempo de espera tras una transición fallida antes de volver a aceptar input.
@export_range(0.0, 10.0, 0.1) var cooldown: float = 0.5

#endregion


#region Variables

# Estado interno actual del trigger.
var _current_state: TriggerState = TriggerState.IDLE
# Indica si el jugador está físicamente dentro del área.
var _player_in_range: bool = false
# Versiones String de los fallbacks para evitar conversiones repetidas en runtime.
var _fallback_player_node_name_text: String = ""
var _fallback_player_interact_area_name_text: String = ""

#endregion


#region Ciclo de vida del nodo

# Configura el Area2D, precalcula strings de fallback y conecta señales.
func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_mask = GameConstants.PHYSICS_MASK_PLAYER_PRESENCE

	# Precalcular una vez para evitar conversiones StringName→String en cada frame.
	_fallback_player_node_name_text = String(fallback_player_node_name)
	_fallback_player_interact_area_name_text = String(fallback_player_interact_area_name)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)

	_set_state(TriggerState.IDLE)

#endregion


#region Input

# Escucha la acción de interacción solo en modo ON_INTERACT con jugador en rango.
func _unhandled_input(event: InputEvent) -> void:
	if transition_mode != TransitionMode.ON_INTERACT:
		return
	if _current_state != TriggerState.PLAYER_IN_RANGE:
		return
	if event.is_action_pressed(interaction_action):
		_request_scene_change()

#endregion


#region Detección del jugador

# Detecta entrada de un cuerpo físico (CharacterBody2D, etc.).
func _on_body_entered(body: Node2D) -> void:
	if not _is_player_body(body):
		return
	_set_player_in_range(true)
	if transition_mode == TransitionMode.ON_ENTER:
		_request_scene_change()


# Detecta salida de un cuerpo físico.
func _on_body_exited(body: Node2D) -> void:
	if not _is_player_body(body):
		return
	_set_player_in_range(false)


# Detecta entrada del Area2D de interacción del jugador.
func _on_area_entered(area: Area2D) -> void:
	if not _is_player_interaction_area(area):
		return
	_set_player_in_range(true)
	if transition_mode == TransitionMode.ON_ENTER:
		_request_scene_change()


# Detecta salida del Area2D de interacción del jugador.
func _on_area_exited(area: Area2D) -> void:
	if not _is_player_interaction_area(area):
		return
	_set_player_in_range(false)

#endregion


#region Transición de escena

# Solicita el cambio de escena si no hay cooldown activo y la ruta es válida.
# Si el cambio falla, espera el cooldown y restaura el estado anterior.
func _request_scene_change() -> void:
	if _current_state == TriggerState.COOLDOWN:
		return

	if next_scene_path.strip_edges() == "":
		push_warning("SceneTransitionTrigger: next_scene_path vacío en " + name)
		return

	_set_state(TriggerState.COOLDOWN)

	var result := get_tree().change_scene_to_file(next_scene_path)
	if result == OK:
		return

	# El cambio falló: registrar el error, esperar cooldown y restaurar estado.
	push_warning("SceneTransitionTrigger: no se pudo cambiar a '%s' (error: %s)" % [next_scene_path, str(result)])
	await _run_cooldown()
	if _player_in_range:
		_set_state(TriggerState.PLAYER_IN_RANGE)
	else:
		_set_state(TriggerState.IDLE)


# Espera el tiempo de cooldown configurado antes de continuar.
func _run_cooldown() -> void:
	if cooldown <= 0.0:
		return
	await get_tree().create_timer(cooldown).timeout

#endregion


#region Gestión de estado interno

# Actualiza el estado interno del trigger.
func _set_state(new_state: TriggerState) -> void:
	_current_state = new_state


# Actualiza el flag de jugador en rango y sincroniza el estado del trigger.
# No cambia el estado si hay un cooldown activo.
func _set_player_in_range(in_range: bool) -> void:
	_player_in_range = in_range
	if _current_state == TriggerState.COOLDOWN:
		return
	if _player_in_range:
		_set_state(TriggerState.PLAYER_IN_RANGE)
	else:
		_set_state(TriggerState.IDLE)

#endregion


#region Utilidades internas

# Verifica si un cuerpo físico pertenece al jugador.
# Comprueba grupo, nombre de nodo, grupo del owner y grupo del padre.
func _is_player_body(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group(player_group):
		return true
	if fallback_player_node_name != &"" and body.name == _fallback_player_node_name_text:
		return true
	var owner_node := body.owner
	if owner_node != null and owner_node.is_in_group(player_group):
		return true
	var parent_node := body.get_parent()
	if parent_node != null and parent_node.is_in_group(player_group):
		return true
	return false


# Verifica si un Area2D pertenece a la zona de interacción del jugador.
# Comprueba grupo del área, grupo del owner, grupo del padre y nombre de área.
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
	if fallback_player_interact_area_name != &"" and area.name == _fallback_player_interact_area_name_text:
		return true
	return false

#endregion
