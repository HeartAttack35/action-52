# Plan de implementación: Shooting Gallery

## Descripción general

Implementación del minijuego Shooting Gallery para el proyecto Action 52 en Godot 4. Se crean
cuatro escenas nuevas (`bullet`, `target`, `player`, `shooting_gallery`) siguiendo exactamente los
mismos patrones de Jupiter Scope y se registra el juego en `MinigameRegistry`.

El lenguaje de implementación es **GDScript 4**.

---

## Tareas

- [x] 1. Crear el script y la escena de la Bala
  - [x] 1.1 Crear `bullet.gd` en `res://scenes/minigames/Shooting Gallery/`
    - Extender `Area2D`
    - Declarar constante `SPEED = 500.0`
    - Implementar `_physics_process(delta)`: decrementar `position.y` en `SPEED * delta`
    - Implementar `_on_visible_on_screen_notifier_2d_screen_exited()`: llamar `queue_free()`
    - _Requisitos: 2.3, 2.4_

  - [x] 1.2 Crear `bullet.tscn` con árbol de nodos correcto
    - Nodo raíz: `Area2D` con nombre `Bullet`, script `bullet.gd`
    - Añadir nodo hijo `CollisionShape2D` con forma `RectangleShape2D` pequeña
    - Añadir nodo hijo `VisibleOnScreenNotifier2D`
    - Asignar el grupo `"proyectiles"` al nodo raíz (pestaña Node → Groups del editor)
    - Conectar la señal `screen_exited` de `VisibleOnScreenNotifier2D` a `_on_visible_on_screen_notifier_2d_screen_exited`
    - _Requisitos: 2.4, 2.5_

  - [x] 1.3 Escribir test de propiedad para el movimiento uniforme de la Bala
    - **Propiedad 2: Movimiento uniforme de la Bala**
    - Iterar 100 veces con `delta` aleatorio en `[0.001, 0.1]`
    - Verificar `is_equal_approx(bullet.position.y, y_before - 500.0 * delta)`
    - **Valida: Requisito 2.3**

  - [x] 1.4 Escribir test unitario de grupo para la Bala
    - Instanciar `bullet.tscn` y verificar `is_in_group("proyectiles") == true`
    - _Requisitos: 2.5_

- [x] 2. Crear el script y la escena del Blanco
  - [x] 2.1 Crear `target.gd` en `res://scenes/minigames/Shooting Gallery/`
    - Extender `Area2D`
    - Declarar variable `_dead: bool = false`
    - Implementar `_ready()`: fijar `$LifeTimer.wait_time = randf_range(1.5, 3.0)`
    - Implementar `_on_life_timer_timeout()`: retornar si `_dead`; poner `_dead = true`; llamar `queue_free()`
    - Implementar `_on_area_entered(area)`: retornar si `_dead`; si `area.is_in_group("proyectiles")`, poner `_dead = true`, llamar `GameManager.add_score(10)`, `area.queue_free()`, `queue_free()`
    - _Requisitos: 3.1, 3.2, 3.3, 3.5_

  - [x] 2.2 Crear `target.tscn` con árbol de nodos correcto
    - Nodo raíz: `Area2D` con nombre `Target`, script `target.gd`
    - Añadir nodo hijo `CollisionShape2D` con forma `RectangleShape2D`
    - Añadir nodo hijo `Sprite2D` (placeholder o sprite de blanco)
    - Añadir nodo hijo `LifeTimer` (`Timer`): `autostart = true`, `wait_time = 2.0` (se sobreescribe en `_ready()`)
    - Asignar el grupo `"blancos"` al nodo raíz
    - Conectar la señal `timeout` de `LifeTimer` a `_on_life_timer_timeout`
    - Conectar la señal `area_entered` del nodo raíz a `_on_area_entered`
    - _Requisitos: 3.1, 3.4_

  - [x] 2.3 Escribir test de propiedad para el rango de LifeTimer del Blanco
    - **Propiedad 5: Rango del LifeTimer del Blanco**
    - Iterar 100 veces: instanciar `target.tscn`, añadirlo como hijo para ejecutar `_ready()`, verificar `wait_time >= 1.5` y `wait_time <= 3.0`
    - **Valida: Requisito 3.1**

  - [x] 2.4 Escribir test de propiedad para el guard contra procesamiento doble
    - **Propiedad 7: Guard contra procesamiento doble en Target**
    - Iterar 100 veces: crear `Area2D` en grupo `"proyectiles"`, llamar `_on_area_entered` dos veces sobre el mismo Target, verificar que `GameManager.add_score` se invoca exactamente una vez
    - **Valida: Requisito 3.5**

  - [x] 2.5 Escribir test de propiedad de instanciación de Bala en posición indicada
    - **Propiedad 3: Instanciación de Bala en la posición indicada**
    - Iterar 100 veces con `pos: Vector2` aleatoria; instanciar Bullet, asignar `position = pos`, verificar `position == pos`
    - **Valida: Requisito 2.2**

  - [x] 2.6 Escribir test de propiedad de coexistencia de múltiples Balas
    - **Propiedad 4: Coexistencia de múltiples Balas**
    - Iterar con N en `[2, 10]`: instanciar N Bullets como hijos de ShootingGallery; verificar que los N nodos existen sin interferir entre sí
    - **Valida: Requisito 2.6**

  - [x] 2.7 Escribir test unitario de grupo para el Blanco
    - Instanciar `target.tscn` y verificar `is_in_group("blancos") == true`
    - _Requisitos: 3.4_

