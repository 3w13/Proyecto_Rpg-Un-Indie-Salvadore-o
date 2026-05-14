# NPCStateBase: clase base para estados de NPC.
# Extiende la base común de animación y agrega helpers/lógica propia de NPC.
class_name NPCStateBase extends AnimatedCharacterStateBase

# Referencia a la máquina de estados del NPC para poder cambiar de estado.
var state_machine: NPCStateMachine

# Si es true, este estado no debe activarse por rotación/auto-transición.
# Solo debería activarse por un disparador explícito (por ejemplo, interacción del jugador).
@export var manual_trigger_only: bool = false

# Última dirección de movimiento registrada.
# Se usa para que estados como WAITING puedan probar si el camino sigue bloqueado.
var last_movement_direction: Vector2 = Vector2.ZERO

#region Métodos virtuales — sobreescribir en estados concretos

func start() -> void:
	pass

# Se ejecuta una vez al salir del estado actual.
func end() -> void:
	pass

# Detiene por completo al NPC y aplica movimiento nulo.
func _stop_npc() -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return
	npc.velocity = Vector2.ZERO
	npc.move_and_slide()

#endregion
