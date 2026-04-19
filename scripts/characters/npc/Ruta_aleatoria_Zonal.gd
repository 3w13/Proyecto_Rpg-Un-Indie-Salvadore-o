extends CharacterBody2D

# Variables configurables desde el inspector
@export var area_center: Vector2 = Vector2.ZERO  # Centro del área de movimiento
@export var area_radius: float = 100.0  # Radio del área de movimiento
@export var speed: float = 100.0  # Velocidad de movimiento
@export var min_distance: float = 20.0  # Distancia mínima para elegir destino
@export var max_distance: float = 80.0  # Distancia máxima para elegir destino

# Variables internas
var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var direccion: Vector2 = Vector2.ZERO  # Dirección actual para animaciones

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready():
	# Inicializar con un destino aleatorio
	choose_random_target()

func _physics_process(_delta):
	if has_target:
		# Calcular dirección hacia el destino
		direccion = (target_position - global_position).normalized()

		# Aplicar velocidad
		velocity = direccion * speed

		# Mover el personaje
		move_and_slide()

		# Verificar si colisionó con algo y cambiar dirección
		if get_slide_collision_count() > 0:
			choose_random_target()
			return  # Salir para evitar verificar llegada al destino en este frame

		# Verificar si llegó al destino (distancia pequeña)
		if global_position.distance_to(target_position) < 5.0:
			has_target = false
			direccion = Vector2.ZERO  # Detener animación durante espera
			# Esperar un poco antes de elegir nuevo destino
			await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
			choose_random_target()
	else:
		direccion = Vector2.ZERO

func choose_random_target():
	# Elegir una dirección aleatoria
	var angle = randf() * 2 * PI
	var distance = randf_range(min_distance, max_distance)

	# Calcular posición relativa al centro del área
	var relative_position = Vector2(cos(angle), sin(angle)) * distance

	# Asegurarse de que esté dentro del radio del área
	if relative_position.length() > area_radius:
		relative_position = relative_position.normalized() * area_radius

	# Establecer destino absoluto
	target_position = area_center + relative_position
	has_target = true

func _process(_delta: float) -> void:
	actualizar_animacion()

func actualizar_animacion():
	var DireccionAnimacion = "Espera"

	if (direccion.x <= -0.5):
		DireccionAnimacion = "Izquierda"
	elif (direccion.x >= 0.5):
		DireccionAnimacion = "Derecha"
	elif (direccion.y <= -0.5):
		DireccionAnimacion = "Arriba"
	elif (direccion.y >= 0.5):
		DireccionAnimacion = "Abajo"

	if animated_sprite:
		animated_sprite.play(DireccionAnimacion)
	else:
		push_warning("AnimatedSprite2D no encontrado en Ruta_aleatoria_Zonal.")
