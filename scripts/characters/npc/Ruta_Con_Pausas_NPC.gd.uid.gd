# Script para el movimiento del NPC siguiendo una ruta predeterminada
# El NPC se mueve a lo largo de un PathFollow2D que define su trayectoria
extends CharacterBody2D

# Referencias a nodos
@onready var path_follow: PathFollow2D = get_parent() as PathFollow2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

# ====== VARIABLES DE MOVIMIENTO ======
@export var speed: float = 350.0  # Velocidad de movimiento en píxeles por segundo
@export var move_duration_min: float = 7.0  # Tiempo mínimo de movimiento en segundos
@export var move_duration_max: float = 8.0  # Tiempo máximo de movimiento en segundos
@export var pause_duration_min: float = 3.0  # Tiempo mínimo de pausa en segundos
@export var pause_duration_max: float = 5.0  # Tiempo máximo de pausa en segundos

# Estados del NPC
enum Estado { MOVIENDO, PAUSADO }
var estado: Estado = Estado.MOVIENDO
var tiempo_restante: float = 0.0

# Datos de dirección para animación
var direccion: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO


func _ready() -> void:
	if path_follow == null:
		push_error("Ruta_Con_Pausas_NPC debe colocarse como hijo directo de un PathFollow2D.")
		set_physics_process(false)
		set_process(false)
		return
	
	posicion_anterior = path_follow.global_position
	_validar_valores()
	_cambiar_estado(Estado.MOVIENDO)


func _physics_process(delta: float) -> void:
	if estado == Estado.PAUSADO:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			_cambiar_estado(Estado.MOVIENDO)
		direccion = Vector2.ZERO
		return

	# Durante movimiento
	tiempo_restante -= delta
	if tiempo_restante <= 0.0:
		_cambiar_estado(Estado.PAUSADO)
		return

	path_follow.progress += speed * delta

	var posicion_actual: Vector2 = path_follow.global_position
	direccion = (posicion_actual - posicion_anterior).normalized()
	posicion_anterior = posicion_actual


func _process(_delta: float) -> void:
	_actualizar_animacion()


func _cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	if estado == Estado.MOVIENDO:
		tiempo_restante = randf_range(move_duration_min, move_duration_max)
	else:
		tiempo_restante = randf_range(pause_duration_min, pause_duration_max)


func _validar_valores() -> void:
	if move_duration_min > move_duration_max:
		move_duration_max = move_duration_min
	if pause_duration_min > pause_duration_max:
		pause_duration_max = pause_duration_min
	if speed < 0.0:
		speed = 0.0


func _actualizar_animacion() -> void:
	var animacion: String = "Espera"
	if direccion.x <= -0.5:
		animacion = "Izquierda"
	elif direccion.x >= 0.5:
		animacion = "Derecha"
	elif direccion.y <= -0.5:
		animacion = "Arriba"
	elif direccion.y >= 0.5:
		animacion = "Abajo"

	if animated_sprite:
		animated_sprite.play(animacion)
	else:
		push_warning("AnimatedSprite2D no encontrado en Ruta_Con_Pausas_NPC.")
