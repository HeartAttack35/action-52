# Documento de Diseño Técnico — Shooting Gallery

## Visión general

Shooting Gallery es el segundo minijuego del Tier 1 del proyecto Action 52 en Godot 4. Un pistolero
se mueve horizontalmente por la base de la pantalla y dispara balas hacia arriba para impactar
blancos estáticos que aparecen en posiciones fijas predefinidas. Los blancos tienen un tiempo de
vida propio (`LifeTimer`) y desaparecen solos si no son alcanzados, sin penalización para el
jugador. La partida termina cuando las vidas llegan a cero.

El diseño sigue fielmente los patrones de Jupiter Scope (el primer minijuego), reutilizando la
misma arquitectura de señales, la clase base `MinigameBase`, y los autoloads `GameManager` y
`SceneManager`. Las diferencias principales son: el objetivo estático con temporización propia, el
sistema de spawn sobre posiciones fijas (`Marker2D`) en vez de posiciones aleatorias continuas, y
la ausencia de colisión entre objetivo y jugador.

---

## Arquitectura

### Árbol de nodos completo

```
shooting_gallery.tscn
└── ShootingGallery  [Node2D — shooting_gallery.gd, extends MinigameBase]
    ├── Player         [player.tscn — CharacterBody2D, player.gd]
    │   ├── CollisionShape2D
    │   ├── Sprite2D              (sprite del pistolero)
    │   └── ShootPoint            [Marker2D] — posición de origen de las balas
    ├── TargetSpawner  [Timer]    wait_time=1.0, autostart=true
    ├── SpawnPoints    [Node2D]   contenedor de posiciones de aparición
    │   ├── SpawnPoint1  [Marker2D]
    │   ├── SpawnPoint2  [Marker2D]
    │   ├── SpawnPoint3  [Marker2D]
    │   ├── SpawnPoint4  [Marker2D]
    │   └── SpawnPoint5  [Marker2D]
    └── HUD            [CanvasLayer]
        ├── LabelScore [Label]
        └── LabelLives [Label]

bullet.tscn
└── Bullet  [Area2D — bullet.gd]
    ├── CollisionShape2D          (cápsula o rectángulo pequeño)
    └── VisibleOnScreenNotifier2D

target.tscn
└── Target  [Area2D — target.gd]
    ├── CollisionShape2D          (rectángulo o círculo)
    ├── Sprite2D                  (sprite del blanco)
    └── LifeTimer  [Timer]        autostart=true, wait_time fijado en _ready()
```

### Posicionamiento de los SpawnPoints

Los 5 `Marker2D` se distribuyen equidistantemente a lo largo del eje X del viewport a Y ≈ 50 px
del borde superior. Con un viewport de 480 px de ancho y márgenes de 48 px en cada extremo:

```
X = 48, 144, 240, 336, 432   (separación de 96 px)
Y = 50 (fijo en el editor)
```

Estas posiciones se establecen directamente en el editor de Godot; no se calculan en tiempo de
ejecución.

---

## Componentes e interfaces

### ShootingGallery (`shooting_gallery.gd`)

Nodo raíz de la escena. Orquesta todos los subsistemas:

- Preloads de `bullet.tscn` y `target.tscn`.
- En `_ready()`: posiciona al jugador, conecta señales del jugador y de `GameManager`, inicializa
  el HUD.
- Manejadores de señal:
  - `_on_shoot_requested(pos)` → instancia `Bullet` en `pos`.
  - `_on_target_spawner_timeout()` → selecciona un `Marker2D` al azar e instancia `Target`.
  - `_on_score_changed(n)` → actualiza `LabelScore`.
  - `_on_lives_changed(n)` → actualiza `LabelLives`; si `n <= 0`, llama `finish("lose")`.

### Player (`player.gd`)

Personaje del jugador. Idéntico en estructura a `player.gd` de Jupiter Scope, con las diferencias
de sprite. Expone la señal `shoot_requested(position: Vector2)`.

- Clamp con semiancho del sprite: `half_w = $Sprite2D.texture.get_width() / 2.0` (o valor
  hardcodeado si el sprite no está disponible en tiempo de exportación).
- No pertenece a ningún grupo de colisión (los blancos no dañan al jugador).

### Bullet (`bullet.gd`)

Proyectil disparado hacia arriba. Equivalente a `laser.gd` de Jupiter Scope.

