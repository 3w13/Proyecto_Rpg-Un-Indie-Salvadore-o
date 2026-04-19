# StateBase: clase base que deben extender todos los estados.
# Define el contrato común: propiedades compartidas y métodos virtuales.
# Los estados concretos sobreescriben solo los métodos que necesitan.
class_name StateBase extends Node

# Nodo que este estado controla (asignado por StateMachine al activarse).
@onready var controlled_node:Node = self.owner

# Referencia a la máquina de estados para poder pedir cambios de estado
# con state_machine.change_to("NombreEstado").
var state_machine:StateMachine

#region Métodos virtuales — sobreescribir en cada estado concreto

# Se llama una vez al activarse el estado.
func start():
	pass

# Se llama una vez al desactivarse el estado (antes del siguiente start).
func end():
	pass

#endregion