- [x] 3. Crear el script y la escena del Pistolero
  - [x] 3.1 Crear `player.gd` en `res://scenes/minigames/Shooting Gallery/`
    - Extender `CharacterBody2D`
    - Declarar constante `SPEED = 300.0`
    - Declarar señal `shoot_requested(position: Vector2)`
    - Implementar `_physics_process(_delta)`: obtener dirección con `Input.get_axis("ui_left","ui_right")`, asignar `velocity.x = direction * SPEED`, llamar `move_and_slide()`, aplicar clamp con semiancho del sprite
    - Implementar `_process(_delta)`: si `Input.is_action_just_pressed("ui_accept")`, llamar `_shoot()`
    - Implementar `_shoot()`: emitir `shoot_requested.emit($ShootPoint.global_position)`
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 2.1_

  - [x] 3.2 Crear `player.tscn` con árbol de nodos correcto
    - Nodo raíz: `CharacterBody2D` con nombre `Player`, script `player.gd`
    - Añadir nodo hijo `CollisionShape2D` con forma `CapsuleShape2D`
    - Añadir nodo hijo `Sprite2D` (placeholder o sprite de pistolero)
    - Añadir nodo hijo `ShootPoint` (`Marker2D`) en posición `(0, -20)`
    - _Requisitos: 1.4, 2.1_

  - [x] 3.3 Escribir test de propiedad para el confinamiento horizontal del Pistolero
    - **Propiedad 1: Confinamiento horizontal del Pistolero**
    - Iterar 100 veces con `half_w` aleatorio en `[8.0, 32.0]` y `x_in` en `[-200.0, 700.0]`
    - Verificar `clamp(x_in, half_w, 480.0 - half_w) >= half_w` y `<= 480.0 - half_w`
    - **Valida: Requisito 1.4**

- [x] 4. Checkpoint — Verificar scripts individuales
  - Asegurar que todos los tests pasen hasta este punto. Consultar al usuario si hay dudas.

