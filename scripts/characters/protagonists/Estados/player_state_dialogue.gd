extends StateBase

# PlayerStateDialogue: estado de bloqueo del jugador durante diálogos.
# Mientras este estado está activo, el player no puede moverse.

@export_group("Configuración de Diálogo")

# Recurso de diálogo relacionado con este estado.
# Se expone en inspector para poder configurarlo fácilmente si luego quieres
# enlazar este estado a un diálogo concreto.
@export var dialogue_resource: DialogueResource

# Ruta alternativa al archivo .dialogue.
@export_file("*.dialogue") var dialogue_path: String = ""

# Título opcional del diálogo relacionado.
@export var dialogue_title: String = ""

@export_group("Animación")

# Ruta al AnimatedSprite2D dentro del player.
@export var animation_player_path: NodePath = "AnimatedSprite2D"


# Al entrar al estado, detiene movimiento y conserva la animación según facing.
func start() -> void:
	#print("[Estado] DIALOGUE")
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO
	_play_animation_by_direction(animation_player_path, _get_facing_direction())


# Al salir del estado, asegura que el player quede inmóvil.
func end() -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO


# Durante diálogo bloquea el desplazamiento en cada frame físico.
func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO
	player.move_and_slide()
