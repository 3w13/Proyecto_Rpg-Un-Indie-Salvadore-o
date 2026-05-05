# EnemyStateBase: clase base para todos los estados del enemigo básico.
# Define el contrato común (ciclo de vida, helpers de animación y movimiento).
class_name EnemyStateBase extends Node

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"

# Nodo CharacterBody2D controlado por este estado.
var controlled_node: Node = null

# Referencia a la máquina de estados del enemigo.
var state_machine: EnemyStateMachine = null

# Referencia al nodo del jugador, asignada por la máquina al detectarlo.
var player_ref: Node = null

#region Métodos virtuales — sobreescribir en estados concretos

# Se ejecuta una vez al entrar al estado.
func start() -> void:
	pass


# Se ejecuta una vez al salir del estado.
func end() -> void:
	pass


# Callback de proceso por frame (opcional).
func on_process(_delta: float) -> void:
	pass


# Callback de proceso físico (opcional).
func on_physics_process(_delta: float) -> void:
	pass

#endregion

#region Helpers reutilizables

# Detiene por completo al enemigo.
func _stop_enemy() -> void:
	var enemy := controlled_node as CharacterBody2D
	if enemy == null:
		return
	enemy.velocity = Vector2.ZERO
	enemy.move_and_slide()


# Reproduce la animación indicada del AnimatedSprite2D del enemigo.
func _play_animation(animation_player_path: NodePath, animation_name: String) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play(animation_name)


# Devuelve el nombre de animación según la dirección de movimiento.
func _get_animation_by_direction(dir: Vector2, threshold: float = 0.5) -> String:
	if dir.x < -threshold:
		return ANIMATION_LEFT
	if dir.x > threshold:
		return ANIMATION_RIGHT
	if dir.y < -threshold:
		return ANIMATION_UP
	if dir.y > threshold:
		return ANIMATION_DOWN
	return ANIMATION_IDLE


# Reproduce la animación direccional resultante.
func _play_animation_by_direction(animation_player_path: NodePath, dir: Vector2, threshold: float = 0.5) -> void:
	_play_animation(animation_player_path, _get_animation_by_direction(dir, threshold))

#endregion
