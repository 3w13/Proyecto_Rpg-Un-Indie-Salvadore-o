# NPCStateRunning: estado de movimiento/patrulla del NPC.
# El NPC se mueve hacia un destino aleatorio generado en ese momento.
# Cuando llega cerca del destino, transiciona al estado IDLE.
extends NPCStateBase

# Velocidad de movimiento del NPC en píxeles/segundo.
@export var speed: float = 350.0

# Rango de generación de destino aleatorio alrededor de la posición actual.
@export var patrol_range: float = 250.0

# Distancia mínima para considerar que llegó al destino.
@export var arrival_distance: float = 100.0

# Ruta al AnimatedSprite2D del NPC.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Variables del estado.
var destination: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var has_destination: bool = false


func start() -> void:
	# Al entrar en RUNNING: generar destino y empezar movimiento.
	print("[NPC Estado] RUNNING")
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	
	_generate_random_destination(npc)


func on_physics_process(delta: float) -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	
	if not has_destination:
		return
	
	# Calcular dirección hacia el destino.
	direction = (destination - npc.global_position).normalized()
	
	# Aplicar velocidad hacia el destino.
	npc.velocity = direction * speed
	
	# Aplicar física y colisiones.
	npc.move_and_slide()
	
	# Reproducir animación según dirección.
	_play_animation_by_direction(direction)
	
	# Verificar si llegó al destino.
	if npc.global_position.distance_to(destination) < arrival_distance:
		has_destination = false
		npc.velocity = Vector2.ZERO
		if state_machine:
			state_machine.change_to("NPCStateIdle")


func _generate_random_destination(npc: CharacterBody2D) -> void:
	# Generar destino aleatorio dentro del rango alrededor de la posición actual.
	var offset := Vector2(
		randf_range(-patrol_range, patrol_range),
		randf_range(-patrol_range, patrol_range)
	)
	destination = npc.global_position + offset
	has_destination = true


func _play_animation_by_direction(dir: Vector2) -> void:
	var animation_name: String = "Espera"
	
	# Umbral de 0.5 para determinar dirección dominante.
	if dir.x < -0.5:
		animation_name = "Izquierda"
	elif dir.x > 0.5:
		animation_name = "Derecha"
	elif dir.y < -0.5:
		animation_name = "Arriba"
	elif dir.y > 0.5:
		animation_name = "Abajo"
	
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)
