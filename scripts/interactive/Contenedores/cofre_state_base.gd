## CofreStateBase
# Clase base de los estados del contenedor.
#
# Proporciona dos referencias comunes:
# - `controlled_node`: nodo del cofre controlado por el estado.
# - `state_machine`: máquina de estados que administra las transiciones.
#
# Los estados concretos solo sobrescriben los callbacks que necesitan.
extends Node

# Nodo que controla el estado actual.
var controlled_node: Node = null
# Referencia a la máquina de estados del contenedor.
# Tipo real: CofreStateMachine (tipado como Node para evitar dependencia circular).
var state_machine: Node = null


# Se ejecuta una vez al entrar al estado.
func start() -> void:
	pass


# Se ejecuta una vez al salir del estado.
func end() -> void:
	pass


# Callback opcional de proceso por frame.
func on_process(_delta: float) -> void:
	pass


# Callback opcional de proceso físico.
func on_physics_process(_delta: float) -> void:
	pass


# Callback opcional para input general.
func on_input(_event: InputEvent) -> void:
	pass


# Callback opcional para input no manejado.
func on_unhandled_input(_event: InputEvent) -> void:
	pass


# Callback opcional para teclas no manejadas.
func on_unhandled_key_input(_event: InputEvent) -> void:
	pass
