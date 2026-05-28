# PlayerStateRunning: estado de movimiento del jugador.
# Mueve al jugador según el input y reproduce la animación de la dirección.
# Si se suelta el input, transfiere el control de vuelta a PlayerStateIdle.
extends StateBase

# Tamaño del segmento de movimiento en píxeles.
@export var movement_segment_px: float = 8.0
const MIN_FRAME_DELTA: float = 0.000001

# Ruta al nodo AnimatedSprite2D dentro del player (relativa al controlled_node).
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Guarda la última dirección para poder usarla en animaciones o lógica futura.
var last_direction: Vector2 = Vector2.DOWN

# Al entrar en RUNNING no requiere inicialización adicional por ahora.
func start() -> void:
	# Al entrar en RUNNING simplemente registramos el cambio en consola.
	#print("[Estado] RUNNING")
	pass


# Procesa movimiento, animación y transición de vuelta a IDLE cuando no hay input.
func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	
	# Leer input de movimiento en los cuatro ejes.
	var input_direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	# Si no hay input, volver al estado de reposo.
	# El nombre debe coincidir exactamente con el nodo hijo en StateMachine.
	if input_direction == Vector2.ZERO:
		if state_machine != null:
			state_machine.change_to("PlayerStateIdle")
		return
	
	# Normalizar dirección para que las diagonales no sean más rápidas.
	last_direction = input_direction.normalized()
	_set_facing_direction(last_direction)
	
	# Aplicar movimiento segmentado (pasos de 8 px por frame de física).
	var movement_step := last_direction * movement_segment_px
	var frame_delta := max(_delta, MIN_FRAME_DELTA)
	player.velocity = movement_step / frame_delta
	
	# Seleccionar y reproducir animación según la dirección dominante.
	_play_animation_by_direction(animation_player_path, last_direction)
	
	# Ejecutar el movimiento con colisión y deslizamiento.
	player.move_and_slide()
