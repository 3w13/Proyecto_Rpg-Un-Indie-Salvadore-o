# EnemyStateBase: clase base para todos los estados del enemigo básico.
# Extiende la base común de animación y agrega helpers/lógica propia del enemigo.
class_name EnemyStateBase extends AnimatedCharacterStateBase

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


#endregion
