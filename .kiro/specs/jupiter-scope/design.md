# Documento de Diseño: Jupiter Scope

## Visión general de la arquitectura

Jupiter Scope es un shooter de pantalla fija que se integra en el sistema de autoloads del proyecto Action 52 en Godot 4. La arquitectura sigue el patrón ya establecido por `demo_minigame`: una escena raíz que extiende `MinigameBase`, delegando el estado global (vidas, puntuación, fin de partida) al singleton `GameManager`.

La comunicación entre el Jugador y el nivel usa señales para mantener el desacoplamiento: el Jugador emite `shoot_requested(position)` y la escena `JupiterScope` instancia el Láser.

```
[MinigameRegistry] ──registra──► "jupiter_scope" → jupiter_scope.tscn
[SceneManager]     ──carga──►    jupiter_scope.tscn
                                      │
                         ┌────────────▼────────────┐
                         │   JupiterScope (raíz)   │  extends MinigameBase
                         │   jupiter_scope.gd       │
                         └──┬──────┬──────┬────────┘
                            │      │      │
                       Player  MeteorSpawner  HUD (CanvasLayer)
                       (CBB2D) (Timer)        ├─ LabelScore
                            │                └─ LabelLives
                     emite: shoot_requested
                            │
                         [Laser] (instanciado en runtime)
                         [Meteor] (instanciado en runtime)
```

---

## Estructura de archivos

```
scenes/minigames/Jupiter Scope/
├── jupiter_scope.tscn      ← escena raíz (sobreescribir placeholder)
├── jupiter_scope.gd        ← script del nivel (sobreescribir placeholder)
├── player.tscn             ← escena del jugador (nueva)
├── player.gd               ← script del jugador (nuevo)
├── laser.tscn              ← escena del láser (nueva)
├── laser.gd                ← script del láser (nuevo)
├── meteor.tscn             ← escena del meteorito (nueva)
└── meteor.gd               ← script del meteorito (nuevo)
```

---

## Componentes

### 1. Jugador (`player.tscn` / `player.gd`)

**Tipo de nodo raíz:** `CharacterBody2D`

**Árbol de nodos:**
```
CharacterBody2D  (player.gd)
├── Sprite2D
├── CollisionShape2D  (RectangleShape2D)
└── Marker2D  (name: "ShootPoint", posición: ~(0, -30) sobre el sprite)
```

**Grupos:** `"jugador"`

**Script (`player.gd`):**

```gdscript
extends CharacterBody2D

const SPEED: float = 300.0

signal shoot_requested(position: Vector2)

func _physics_process(delta: float) -> void:
    var direction: float = Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * SPEED
    move_and_slide()
    var vp_width: float = get_viewport_rect().size.x
    position.x = clamp(position.x, 0.0, vp_width)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        _shoot()

func _shoot() -> void:
    shoot_requested.emit($ShootPoint.global_position)
```

---

### 2. Láser (`laser.tscn` / `laser.gd`)

**Tipo de nodo raíz:** `Area2D`

**Árbol de nodos:**
```
Area2D  (laser.gd)
├── Sprite2D
├── CollisionShape2D  (RectangleShape2D, ~4×16 px)
└── VisibleOnScreenNotifier2D
```

**Grupos:** `"proyectiles"`

**Script (`laser.gd`):**

```gdscript
extends Area2D

const SPEED: float = 500.0

func _physics_process(delta: float) -> void:
    position.y -= SPEED * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()
```

---

### 3. Meteorito (`meteor.tscn` / `meteor.gd`)

**Tipo de nodo raíz:** `Area2D`

**Árbol de nodos:**
```
Area2D  (meteor.gd)
├── Sprite2D
└── CollisionShape2D  (RectangleShape2D, ~20×20 px)
```

**Grupos:** `"meteoros"`

**Script (`meteor.gd`):**

```gdscript
extends Area2D

const SPEED: float = 150.0

func _physics_process(delta: float) -> void:
    position.y += SPEED * delta

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("proyectiles"):
        GameManager.add_score(10)
        area.queue_free()
        queue_free()
    elif area.is_in_group("jugador"):
        _hit_jugador()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("jugador"):
        _hit_jugador()

func _hit_jugador() -> void:
    GameManager.lose_life()
    queue_free()
```

> **Nota:** `lose_life()` en `GameManager` ya llama `SceneManager.game_over()` automáticamente si `lives <= 0`. La escena `JupiterScope` también escucha `lives_changed` para llamar `finish("lose")` de manera explícita, garantizando que la señal `minigame_finished` se emita antes de cambiar de escena.

---

### 4. Escena principal: JupiterScope (`jupiter_scope.tscn` / `jupiter_scope.gd`)

**Tipo de nodo raíz:** `Node2D` con script que extiende `MinigameBase`

**Árbol de nodos:**
```
Node2D  (jupiter_scope.gd, extends MinigameBase)
├── Player  (instancia de player.tscn)
├── MeteorSpawner  (Timer, wait_time=1.0, autostart=true)
└── HUD  (CanvasLayer)
    ├── LabelScore  (Label)
    └── LabelLives  (Label)
```

**Script (`jupiter_scope.gd`):**

