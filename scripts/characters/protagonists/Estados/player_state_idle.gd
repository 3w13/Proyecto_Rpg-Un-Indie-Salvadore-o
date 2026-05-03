# PlayerStateIdle: estado de reposo del jugador.
# El jugador permanece quieto hasta que detecta input de movimiento,
# momento en que transfiere el control a PlayerStateRunning.
extends StateBase

# Ruta al nodo AnimatedSprite2D dentro del player (relativa al controlled_node).
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Velocidad en reposo (no se usa para mover, está como referencia por si se necesita).
var speed: float = 200.0

# Al entrar al estado, detiene movimiento y mantiene animación de reposo.
func start() -> void:
	# Al entrar en IDLE: detener al jugador y mostrar animación de espera.
	#print("[Estado] IDLE")
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	player.velocity = Vector2.ZERO
	_play_animation_by_direction(animation_player_path, _get_facing_direction())


# Permanece en reposo y cambia a RUNNING cuando detecta input de movimiento.
func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	
	# Leer input de movimiento en los cuatro ejes.
	var input_direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	# Si hay input, pasar a estado de movimiento.
	# El nombre debe coincidir exactamente con el nodo hijo en StateMachine.
	if input_direction != Vector2.ZERO:
		if state_machine != null:
			state_machine.change_to("PlayerStateRunning")
		return
	
	# Sin input: mantener velocidad en cero y aplicar física (para colisiones).
	player.velocity = Vector2.ZERO
	player.move_and_slide()
