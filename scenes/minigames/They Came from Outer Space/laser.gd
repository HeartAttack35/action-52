extends Area2D
## laser.gd  (They Came from Outer Space)
## Proyectil con dirección arbitraria.
##
## Llama a setup(direction) antes de add_child() para configurar:
##   • Dirección de movimiento y rotación visual del nodo completo
##   • Hitbox y escala del sprite adaptados al eje de disparo:
##
##   Horizontal (←/→):  shape local (34×6)  → global ancho y plano
##                       sprite más ancho y bajo
##   Vertical   (↑/↓):  shape local (34×5)  → global fino y alto
##                       sprite más estrecho y alargado
##
## Nota: al rotar el nodo raíz, CollisionShape2D y Sprite2D rotan juntos.
## Una forma local (W, H) tras ±90° de rotación aparece como (H, W) global.

const SPEED: float = 550.0

var direction: Vector2 = Vector2.UP


## Configura el proyectil a partir de una dirección normalizada.
func setup(dir: Vector2) -> void:
	direction = dir

	# Rotar el nodo completo para alinear sprite y shape con la dirección.
	# Vector2.angle() devuelve el ángulo respecto al eje +X (derecha).
	#   UP   → -PI/2    RIGHT → 0    DOWN → PI/2    LEFT → PI
	rotation = dir.angle()

	var shape_node: CollisionShape2D = $CollisionShape2D
	var sprite: Sprite2D             = $Sprite2D
	var rect := RectangleShape2D.new()
	shape_node.position = Vector2.ZERO
	shape_node.rotation = 0.0

	if abs(dir.x) > 0.5:
		# ── Disparo HORIZONTAL (←/→) ─────────────────────────────────
		# Shape local (34, 6): node rot 0°/180° → global (34, 6) ancha y plana.
		rect.size = Vector2(34.0, 6.0)
		# Sprite más ancho y achatado para reflejar el impacto lateral.
		sprite.scale = Vector2(0.22, 0.09)
	else:
		# ── Disparo VERTICAL (↑/↓) ───────────────────────────────────
		# Shape local (34, 5): node rot ±90° → global (5, 34) fina y alta.
		rect.size = Vector2(34.0, 5.0)
		# Sprite más estrecho y alargado para un haz de precisión.
		sprite.scale = Vector2(0.09, 0.22)

	shape_node.shape = rect


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

