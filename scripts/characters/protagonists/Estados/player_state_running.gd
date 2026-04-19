# PlayerStateRunning: estado de movimiento del jugador.
# Mueve al jugador según el input y reproduce la animación de la dirección.
# Si se suelta el input, transfiere el control de vuelta a PlayerStateIdle.
extends StateBase

# Velocidad de movimiento en píxeles por segundo.
@export var speed: float = 200.0

# Ruta al nodo AnimatedSprite2D dentro del player (relativa al controlled_node).
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Guarda la última dirección para poder usarla en animaciones o lógica futura.
var last_direction: Vector2 = Vector2.DOWN

func start() -> void:
	# Al entrar en RUNNING simplemente registramos el cambio en consola.
	print("[Estado] RUNNING")


func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	
	# Leer input de movimiento en los cuatro ejes.
	var input_direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	# Si no hay input, volver al estado de reposo.
	# El nombre debe coincidir exactamente con el nodo hijo en StateMachine.
	if input_direction == Vector2.ZERO:
		state_machine.change_to("PlayerStateIdle")
		return
	
	# Normalizar dirección para que las diagonales no sean más rápidas.
	last_direction = input_direction.normalized()
	
	# Aplicar velocidad al CharacterBody2D.
	player.velocity = last_direction * speed
	
	# Seleccionar y reproducir animación según la dirección dominante.
	_play_animation_by_direction(last_direction)
	
	# Ejecutar el movimiento con detección de colisiones.
	player.move_and_slide()


# Determina qué animación reproducir según la dirección del movimiento.
# Prioridad: horizontal > vertical (izquierda/derecha primero).
func _play_animation_by_direction(direction: Vector2) -> void:
	var animation_name: String = "Espera"
	
	if direction.x < -0.5:
		animation_name = "Izquierda"
	elif direction.x > 0.5:
		animation_name = "Derecha"
	elif direction.y < -0.5:
		animation_name = "Arriba"
	elif direction.y > 0.5:
		animation_name = "Abajo"
	
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)