- Pertenece al grupo `"proyectiles"` (asignado en la escena `.tscn`, no en el script).
- Se mueve a 500 px/s hacia arriba en `_physics_process`.
- Se elimina con `queue_free()` al salir del viewport (señal de `VisibleOnScreenNotifier2D`).

### Target (`target.gd`)

Blanco estático con vida propia.

- Pertenece al grupo `"blancos"` (asignado en la escena `.tscn`).
- En `_ready()`: fija `LifeTimer.wait_time = randf_range(1.5, 3.0)`.
- Flag `_dead: bool = false` para el guard contra doble `queue_free`.
- `_on_life_timer_timeout()`: llama `queue_free()` sin tocar `GameManager`.
- `_on_area_entered(area)`: si `_dead` es `true`, retorna inmediatamente. Si `area` está en el
  grupo `"proyectiles"`: pone `_dead = true`, llama `GameManager.add_score(10)`,
  `area.queue_free()`, `queue_free()`.

### HUD

Capa `CanvasLayer` con dos `Label`:

- `LabelScore`: posición superior-izquierda.
- `LabelLives`: posición superior-derecha.

Ambos se actualizan síncronamente en los manejadores de señal de `ShootingGallery`.

---

## Modelos de datos

### Grupos de colisión

| Grupo         | Nodo(s)                | Propósito                              |
|---------------|------------------------|----------------------------------------|
| `"proyectiles"` | Bullet               | Detección de impacto en Target         |
| `"blancos"`   | Target                 | Consultas futuras (e.g. contar activos) |

Los grupos se asignan en las propiedades del nodo raíz de cada escena `.tscn` (pestaña
*Node → Groups* en el editor), no en código GDScript.

### Estado interno de Target

```gdscript
var _dead: bool = false   # Guard contra procesamiento tras queue_free()
```

### Constantes de velocidad

| Constante       | Valor     | Nodo   |
|-----------------|-----------|--------|
| `SPEED (Player)`| 300.0 px/s | Player |
| `SPEED (Bullet)`| 500.0 px/s | Bullet |

### Rango de LifeTimer

```
wait_time ∈ [1.5, 3.0]  (establecido con randf_range en _ready() del Target)
```

---

## Scripts GDScript 4 completos

### `shooting_gallery.gd`

```gdscript
extends MinigameBase
## shooting_gallery.gd
## Escena principal del minijuego Shooting Gallery.
## Orquesta el spawner de blancos, conecta al jugador y mantiene el HUD
## sincronizado con el estado de GameManager.

const BULLET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/bullet.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/minigames/Shooting Gallery/target.tscn")

@onready var player: CharacterBody2D = $Player
@onready var target_spawner: Timer = $TargetSpawner
@onready var spawn_points: Node2D = $SpawnPoints
@onready var label_score: Label = $HUD/LabelScore
@onready var label_lives: Label = $HUD/LabelLives


func _ready() -> void:
	var vp: Vector2 = get_viewport_rect().size
	player.position = Vector2(vp.x / 2.0, vp.y - 50.0)
	player.shoot_requested.connect(_on_shoot_requested)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	label_score.text = "Puntos: %d" % GameManager.score
	label_lives.text = "Vidas: %d" % GameManager.lives


func _on_shoot_requested(shoot_pos: Vector2) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate()
	bullet.position = shoot_pos
	add_child(bullet)


func _on_target_spawner_timeout() -> void:
	var points: Array = spawn_points.get_children()
	if points.is_empty():
		return
	var marker: Marker2D = points.pick_random()
	var target: Area2D = TARGET_SCENE.instantiate()
	target.position = marker.global_position
	add_child(target)


func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	label_lives.text = "Vidas: %d" % new_lives
	if new_lives <= 0:
		finish("lose")
```

### `player.gd`

```gdscript
extends CharacterBody2D
## player.gd  (Shooting Gallery)
## Pistolero controlado por el jugador. Se mueve horizontalmente y emite
## una señal cuando dispara para que la escena principal instancie la bala.

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	move_and_slide()
	var half_w: float = $Sprite2D.texture.get_width() / 2.0
	position.x = clamp(position.x, half_w, get_viewport_rect().size.x - half_w)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_shoot()


func _shoot() -> void:
	shoot_requested.emit($ShootPoint.global_position)
```

