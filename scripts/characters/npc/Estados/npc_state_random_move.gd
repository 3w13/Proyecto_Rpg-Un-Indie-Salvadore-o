# NPCStateRandomMove: estado de movimiento/patrulla del NPC.
# El NPC se mueve hacia un destino aleatorio generado en ese momento.
# Cuando llega cerca del destino, transiciona al estado IDLE.
extends NPCStateBase

#region Exportaciones
# Velocidad de movimiento del NPC en píxeles/segundo.
@export var speed: float = 350.0

# Rango de generación de destino aleatorio alrededor de la posición actual.
@export var patrol_range: float = 500.0

# Distancia mínima para considerar que llegó al destino.
@export var arrival_distance: float = 12.0

# Ruta al AnimatedSprite2D del NPC.
@export var animation_player_path: NodePath = "AnimatedSprite2D"
#endregion

#region Variables de estado
var destination: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var has_destination: bool = false
#endregion

#region Ciclo de vida del estado
func start() -> void:
	# Al entrar en RANDOM_MOVE: generar destino y empezar movimiento.
	print("[NPC Estado] RANDOM_MOVE")
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	
	_generate_random_destination(npc)
#endregion

#region Física
func on_physics_process(_delta: float) -> void:
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

	# Si chocó con cualquier cuerpo físico (paredes, TilemapLayer, etc.),
	# genera un nuevo destino para cambiar de dirección.
	if npc.get_slide_collision_count() > 0:
		_generate_random_destination(npc)
		direction = (destination - npc.global_position).normalized()
		npc.velocity = direction * speed
	
	# Reproducir animación según dirección.
	_play_animation_by_direction(animation_player_path, direction)
	
	# Verificar si llegó al destino.
	if npc.global_position.distance_to(destination) < arrival_distance:
		has_destination = false
		_stop_npc()
		if state_machine:
			_change_to_idle_state()
#endregion

#region Helpers
func _generate_random_destination(npc: CharacterBody2D) -> void:
	# Generar destino aleatorio dentro del rango alrededor de la posición actual.
	var offset := Vector2(
		randf_range(-patrol_range, patrol_range),
		randf_range(-patrol_range, patrol_range)
	)
	destination = npc.global_position + offset
	has_destination = true


# Intenta volver al estado IDLE probando aliases y búsqueda por script.
func _change_to_idle_state() -> void:
	if state_machine == null:
		return

	var candidates: Array[String] = ["NpcStateIdle", "NPCStateIdle"]
	for state_name in candidates:
		if state_machine.get_node_or_null(state_name) != null:
			state_machine.change_to(state_name)
			return

	for child in state_machine.get_children():
		var script_ref: Script = child.get_script() as Script
		if script_ref == null:
			continue
		if script_ref.resource_path.ends_with("npc_state_idle.gd"):
			state_machine.change_to(child.name)
			return
#endregion

