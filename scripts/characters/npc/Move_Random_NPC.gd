extends CharacterBody2D

@export var velocidad = 350.0  # velocidad del NPC, configurable en el inspector

var direccion: = Vector2.ZERO  # dirección actual de movimiento (vector normalizado)
var destino: Vector2  # punto actual al que se dirige
var existencia_destino = false  # indica si hay un destino activo

func _ready() -> void:
	# llamado al iniciar la escena
	generar_nuevo_destino()

func _physics_process(_delta: float) -> void:
	# actualización de física cada frame
	movimiento()

func _process(_delta: float) -> void:
	# actualización por frame de render
	actualizar_animacion()

func generar_nuevo_destino():
	# elige un destino aleatorio alrededor de la posición actual
	var rango = 250
	destino = global_position + Vector2(randf_range(-rango, rango), randf_range(-rango, rango))
	existencia_destino = true

func movimiento():
	if existencia_destino:
		# calcula la dirección hacia el destino y mueve el cuerpo
		direccion = (destino - global_position).normalized()
		velocity = direccion * velocidad
		move_and_slide()

		# si ya está cerca del destino, se detiene y espera un tiempo
		if global_position.distance_to(destino) < 100:
			velocity = Vector2.ZERO
			direccion = Vector2.ZERO  # resetear dirección para animación de espera
			existencia_destino = false
			await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
			generar_nuevo_destino()

func actualizar_animacion():
	# elige la animación según la dirección de movimiento
	# dirección normalizada va de -1 a 1, así que usamos umbrales de +/-0.5 para detectar dirección dominante
	var DireccionAnimacion = "Espera"

	if (direccion.x <= -0.5):
		DireccionAnimacion = "Izquierda"
	elif (direccion.x >= 0.5):
		DireccionAnimacion = "Derecha"
	elif (direccion.y <= -0.5):
		DireccionAnimacion = "Arriba"
	elif (direccion.y >= 0.5):
		DireccionAnimacion = "Abajo"

	get_node("AnimatedSprite2D").play(DireccionAnimacion)