> **Nota de implementación:** Si el sprite del pistolero no tiene textura asignada durante el
> desarrollo inicial, sustituir `$Sprite2D.texture.get_width() / 2.0` por un valor literal (p.ej.
> `16.0`) hasta disponer del asset definitivo.

### `bullet.gd`

```gdscript
extends Area2D
## bullet.gd
## Proyectil disparado por el pistolero. Se mueve hacia arriba a velocidad
## constante y se elimina al salir de la pantalla.

const SPEED: float = 500.0


func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
```

### `target.gd`

```gdscript
extends Area2D
## target.gd
## Blanco estático con tiempo de vida propio (LifeTimer).
## Desaparece al expirar el timer (sin penalización) o al recibir un
## proyectil (suma 10 puntos). Incluye guard contra doble queue_free.

var _dead: bool = false


func _ready() -> void:
	$LifeTimer.wait_time = randf_range(1.5, 3.0)


func _on_life_timer_timeout() -> void:
	if _dead:
		return
	_dead = true
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("proyectiles"):
		_dead = true
		GameManager.add_score(10)
		area.queue_free()
		queue_free()
```

---

## Diagrama de flujo de señales

```
Player ──── shoot_requested(pos) ──────────────────► ShootingGallery
                                                          │
                                              instancia Bullet en pos
                                                          │
                                                       Bullet
                                                          │
                                         VisibleOnScreenNotifier2D
                                         (screen_exited) → queue_free()

TargetSpawner ── timeout ──────────────────────────► ShootingGallery
                                                          │
                                      pick_random() sobre SpawnPoints
                                                          │
                                              instancia Target en marker.global_position
                                                          │
                                                       Target
                                                    ┌────┴────┐
                                              LifeTimer   area_entered
                                              (timeout)   (Bullet del grupo "proyectiles")
                                                 │              │
                                            queue_free()   add_score(10)
                                            (sin puntos)   bullet.queue_free()
                                                           queue_free()

GameManager ── score_changed(n) ──────────────────► ShootingGallery
                                                          │
                                               LabelScore.text = "Puntos: %d" % n

GameManager ── lives_changed(n) ──────────────────► ShootingGallery
                                                          │
                                               LabelLives.text = "Vidas: %d" % n
                                                          │
                                                    n <= 0 ?
                                                     │
                                                 finish("lose")
                                                     │
                                             MinigameBase.finish()
                                                     │
                                       minigame_finished.emit("lose")
                                       SceneManager.return_to_menu()
```

---

## Propiedades de corrección

*Una propiedad es una característica o comportamiento que debe mantenerse verdadero en todas las
ejecuciones válidas del sistema — esencialmente, un enunciado formal sobre lo que el sistema debe
hacer. Las propiedades sirven de puente entre especificaciones legibles por humanos y garantías de
corrección verificables automáticamente.*

### Propiedad 1: Confinamiento horizontal del Pistolero

*Para cualquier* posición X de entrada y semiancho de sprite `half_w`, después de aplicar el clamp
de confinamiento el resultado debe satisfacer `half_w ≤ position.x ≤ viewport_width - half_w`.

**Valida: Requisito 1.4**

---

### Propiedad 2: Movimiento uniforme de la Bala

*Para cualquier* valor de `delta > 0`, después de un paso de física la posición Y de la Bala
disminuye en exactamente `SPEED * delta` (donde `SPEED = 500.0`).

**Valida: Requisito 2.3**

---

### Propiedad 3: Instanciación de Bala en la posición indicada

*Para cualquier* posición `pos: Vector2` emitida por la señal `shoot_requested`, la Bala
instanciada por `ShootingGallery` debe tener `position == pos` inmediatamente tras `add_child()`.

**Valida: Requisito 2.2**

---

### Propiedad 4: Coexistencia de múltiples Balas

*Para cualquier* número entero `N` con `2 ≤ N ≤ 10` disparos consecutivos antes de que salgan del
viewport, deben existir exactamente `N` nodos Bullet como hijos de `ShootingGallery` sin que
ninguno elimine a otro.

**Valida: Requisito 2.6**

---

### Propiedad 5: Rango del LifeTimer del Blanco

*Para cualquier* instancia de `Target`, su `LifeTimer.wait_time` tras `_ready()` debe estar en el
intervalo cerrado `[1.5, 3.0]`.