- [ ] 5. Crear la escena principal y el script del minijuego
  - [x] 5.1 Crear `shooting_gallery.gd` en `res://scenes/minigames/Shooting Gallery/`
    - Extender `MinigameBase`
    - Declarar `const BULLET_SCENE` y `const TARGET_SCENE` con `preload`
    - Declarar referencias `@onready` para `Player`, `TargetSpawner`, `SpawnPoints`, `LabelScore`, `LabelLives`
    - Implementar `_ready()`: posicionar al Pistolero, conectar señal `player.shoot_requested`, conectar `GameManager.score_changed`, conectar `GameManager.lives_changed` con guard `is_connected()`, inicializar textos del HUD
    - Implementar `_on_shoot_requested(shoot_pos)`: instanciar Bullet y añadirlo como hijo
    - Implementar `_on_target_spawner_timeout()`: obtener hijos de `SpawnPoints`, retornar si vacío, elegir un `Marker2D` con `pick_random()`, instanciar Target en `marker.global_position`
    - Implementar `_on_score_changed(new_score)`: actualizar `LabelScore.text`
    - Implementar `_on_lives_changed(new_lives)`: actualizar `LabelLives.text`; si `new_lives <= 0`, llamar `finish("lose")`
    - _Requisitos: 1.5, 2.2, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 7.1_

  - [x] 5.2 Crear `shooting_gallery.tscn` con árbol de nodos completo
    - Nodo raíz: `Node2D` con nombre `ShootingGallery`, script `shooting_gallery.gd`
    - Añadir instancia de `player.tscn` como hijo con nombre `Player`
    - Añadir nodo `TargetSpawner` (`Timer`): `wait_time = 1.0`, `autostart = true`; conectar señal `timeout` a `_on_target_spawner_timeout`
    - Añadir nodo `SpawnPoints` (`Node2D`) con 5 hijos `Marker2D` en posiciones `(48,50)`, `(144,50)`, `(240,50)`, `(336,50)`, `(432,50)`
    - Añadir nodo `HUD` (`CanvasLayer`) con hijos `LabelScore` y `LabelLives` en esquinas superior-izquierda y superior-derecha respectivamente
    - _Requisitos: 4.1, 4.5, 7.3_

  - [-] 5.3 Escribir test de propiedad para el spawn de Blancos en posiciones válidas
    - **Propiedad 8: Spawn de Blancos en posiciones válidas**
    - Iterar 100 veces: simular `_on_target_spawner_timeout()`, verificar que la posición del Target instanciado coincide con la `global_position` de uno de los 5 `Marker2D`
    - **Valida: Requisitos 4.2, 4.3**

  - [-] 5.4 Escribir test de propiedad para el formato del HUD
    - **Propiedad 9: Formato del HUD**
    - Iterar 100 veces con `n` entero aleatorio en `[0, 9999]`
    - Verificar `"Puntos: %d" % n == "Puntos: " + str(n)` y `"Vidas: %d" % n == "Vidas: " + str(n)`
    - **Valida: Requisitos 6.1, 6.2**

  - [-] 5.5 Escribir test de propiedad para la condición de fin de partida
    - **Propiedad 10: Fin de partida al agotar vidas**
    - Iterar 100 veces con `v` entero aleatorio en `[-100, 0]`
    - Verificar que `_on_lives_changed(v)` invoca `finish("lose")`
    - **Valida: Requisitos 5.2, 6.6**

  - [-] 5.6 Escribir tests unitarios de inicialización y configuración de escena
    - Verificar que `player.position == Vector2(vp.x/2, vp.y - 50)` tras `_ready()`
    - Verificar `TargetSpawner.wait_time == 1.0` y `TargetSpawner.autostart == true`
    - Verificar `SpawnPoints.get_children().size() == 5`
    - Verificar que `LabelScore` y `LabelLives` muestran valores iniciales correctos de `GameManager`
    - _Requisitos: 1.5, 4.1, 4.5, 6.5_

- [ ] 6. Registrar el minijuego en MinigameRegistry
  - [-] 6.1 Actualizar `autoloads/minigame_registry.gd`
    - Añadir la entrada `{ "id": "shooting_gallery", "name": "Shooting Gallery", "scene": "res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn", "tier": 1 }` después de la entrada de `jupiter_scope`
    - _Requisitos: 7.2_

  - [x] 6.2 Escribir test unitario de integración con MinigameRegistry
    - Llamar `MinigameRegistry.get_minigame("shooting_gallery")`
    - Verificar que el diccionario retornado contiene todos los campos: `id`, `name`, `scene`, `tier` con los valores correctos
    - _Requisitos: 7.2_

- [x] 7. Checkpoint final — Verificar integración completa
  - Asegurar que todos los tests pasen. Verificar que el minijuego aparece en el menú principal generado por `MinigameRegistry`. Consultar al usuario si hay dudas.

---

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para una implementación MVP más rápida.
- Los grupos de colisión (`"proyectiles"`, `"blancos"`) se asignan en el editor (pestaña Node → Groups), no en GDScript.
- El guard `is_connected()` para `lives_changed` es necesario para evitar el error de señal doblemente conectada (Requisito 5.3).
- Si el sprite del pistolero no tiene textura durante desarrollo, sustituir `$Sprite2D.texture.get_width() / 2.0` por el literal `16.0`.
- Los tests de propiedad deben ejecutarse con un mínimo de 100 iteraciones usando [GdUnit4](https://mikeschulze.github.io/gdUnit4/).
- Cada tarea de implementación referencia los requisitos específicos que valida para trazabilidad completa.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "3.1"] },
    { "id": 1, "tasks": ["1.2", "2.2", "3.2"] },
    { "id": 2, "tasks": ["1.3", "1.4", "2.3", "2.4", "2.5", "2.6", "2.7", "3.3"] },
    { "id": 3, "tasks": ["5.1"] },
    { "id": 4, "tasks": ["5.2"] },
    { "id": 5, "tasks": ["5.3", "5.4", "5.5", "5.6", "6.1"] },
    { "id": 6, "tasks": ["6.2"] }
  ]
}
```
