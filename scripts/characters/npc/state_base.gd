# NPCStateBase: clase base para estados de NPC.
# Define el contrato común que todos los estados de NPC deben extender.
class_name NPCStateBase extends Node

# Nodo controlado por el estado (normalmente el NPC owner de la máquina).
@onready var controlled_node: Node = self.owner

# Referencia a la máquina de estados del NPC para poder cambiar de estado.
var state_machine: NPCStateMachine

#region Métodos virtuales — sobreescribir en estados concretos

func start() -> void:
	pass

func end() -> void:
	pass

#endregion
