extends StateBase

# =========================================================
# ESTADO: SEGUIR (Follow State)
# Controla el movimiento del personaje cuando sigue a un
# objetivo (por ejemplo, el líder del grupo en el party).
# =========================================================

#region Exportaciones
@export var speed: float = 250.0
## Ruta al nodo AnimatedSprite2D que maneja las animaciones del personaje
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion


#region Ciclo de vida del estado

## Se ejecuta al entrar al estado.
## Detiene al personaje inmediatamente al iniciar el seguimiento.
func start() -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO


## Se ejecuta cada frame de física.
## Calcula la dirección, velocidad y animación para seguir al objetivo.
func on_physics_process(delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	if state_machine == null:
		return
	# Verificar que la máquina de estados soporte seguimiento de objetivos
	if not state_machine.has_method("has_follow_target"):
		return

	# Si no hay objetivo que seguir, volver al estado inactivo
	if not state_machine.has_follow_target():
		_change_to_idle(player)
		return

	var target_position: Vector2 = state_machine.get_follow_target_position()
	var to_target := target_position - player.global_position
	var distance_to_target := to_target.length()

	# Verificar si la máquina de estados indica que debemos detenernos
	if state_machine.has_method("should_stop_chase") and state_machine.should_stop_chase(player.global_position):
		_change_to_idle(player)
		return

	# Si ya estamos sobre el objetivo, detenerse
	if distance_to_target <= 0.001:
		_change_to_idle(player)
		return

	var move_direction := to_target.normalized()

	# Obtener multiplicador de velocidad para alcanzar al grupo
	var catch_up_multiplier := 1.0
	if state_machine.has_method("get_party_catch_up_multiplier"):
		catch_up_multiplier = state_machine.get_party_catch_up_multiplier()

	# Obtener la dirección de mirada del objetivo (para animaciones)
	var target_facing := _get_facing_direction()
	if state_machine.has_method("get_follow_target_facing"):
		target_facing = state_machine.get_follow_target_facing()

	# Obtener la velocidad actual del objetivo
	var target_speed := 0.0
	if state_machine.has_method("get_follow_target_speed"):
		target_speed = state_machine.get_follow_target_speed()

	# Saber si el objetivo está en movimiento
	var target_is_moving := false
	if state_machine.has_method("is_follow_target_moving"):
		target_is_moving = state_machine.is_follow_target_moving()

	# Velocidad máxima permitida para no sobrepasar al objetivo en un frame
	var max_frame_speed := distance_to_target / maxf(delta, 0.001)

	var follow_speed := _resolve_follow_speed(distance_to_target, target_speed, target_is_moving, catch_up_multiplier)
	var applied_speed := minf(follow_speed, max_frame_speed)
	var animation_direction := _resolve_cardinal_direction(move_direction, target_facing)

	_set_facing_direction(animation_direction)
	player.velocity = move_direction * applied_speed
	_play_animation_by_direction(animation_player_path, animation_direction)
	player.move_and_slide()

#endregion


#region Transiciones de estado

## Transiciona al estado Idle (inactivo).
## Ajusta la dirección de mirada para que coincida con el objetivo antes de detenerse.
func _change_to_idle(player: CharacterBody2D) -> void:
	# Heredar la dirección de mirada del objetivo al detenerse
	if state_machine != null and state_machine.has_method("get_follow_target_facing"):
		var target_facing: Vector2 = state_machine.get_follow_target_facing()
		if target_facing != Vector2.ZERO:
			_set_facing_direction(_resolve_cardinal_direction(target_facing, target_facing))

	player.velocity = Vector2.ZERO
	player.move_and_slide()
	_play_animation(animation_player_path, ANIMATION_IDLE_DOWN, true)
	state_machine.change_to("PlayerStateIdle")

#endregion


#region Cálculo de velocidad

## Calcula la velocidad de seguimiento según la distancia y el estado del objetivo.
## Aplica una interpolación suave entre velocidad mínima y máxima según qué tan
## lejos esté el seguidor del objetivo, respetando las distancias de parada/reanudación.
##
## [param distance_to_target] Distancia actual al objetivo en píxeles.
## [param target_speed] Velocidad actual del objetivo.
## [param target_is_moving] Si el objetivo se está moviendo actualmente.
## [param catch_up_multiplier] Multiplicador adicional para alcanzar al grupo.
## [returns] Velocidad calculada a aplicar este frame.
func _resolve_follow_speed(distance_to_target: float, target_speed: float, target_is_moving: bool, catch_up_multiplier: float) -> float:
	# Distancia mínima para considerarse "llegado" al objetivo
	var stop_distance := 10.0
	if state_machine != null and state_machine.has_method("get_party_stop_distance"):
		stop_distance = state_machine.get_party_stop_distance()

	# Distancia a partir de la cual se reanuda el movimiento tras detenerse
	var resume_distance := maxf(stop_distance + 1.0, 18.0)
	if state_machine != null and state_machine.has_method("get_party_resume_distance"):
		resume_distance = maxf(state_machine.get_party_resume_distance(), stop_distance + 1.0)

	# Ratio de 0.0 (cerca) a 1.0 (lejos) dentro del rango de parada/reanudación
	var gap_ratio := clampf((distance_to_target - stop_distance) / maxf(resume_distance - stop_distance, 0.001), 0.0, 1.0)

	if target_is_moving:
		# Si el objetivo se mueve: interpolar entre velocidad suave (cerca) y rápida (lejos)
		var near_speed := maxf(minf(speed * 0.8, target_speed * 0.9), 80.0)
		var far_speed := maxf(speed, target_speed * catch_up_multiplier)
		return lerpf(near_speed, far_speed, gap_ratio)

	# Si el objetivo está quieto: usar velocidades más lentas para asentarse suavemente
	var near_settle_speed := maxf(speed * 0.45, 70.0)
	var far_settle_speed := maxf(speed * 0.8, near_settle_speed)
	return lerpf(near_settle_speed, far_settle_speed, gap_ratio)

#endregion


#region Dirección cardinal

## Resuelve la dirección cardinal (arriba/abajo/izquierda/derecha) a partir de
## un vector de movimiento, con soporte para una dirección preferida en diagonales.
##
## [param move_direction] Vector de movimiento actual del personaje.
## [param preferred_direction] Dirección preferida para desempatar en diagonales (opcional).
## [returns] Vector cardinal unitario que representa la dirección de animación.
func _resolve_cardinal_direction(move_direction: Vector2, preferred_direction: Vector2 = Vector2.ZERO) -> Vector2:
	# Sin movimiento: usar la dirección preferida o la almacenada
	if move_direction == Vector2.ZERO:
		if preferred_direction != Vector2.ZERO:
			return _resolve_cardinal_direction(preferred_direction)
		return _get_facing_direction()

	var normalized_direction := move_direction.normalized()
	var abs_x := absf(normalized_direction.x)
	var abs_y := absf(normalized_direction.y)

	# En diagonales cercanas al umbral, respetar la dirección preferida
	if preferred_direction != Vector2.ZERO:
		var preferred_cardinal := _resolve_cardinal_direction(preferred_direction)
		if absf(abs_x - abs_y) <= 0.15:
			return preferred_cardinal

	# Si X e Y son exactamente iguales, usar la dirección almacenada para desempatar
	if is_equal_approx(abs_x, abs_y):
		var stored_direction := _get_facing_direction()
		if absf(stored_direction.x) > absf(stored_direction.y):
			return Vector2(signf(stored_direction.x), 0.0)
		if absf(stored_direction.y) > 0.0:
			return Vector2(0.0, signf(stored_direction.y))

	# Eje dominante: horizontal o vertical
	if abs_x > abs_y:
		return Vector2(signf(normalized_direction.x), 0.0)

	return Vector2(0.0, signf(normalized_direction.y))

#endregion