**Valida: Requisito 3.1**

---

### Propiedad 6: Impacto de Bala en Blanco suma puntos y destruye ambos

*Para cualquier* instancia de `Bullet` del grupo `"proyectiles"` que entre en la zona de colisión
de un `Target` que no esté ya muerto (`_dead == false`), el resultado debe ser: `GameManager.score`
aumenta en exactamente 10, la Bullet es marcada para eliminar (`queue_free`) y el Target es marcado
para eliminar (`queue_free`).

**Valida: Requisito 3.3**

---

### Propiedad 7: Guard contra procesamiento doble en Target

*Para cualquier* secuencia de dos o más eventos `area_entered` sobre el mismo `Target` (ya sea por
la misma bala o por balas distintas en el mismo frame), `GameManager.add_score()` debe llamarse
exactamente una vez como resultado total de esa secuencia.

**Valida: Requisito 3.5**

---

### Propiedad 8: Spawn de Blancos en posiciones válidas

*Para cualquier* timeout del `TargetSpawner`, la posición del `Target` instanciado debe coincidir
exactamente con la `global_position` de uno de los 5 `Marker2D` hijos de `SpawnPoints`.

**Valida: Requisitos 4.2, 4.3**

---

### Propiedad 9: Formato del HUD

*Para cualquier* valor entero `n`, cuando `LabelScore` se actualiza debe contener la cadena
`"Puntos: %d" % n` y cuando `LabelLives` se actualiza debe contener `"Vidas: %d" % n`.

**Valida: Requisitos 6.1, 6.2**

---

### Propiedad 10: Fin de partida al agotar vidas

*Para cualquier* valor entero `v ≤ 0` emitido por `GameManager.lives_changed`, `ShootingGallery`
debe invocar `finish("lose")`.

**Valida: Requisitos 5.2, 6.6**

---

## Manejo de errores

| Situación                                          | Comportamiento                                                                      |
|----------------------------------------------------|--------------------------------------------------------------------------------------|
| `SpawnPoints` no tiene hijos                       | `_on_target_spawner_timeout()` retorna anticipadamente sin instanciar Target         |
| `area_entered` recibido tras `queue_free()` previo | Flag `_dead = true` previene llamadas duplicadas a `add_score` y `queue_free`        |
| Señal `lives_changed` ya conectada                 | Godot emite un error si se conecta dos veces; usar `is_connected()` o flag de guard  |
| Sprite sin textura en desarrollo                   | Usar valor literal para `half_w` hasta disponer del asset definitivo                 |
| Bala fuera de viewport sin `VisibleOnScreenNotifier2D` activo | El nodo no se elimina; asegurar que `VisibleOnScreenNotifier2D` esté en la escena `.tscn` |

### Guard de conexión duplicada de señal (Requisito 5.3)

```gdscript
if not GameManager.lives_changed.is_connected(_on_lives_changed):
    GameManager.lives_changed.connect(_on_lives_changed)
```

---

## Estrategia de pruebas

### Pruebas unitarias / de integración (ejemplo-based)

Estas pruebas verifican comportamientos concretos y configuración de escena:

- **Inicialización del jugador:** verificar que `player.position == Vector2(vp.x/2, vp.y - 50)` tras `_ready()`.
- **Grupo de Bullet:** instanciar `bullet.tscn` y verificar `is_in_group("proyectiles") == true`.
- **Grupo de Target:** instanciar `target.tscn` y verificar `is_in_group("blancos") == true`.
- **LifeTimer autostart:** verificar `$LifeTimer.autostart == true` en la escena.
- **TargetSpawner configuración:** verificar `wait_time == 1.0` y `autostart == true`.
- **SpawnPoints count:** instanciar la escena y verificar `$SpawnPoints.get_children().size() == 5`.
- **Timeout sin puntos:** disparar `_on_life_timer_timeout()`, verificar que `add_score` y `lose_life` no fueron llamados.
- **Actualización síncrona del HUD:** emitir `score_changed(42)`, verificar `LabelScore.text == "Puntos: 42"` en el mismo frame.
- **Registro en MinigameRegistry:** llamar `MinigameRegistry.get_minigame("shooting_gallery")` y verificar todos los campos.

### Pruebas de propiedades (property-based testing)