```gdscript
extends MinigameBase

const METEOR_SCENE: PackedScene = preload("res://scenes/minigames/Jupiter Scope/meteor.tscn")

@onready var player: CharacterBody2D = $Player
@onready var meteor_spawner: Timer = $MeteorSpawner
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
    var laser: Area2D = LASER_SCENE.instantiate()
    laser.position = shoot_pos
    add_child(laser)

func _on_meteor_spawner_timeout() -> void:
    var meteor: Area2D = METEOR_SCENE.instantiate()
    var vp_width: float = get_viewport_rect().size.x
    meteor.position = Vector2(randf_range(0.0, vp_width), -20.0)
    add_child(meteor)

func _on_score_changed(new_score: int) -> void:
    label_score.text = "Puntos: %d" % new_score

func _on_lives_changed(new_lives: int) -> void:
    label_lives.text = "Vidas: %d" % new_lives
    if new_lives <= 0:
        finish("lose")
```

> **Nota:** `LASER_SCENE` se declara de forma análoga a `METEOR_SCENE` con `preload()` apuntando a `laser.tscn`.

---

### 5. Actualización del registro (`minigame_registry.gd`)

Reemplazar el bloque comentado con la entrada real:

```gdscript
{
    "id": "jupiter_scope",
    "name": "Jupiter Scope",
    "scene": "res://scenes/minigames/Jupiter Scope/jupiter_scope.tscn",
    "tier": 1,
},
```

---

## Modelos de datos

No se requieren recursos personalizados ni estructuras de datos complejas. El estado del juego (vidas, puntuación) reside íntegramente en `GameManager`. Los nodos instanciados en runtime (Láser, Meteorito) son efímeros y no persisten entre sesiones.

---

## Manejo de errores

| Situación | Comportamiento |
|---|---|
| `GameManager.lives` llega a 0 | `GameManager.lose_life()` invoca `SceneManager.game_over()` automáticamente → vuelve al menú. Adicionalmente, `JupiterScope._on_lives_changed(0)` llama `finish("lose")` para emitir la señal `minigame_finished`. |
| El jugador presiona ESC | `MinigameBase._unhandled_input()` llama `finish("quit")` → vuelve al menú. |
| Láser sale de pantalla | `VisibleOnScreenNotifier2D.screen_exited` libera el nodo. |
| Meteorito no destruido llega al fondo | No hay colisión con el fondo; el meteorito sigue descendiendo indefinidamente. Se puede añadir un `VisibleOnScreenNotifier2D` en una iteración futura para limpiarlo. |

---

## Propiedades de corrección

*Una propiedad es una característica o comportamiento que debe mantenerse como verdadero en todas las ejecuciones válidas del sistema — esencialmente, una declaración formal sobre lo que el sistema debe hacer. Las propiedades sirven como puente entre las especificaciones legibles por humanos y las garantías de corrección verificables automáticamente.*

### Propiedad 1: Confinamiento del Jugador al Viewport

*Para cualquier* velocidad de movimiento y cualquier tamaño de viewport, después de aplicar `move_and_slide()` y el clamp, la posición X del Jugador debe estar siempre en el rango `[0, viewport_width]`.

**Valida: Requisitos 1.3, 1.4**

---

### Propiedad 2: Movimiento ascendente del Láser

*Para cualquier* posición inicial del Láser y cualquier valor de `delta`, después de un frame de `_physics_process`, la nueva posición Y del Láser debe ser igual a `posición_inicial.y − 500 * delta`.

**Valida: Requisitos 2.3**

---

### Propiedad 3: Movimiento descendente del Meteorito

*Para cualquier* posición inicial del Meteorito y cualquier valor de `delta`, después de un frame de `_physics_process`, la nueva posición Y del Meteorito debe ser igual a `posición_inicial.y + 150 * delta`.

**Valida: Requisitos 3.2**

---

### Propiedad 4: Posición de spawn del Meteorito dentro del Viewport

*Para cualquier* ancho de viewport, la posición X asignada a un Meteorito recién instanciado debe estar en el rango `[0, viewport_width]`, y su posición Y debe ser `−20`.

**Valida: Requisitos 3.1**

---

### Propiedad 5: Puntuación aumenta al destruir un Meteorito

*Para cualquier* estado inicial de puntuación en `GameManager`, cuando un Láser colisiona con un Meteorito, la puntuación resultante debe ser exactamente `puntuación_inicial + 10`.

**Valida: Requisitos 4.1**

---

### Propiedad 6: Vidas decrementan al impactar al Jugador

*Para cualquier* estado inicial de vidas en `GameManager` con `lives > 0`, cuando un Meteorito colisiona con el Jugador, las vidas resultantes deben ser exactamente `vidas_iniciales − 1`.

**Valida: Requisitos 5.1**

---

### Propiedad 7: El HUD refleja el estado actual de GameManager

*Para cualquier* valor de puntuación emitido por `score_changed` y cualquier valor de vidas emitido por `lives_changed`, el texto de los labels del HUD debe contener exactamente los valores actuales de `GameManager.score` y `GameManager.lives` respectivamente.

**Valida: Requisitos 6.3, 6.4**

---

### Propiedad 8: Posición inicial del Jugador es dinámica al Viewport

*Para cualquier* tamaño de ventana al inicio de la escena, la posición del Jugador al ejecutar `_ready()` debe ser `(viewport_width / 2, viewport_height − 50)`.

**Valida: Requisitos 8.1**
