# NPCStatePatrol
# Estado de NPC que patrulla siguiendo los puntos de un Path2D.
#
# Requisitos:
# - `patrol_path_path` debe apuntar a un nodo Path2D válido.
# - La curva del Path2D debe tener al menos 2 puntos.
#
# Comportamiento:
# - Al iniciar, carga los puntos del Path2D en coordenadas globales.
# - Selecciona como objetivo inicial el punto más cercano al NPC.
# - Recorre todos los puntos en orden y vuelve al inicio (loop continuo).
# - Cambia animación según la dirección actual de movimiento.
extends NPCStateBase


#region Exportaciones

# Velocidad de desplazamiento del NPC en píxeles/segundo.
@export var speed: float = 120.0

# Ruta al Path2D que define la trayectoria de patrulla.
@export var patrol_path_path: NodePath

# Distancia mínima para considerar que llegó al punto objetivo actual.
@export var arrival_distance: float = 12.0

# Tiempo en segundos antes de pausar la patrulla y pasar a WAITING.
@export var transition_to_waiting_time: float = 8.0

# Nombre del nodo de estado waiting dentro de la máquina.
@export var waiting_state_name: String = "NpcStateWaiting"

# Ruta al AnimatedSprite2D del NPC para reproducir animaciones direccionales.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

#endregion


#region Variables

# Punto objetivo actual en coordenadas globales.
var current_target: Vector2 = Vector2.ZERO

# Lista de puntos de patrulla cargados desde la curva del Path2D (en global).
var patrol_points: Array[Vector2] = []

# Indica si los puntos de patrulla se cargaron correctamente.
var has_patrol_points: bool = false

# Índice del objetivo actual dentro de `patrol_points`.
var current_target_index: int = 0

# Tiempo acumulado en este estado desde la última entrada.
var elapsed_patrol_time: float = 0.0

# Indica si este estado ya fue inicializado al menos una vez.
# Permite retomar el índice guardado en lugar de buscar el más cercano.
var _initialized: bool = false

#endregion


#region Ciclo de vida del estado

# Al entrar por primera vez, carga la ruta y elige el punto más cercano como inicio.
# En reentradas posteriores, retoma desde el índice guardado sin recalcular.
func start() -> void:
	print("[NPC Estado] PATROL")
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return

	elapsed_patrol_time = 0.0

	if not _initialized:
		has_patrol_points = _load_points_from_path()
		if not has_patrol_points:
			push_warning("NPCStatePatrol: Path2D inválido o sin al menos 2 puntos -> " + str(patrol_path_path))
			_stop_npc()
			return
		current_target_index = _get_nearest_patrol_index(npc.global_position)
		current_target = patrol_points[current_target_index]
		_initialized = true
	else:
		# Reentrada: retoma exactamente desde el punto guardado.
		current_target = patrol_points[current_target_index]


# Al salir del estado, deja al NPC completamente detenido.
func end() -> void:
	_stop_npc()

#endregion


#region Física

# Mueve al NPC hacia el objetivo actual y avanza al siguiente punto al llegar.
# Pasa a WAITING si se supera el tiempo límite o se detecta una colisión.
func on_physics_process(delta: float) -> void:
	var npc := controlled_node as CharacterBody2D
	if npc == null:
		return

	elapsed_patrol_time += delta

	# Tiempo de patrulla agotado: pausar y esperar.
	if elapsed_patrol_time >= transition_to_waiting_time:
		_stop_npc()
		_change_to_waiting_state()
		return

	if not has_patrol_points:
		_stop_npc()
		return

	var direction := current_target - npc.global_position

	# Al llegar al punto actual, avanzar al siguiente en el ciclo.
	if direction.length() <= arrival_distance:
		current_target_index = (current_target_index + 1) % patrol_points.size()
		current_target = patrol_points[current_target_index]
		direction = current_target - npc.global_position

	var movement_direction := direction.normalized()
	npc.velocity = movement_direction * speed
	npc.move_and_slide()

	# Guardar dirección para que WAITING pueda probar si el camino sigue bloqueado.
	last_movement_direction = movement_direction

	# Colisión detectada (pared, player, etc.): pausar y esperar.
	if npc.get_slide_collision_count() > 0:
		_stop_npc()
		_change_to_waiting_state()
		return

	_play_animation_by_direction(animation_player_path, movement_direction)

#endregion


#region Utilidades internas

# Carga y valida los puntos desde el Path2D configurado.
# Convierte los puntos de local a global. Retorna true si hay al menos 2 puntos válidos.
func _load_points_from_path() -> bool:
	var path_node := controlled_node.get_node_or_null(patrol_path_path) as Path2D
	if path_node == null:
		return false
	if path_node.curve == null:
		return false
	if path_node.curve.point_count < 2:
		return false

	patrol_points.clear()
	for i in path_node.curve.point_count:
		var local_point := path_node.curve.get_point_position(i)
		patrol_points.append(path_node.to_global(local_point))

	if patrol_points.size() < 2:
		return false

	return true


# Busca el índice del punto de patrulla más cercano a un origen dado.
# Se usa para que el NPC arranque de forma natural desde su posición actual.
func _get_nearest_patrol_index(origin: Vector2) -> int:
	var nearest_index := 0
	var nearest_distance := INF

	for i in patrol_points.size():
		var distance := origin.distance_to(patrol_points[i])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	return nearest_index


# Intenta cambiar al estado WAITING de forma tolerante a diferencias de naming.
# Primero busca por nombre configurado y variantes conocidas; como último recurso,
# busca entre los hijos por nombre de script.
func _change_to_waiting_state() -> void:
	if state_machine == null:
		return

	# Intentar nombres conocidos en orden de prioridad.
	var candidates: Array[String] = [waiting_state_name, "NpcStateWaiting", "NPCStateWaiting"]
	for state_name in candidates:
		if state_name == "":
			continue
		if state_machine.get_node_or_null(state_name) != null:
			state_machine.change_to(state_name)
			return

	# Fallback: buscar por nombre de archivo de script.
	for child in state_machine.get_children():
		var script_ref: Script = child.get_script() as Script
		if script_ref == null:
			continue
		if script_ref.resource_path.ends_with("npc_state_waiting.gd"):
			state_machine.change_to(child.name)
			return

#endregion