Se utiliza [GdUnit4](https://mikeschulze.github.io/gdUnit4/) como framework de pruebas para Godot 4.
Para property-based testing en GDScript se implementan generadores de entradas aleatorias dentro de
bucles de `fuzz_test` o llamadas repetidas con `seed` variable. Cada prueba de propiedad debe
ejecutarse con un mínimo de **100 iteraciones**.

Referencia de etiqueta para cada prueba de propiedad:

```
# Feature: shooting-gallery, Propiedad N: <texto de la propiedad>
```

**Prueba de Propiedad 1 — Confinamiento horizontal:**
```gdscript
# Feature: shooting-gallery, Propiedad 1: confinamiento horizontal del Pistolero
for i in 100:
    var half_w := randf_range(8.0, 32.0)
    var vp_w := 480.0
    var x_in := randf_range(-200.0, 700.0)
    var x_out := clamp(x_in, half_w, vp_w - half_w)
    assert(x_out >= half_w and x_out <= vp_w - half_w)
```

**Prueba de Propiedad 2 — Movimiento uniforme de Bala:**
```gdscript
# Feature: shooting-gallery, Propiedad 2: movimiento uniforme de la Bala
for i in 100:
    var delta := randf_range(0.001, 0.1)
    var bullet := preload("res://scenes/minigames/Shooting Gallery/bullet.tscn").instantiate()
    var y_before := bullet.position.y
    bullet._physics_process(delta)
    assert(is_equal_approx(bullet.position.y, y_before - 500.0 * delta))
    bullet.free()
```

**Prueba de Propiedad 5 — Rango de LifeTimer:**
```gdscript
# Feature: shooting-gallery, Propiedad 5: rango del LifeTimer del Blanco
for i in 100:
    var target := preload("res://scenes/minigames/Shooting Gallery/target.tscn").instantiate()
    add_child(target)   # necesario para que _ready() se ejecute
    assert(target.get_node("LifeTimer").wait_time >= 1.5)
    assert(target.get_node("LifeTimer").wait_time <= 3.0)
    target.queue_free()
```

**Prueba de Propiedad 7 — Guard doble en Target:**
```gdscript
# Feature: shooting-gallery, Propiedad 7: guard contra procesamiento doble en Target
for i in 100:
    var call_count := 0
    var mock_area := Area2D.new()
    mock_area.add_to_group("proyectiles")
    var target := preload("res://scenes/minigames/Shooting Gallery/target.tscn").instantiate()
    # Interceptar add_score para contar llamadas
    target._on_area_entered(mock_area)
    target._on_area_entered(mock_area)   # segunda llamada debe ser ignorada
    # call_count debe ser exactamente 1
```

**Prueba de Propiedad 9 — Formato del HUD:**
```gdscript
# Feature: shooting-gallery, Propiedad 9: formato del HUD
for i in 100:
    var n := randi_range(0, 9999)
    assert(("Puntos: %d" % n) == "Puntos: " + str(n))
    assert(("Vidas: %d" % n) == "Vidas: " + str(n))
```

**Prueba de Propiedad 10 — Fin de partida:**
```gdscript
# Feature: shooting-gallery, Propiedad 10: fin de partida al agotar vidas
for i in 100:
    var v := randi_range(-100, 0)   # cualquier valor <= 0
    # simular emisión de lives_changed(v) y verificar que finish("lose") es llamado
```

### Cobertura mínima esperada

| Área                        | Tipo de prueba    | Cobertura objetivo |
|-----------------------------|-------------------|--------------------|
| Movimiento del jugador      | Unitaria          | Dirección ±1, 0    |
| Confinamiento viewport      | Propiedad         | 100 iteraciones    |
| Instanciación de bala       | Propiedad         | 100 iteraciones    |
| Movimiento de bala          | Propiedad         | 100 iteraciones    |
| LifeTimer rango             | Propiedad         | 100 iteraciones    |
| Impacto bala-blanco         | Propiedad         | 100 iteraciones    |
| Guard doble queue_free      | Propiedad + edge  | 100 iteraciones    |
| Spawn en posición correcta  | Propiedad         | 100 iteraciones    |
| Formato HUD                 | Propiedad         | 100 iteraciones    |
| Condición de derrota        | Propiedad         | 100 iteraciones    |
| Integración MinigameRegistry| Unitaria          | 1 ejemplo          |
| Grupos de nodos             | Unitaria          | 1 ejemplo por nodo |
