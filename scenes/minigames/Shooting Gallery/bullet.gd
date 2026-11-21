extends Area2D
## bullet.gd  (Shooting Gallery)
## Proyectil disparado por el pistolero.
##
## Llama a setup(direction) justo después de instanciar para configurar:
##   • Dirección de movimiento
##   • Rotación visual del sprite
##   • Forma de la hitbox según el ángulo:
##       horizontal  (vert = 0)  → rectángulo apaisado  (32 × 8)
##       diagonal    (vert ≠ 0)  → rectángulo cuadrado  (12 × 12), rotado 45°

const SPEED: float = 500.0

var _direction: Vector2 = Vector2(1.0, 0.0)


## Configura el proyectil a partir de una dirección normalizada.
## Debe llamarse antes de add_child() o en el mismo frame.
func setup(dir: Vector2) -> void:
	_direction = dir

	# --- Rotación visual: alinea el sprite con la dirección ---
	rotation = dir.angle()

	# --- Hitbox: ajusta la forma según si es horizontal o diagonal ---
	var shape_node: CollisionShape2D = $CollisionShape2D
	var rect := RectangleShape2D.new()

	if abs(dir.y) < 0.01:
		# Tiro horizontal puro → rectángulo apaisado (ancho × alto)
		rect.size = Vector2(32.0, 8.0)
		shape_node.position = Vector2.ZERO
		shape_node.rotation = 0.0
	else:
		# Tiro diagonal (45°) → rectángulo compacto, rotado 45°
		rect.size = Vector2(14.0, 14.0)
		shape_node.position = Vector2.ZERO
		shape_node.rotation = deg_to_rad(45.0)

	shape_node.shape = rect


func _physics_process(delta: float) -> void:
	position += _direction * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

