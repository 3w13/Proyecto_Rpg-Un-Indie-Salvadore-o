# Script para el movimiento del NPC siguiendo una ruta predeterminada
# El NPC se mueve a lo largo de un PathFollow2D que define su trayectoria
extends CharacterBody2D

# Obtiene el nodo PathFollow2D padre que define la ruta a seguir
@onready var path_follow = get_parent()

# ====== VARIABLES DE MOVIMIENTO ======
var direccion: Vector2  # Dirección actual del movimiento
var posicion_anterior: Vector2  # Registra la posición anterior para calcular cambios
var speed: float = 350.0  # Velocidad de movimiento en píxeles por segundo (configurable)

# ====== VARIABLES DE PAUSA ======
var tiempo_espera = 0.0  # Contador de tiempo para la pausa actual
var pausa = false  # Bandera que indica si el NPC está en pausa


# Se ejecuta cuando el nodo entra en la escena
func _ready():
	# Guarda la posición inicial para futuras comparaciones
	posicion_anterior = path_follow.global_position


# Se ejecuta cada frame de física
# delta: es el tiempo transcurrido desde el último frame
func _physics_process(delta: float) -> void:
	# Avanza el progreso del PathFollow2D basándose en la velocidad
	# Esto hace que el NPC se mueva a lo largo de la ruta
	path_follow.progress += speed * delta

	# Calcula la dirección basada en el cambio de posición
	var posicion_actual = path_follow.global_position
	direccion = (posicion_actual - posicion_anterior).normalized()
	posicion_anterior = posicion_actual

	# Si el NPC está en pausa
	if pausa:
		# Decrementa el temporizador de espera
		if tiempo_espera <= 0.0:
			# Cuando el tiempo se acaba, reanuda el movimiento
			pausa = false
		else:
			# Sigue esperando, decementa el tiempo
			tiempo_espera -= delta
			direccion = Vector2.ZERO  # Resetear dirección durante pausa para animación de espera    

# Se ejecuta cada frame de render
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
	get_node("AnimatedSprite2D").play(DireccionAnimacion)
