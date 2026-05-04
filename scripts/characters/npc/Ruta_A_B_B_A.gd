# Ruta_A_B_B_A: Mueve al NPC desde su posición inicial (punto A) hasta un punto B
# y luego regresa de B a A en un ciclo continuo (A→B→A→B…).
# El punto B se define como un desplazamiento relativo a la posición inicial del NPC.
extends CharacterBody2D

# Velocidad de desplazamiento en píxeles/segundo.
@export var speed: float = 80.0

# Desplazamiento del punto B respecto a la posición inicial (punto A).
# Ejemplo: Vector2(200, 0) → el NPC se mueve 200 px hacia la derecha y vuelve.
@export var destination_offset: Vector2 = Vector2(200, 0)

# Distancia en píxeles para considerar que llegó al punto objetivo.
@export var arrival_distance: float = 12.0

# Pausa en segundos entre cada ida y vuelta.
@export var wait_time: float = 1.0

# Ruta al nodo AnimatedSprite2D del NPC.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_RIGHT: String = "Derecha"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"

# Punto de origen (posición inicial del NPC al entrar en escena).
var _point_a: Vector2 = Vector2.ZERO
# Punto destino (posición inicial + offset configurado).
var _point_b: Vector2 = Vector2.ZERO
# Punto objetivo actual.
var _target: Vector2 = Vector2.ZERO
# Indica si el NPC está en pausa entre segmentos.
var _waiting: bool = false


# Registra los puntos A y B y establece B como primer destino.
func _ready() -> void:
	_point_a = global_position
	_point_b = global_position + destination_offset
	_target = _point_b


# Mueve al NPC hacia el objetivo actual.
# Cuando llega, espera `wait_time` segundos y alterna de objetivo.
func _physics_process(_delta: float) -> void:
	if _waiting:
		return

	var distance := global_position.distance_to(_target)

	if distance <= arrival_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_animation(ANIMATION_IDLE)
		_switch_target()
		return

	var direction := (_target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	_play_animation_by_direction(direction)


# Alterna entre punto A y punto B tras esperar `wait_time` segundos.
func _switch_target() -> void:
	_waiting = true
	_target = _point_a if _target.is_equal_approx(_point_b) else _point_b
	await get_tree().create_timer(wait_time).timeout
	# Verificar que el nodo sigue en el árbol antes de continuar
	# (puede haber sido liberado mientras esperaba).
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_waiting = false


# Reproduce la animación indicada en el AnimatedSprite2D con seguridad.
func _play_animation(anim_name: String) -> void:
	var sprite := get_node_or_null(animation_player_path) as AnimatedSprite2D
	if sprite == null:
		return
	if sprite.sprite_frames == null:
		return
	var target_anim := StringName(anim_name)
	if not sprite.sprite_frames.has_animation(target_anim):
		return
	if sprite.animation == target_anim and sprite.is_playing():
		return
	sprite.play(target_anim)


# Selecciona la animación correcta según la dirección de movimiento.
func _play_animation_by_direction(dir: Vector2) -> void:
	if dir.x < -0.5:
		_play_animation(ANIMATION_LEFT)
	elif dir.x > 0.5:
		_play_animation(ANIMATION_RIGHT)
	elif dir.y < -0.5:
		_play_animation(ANIMATION_UP)
	elif dir.y > 0.5:
		_play_animation(ANIMATION_DOWN)
