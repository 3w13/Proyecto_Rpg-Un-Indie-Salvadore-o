extends CharacterBody2D

# Referencias a nodos
@onready var path_follow: PathFollow2D = get_parent() as PathFollow2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

# Variables de movimiento
@export var speed: float = 350.0  # Velocidad en píxeles por segundo
var direction_multiplier: float = 1.0  # 1.0 para adelante (A a B), -1.0 para atrás (B a A)

# Variables para animación
var direccion: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO

const DIRECTION_MAP = {
	"Izquierda": Vector2.LEFT,
	"Derecha": Vector2.RIGHT,
	"Arriba": Vector2.UP,
	"Abajo": Vector2.DOWN,
}

func _ready() -> void:
	if path_follow == null:
		push_error("Ruta_A_B_B_A debe colocarse como hijo directo de un PathFollow2D.")
		set_physics_process(false)
		set_process(false)
		return

	posicion_anterior = path_follow.global_position


func _physics_process(delta: float) -> void:
	# Mover a lo largo del path
	path_follow.progress += speed * direction_multiplier * delta

	# Invertir dirección al llegar a los extremos
	if path_follow.progress_ratio >= 1.0:
		direction_multiplier = -1.0
	elif path_follow.progress_ratio <= 0.0:
		direction_multiplier = 1.0

	# Calcular dirección para animación
	var posicion_actual: Vector2 = path_follow.global_position
	direccion = (posicion_actual - posicion_anterior).normalized()
	posicion_anterior = posicion_actual


func _process(_delta: float) -> void:
	_actualizar_animacion()


func _actualizar_animacion() -> void:
	var animacion: String = "Espera"
	if direccion.length() >= 0.1:
		animacion = _mejor_animacion_de_direccion(direccion)

	if animated_sprite:
		animated_sprite.play(animacion)
	else:
		push_warning("AnimatedSprite2D no encontrado en Ruta_A_B_B_A.")


func _mejor_animacion_de_direccion(dir: Vector2) -> String:
	var mejor_animacion: String = "Espera"
	var mejor_valor: float = -1.0
	var direccion_normalizada = dir.normalized()

	for nombre_animacion in DIRECTION_MAP.keys():
		var referencia = DIRECTION_MAP[nombre_animacion]
		var valor = direccion_normalizada.dot(referencia)
		if valor > mejor_valor:
			mejor_valor = valor
			mejor_animacion = nombre_animacion

	return mejor_animacion