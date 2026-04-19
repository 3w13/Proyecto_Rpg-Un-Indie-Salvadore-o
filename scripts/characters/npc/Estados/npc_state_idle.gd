# NPCStateIdle: estado de reposo/espera del NPC.
# El NPC permanece parado en su ubicación actual, mostrando animación de espera.
# Después de un tiempo aleatorio, transiciona al estado de patrulla/movimiento.
extends NPCStateBase

# Tiempo de espera en estado idle antes de pasar a moving.
@export var wait_time_min: float = 1.0
@export var wait_time_max: float = 3.0

# Ruta al AnimatedSprite2D del NPC.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

var is_waiting: bool = false

func start() -> void:
	# Al entrar en IDLE: detener y mostrar animación de espera.
	print("[NPC Estado] IDLE")
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	
	npc.velocity = Vector2.ZERO
	_play_animation("Espera")
	
	# Inicia el temporizador de espera.
	is_waiting = true
	var wait_duration = randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(wait_duration).timeout
	is_waiting = false
	
	# Transiciona al estado de movimiento/patrulla.
	# El nombre debe coincidir exactamente con el nodo hijo en NPCStateMachine.
	if state_machine:
		state_machine.change_to("NPCStateRunning")


func on_physics_process(_delta: float) -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	
	# Mantener el NPC parado mientras espera.
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()


func _play_animation(animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)
