# PlayerStateIdle: estado de reposo del jugador.
# El jugador permanece quieto hasta que detecta input de movimiento,
# momento en que transfiere el control a PlayerStateRunning.
extends StateBase

# Ruta al nodo AnimatedSprite2D dentro del player (relativa al controlled_node).
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Velocidad en reposo (no se usa para mover, está como referencia por si se necesita).
var speed: float = 200.0

func start() -> void:
	# Al entrar en IDLE: detener al jugador y mostrar animación de espera.
	print("[Estado] IDLE")
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	player.velocity = Vector2.ZERO
	_play_animation("Espera")


func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	
	# Leer input de movimiento en los cuatro ejes.
	var input_direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	# Si hay input, pasar a estado de movimiento.
	# El nombre debe coincidir exactamente con el nodo hijo en StateMachine.
	if input_direction != Vector2.ZERO:
		state_machine.change_to("PlayerStateRunning")
		return
	
	# Sin input: mantener velocidad en cero y aplicar física (para colisiones).
	player.velocity = Vector2.ZERO
	player.move_and_slide()


# Reproduce una animación en el AnimatedSprite2D del jugador.
func _play_animation(animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)
