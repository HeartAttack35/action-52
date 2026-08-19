# Plan de Implementación: Jupiter Scope

## Visión general

Implementar el minijuego Jupiter Scope en GDScript 4, creando cuatro escenas (Jugador, Láser, Meteorito, nivel principal) y actualizando el registro de minijuegos. Cada paso construye sobre el anterior hasta tener el juego completamente integrado y funcional.

---

## Tareas

- [x] 1. Registrar Jupiter Scope en MinigameRegistry
  - Editar `autoloads/minigame_registry.gd` y reemplazar el bloque comentado con la entrada real de `jupiter_scope`.
  - La entrada debe tener `"id": "jupiter_scope"`, `"name": "Jupiter Scope"`, `"scene": "res://scenes/minigames/Jupiter Scope/jupiter_scope.tscn"`, `"tier": 1`.
  - _Requisitos: 9.1, 9.2_

- [x] 2. Implementar la escena Láser
  - [x] 2.1 Crear `laser.tscn` y `laser.gd` en `scenes/minigames/Jupiter Scope/`
    - Nodo raíz `Area2D` con `Sprite2D`, `CollisionShape2D` (RectangleShape2D ~4×16 px) y `VisibleOnScreenNotifier2D`.
    - Script: constante `SPEED = 500.0`, `_physics_process` mueve `position.y -= SPEED * delta`, callback `_on_visible_on_screen_notifier_2d_screen_exited` llama `queue_free()`.
    - Añadir al grupo `"proyectiles"`.
    - Conectar la señal `screen_exited` de `VisibleOnScreenNotifier2D` al método de limpieza.
    - _Requisitos: 2.3, 2.4_
  - [ ]* 2.2 Escribir test de propiedad para el movimiento del Láser
    - **Propiedad 2: Movimiento ascendente del Láser**
    - Para cualquier posición inicial Y y cualquier delta, verificar que `nueva_y == inicial_y - 500 * delta`.
    - **Valida: Requisito 2.3**

- [x] 3. Implementar la escena Jugador
  - [x] 3.1 Crear `player.tscn` y `player.gd` en `scenes/minigames/Jupiter Scope/`
    - Nodo raíz `CharacterBody2D` con `Sprite2D`, `CollisionShape2D` (RectangleShape2D) y `Marker2D` (name: `ShootPoint`, posición ~(0, -30) relativa al raíz).
    - Script: constante `SPEED = 300.0`, señal `shoot_requested(position: Vector2)`.
    - `_physics_process`: leer `Input.get_axis("ui_left", "ui_right")`, aplicar a `velocity.x`, llamar `move_and_slide()`, luego `position.x = clamp(position.x, 0.0, get_viewport_rect().size.x)`.
    - `_process`: si `Input.is_action_just_pressed("ui_accept")`, llamar `_shoot()`.
    - `_shoot()`: emitir `shoot_requested.emit($ShootPoint.global_position)`.
    - Añadir al grupo `"jugador"`.
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2_
  - [ ]* 3.2 Escribir test de propiedad para el confinamiento del Jugador
    - **Propiedad 1: Confinamiento del Jugador al Viewport**
    - Para cualquier posición X resultante del movimiento y cualquier ancho de viewport, verificar que `0 <= posicion_x <= viewport_width`.
    - **Valida: Requisitos 1.3, 1.4**

- [x] 4. Implementar la escena Meteorito
  - [x] 4.1 Crear `meteor.tscn` y `meteor.gd` en `scenes/minigames/Jupiter Scope/`
    - Nodo raíz `Area2D` con `Sprite2D` y `CollisionShape2D` (RectangleShape2D ~20×20 px).
    - Script: constante `SPEED = 150.0`, `_physics_process` mueve `position.y += SPEED * delta`.
    - Implementar `_on_area_entered(area)`: si `area.is_in_group("proyectiles")`, llamar `GameManager.add_score(10)`, `area.queue_free()`, `queue_free()`.
    - Implementar `_on_body_entered(body)`: si `body.is_in_group("jugador")`, llamar `_hit_jugador()`.
    - Implementar `_on_area_entered` también para el caso `area.is_in_group("jugador")` → `_hit_jugador()`.
    - Implementar `_hit_jugador()`: llamar `GameManager.lose_life()`, luego `queue_free()`.
    - Añadir al grupo `"meteoros"`.
    - Conectar las señales `area_entered` y `body_entered` a sus respectivos métodos en la escena.
    - _Requisitos: 3.2, 4.1, 4.2, 5.1, 5.2_
  - [ ]* 4.2 Escribir tests de propiedades para el Meteorito
    - **Propiedad 3: Movimiento descendente del Meteorito** — Para cualquier posición inicial Y y delta, verificar que `nueva_y == inicial_y + 150 * delta`. **Valida: Requisito 3.2**
    - **Propiedad 5: Puntuación aumenta al destruir un Meteorito** — Para cualquier puntuación inicial, al colisionar un láser con un meteorito, la puntuación resultante es `inicial + 10`. **Valida: Requisito 4.1**
    - **Propiedad 6: Vidas decrementan al impactar al Jugador** — Para cualquier cantidad de vidas inicial > 0, al colisionar un meteorito con el jugador, las vidas resultan en `inicial - 1`. **Valida: Requisito 5.1**

- [x] 5. Checkpoint — Verificar que las escenas individuales compilan sin errores en Godot.
  - Abrir Godot y verificar que `laser.tscn`, `player.tscn` y `meteor.tscn` se cargan sin errores de script.
  - Comprobar que los grupos están asignados correctamente en cada escena.

- [x] 6. Implementar la escena principal JupiterScope
  - [x] 6.1 Sobreescribir `jupiter_scope.tscn` y `jupiter_scope.gd`
    - Árbol de nodos: `Node2D` (raíz, script `jupiter_scope.gd`) > `Player` (instancia de `player.tscn`), `MeteorSpawner` (Timer, `wait_time=1.0`, `autostart=true`), `HUD` (CanvasLayer) > `LabelScore` (Label), `LabelLives` (Label).
    - Script extiende `MinigameBase`.
    - Declarar `const METEOR_SCENE` y `const LASER_SCENE` con `preload()` hacia sus respectivas `.tscn`.
    - `_ready()`: calcular posición inicial del jugador como `(vp.x / 2, vp.y - 50)`, conectar `player.shoot_requested` → `_on_shoot_requested`, conectar `GameManager.score_changed` → `_on_score_changed`, conectar `GameManager.lives_changed` → `_on_lives_changed`, inicializar los labels con los valores actuales de `GameManager`.
    - `_on_shoot_requested(pos)`: instanciar `LASER_SCENE`, asignar posición, `add_child`.
    - `_on_meteor_spawner_timeout()`: instanciar `METEOR_SCENE`, posición X con `randf_range(0, viewport_width)`, Y = -20, `add_child`.
    - `_on_score_changed(new_score)`: actualizar texto de `LabelScore`.
    - `_on_lives_changed(new_lives)`: actualizar texto de `LabelLives`; si `new_lives <= 0`, llamar `finish("lose")`.
    - Conectar la señal `timeout` de `MeteorSpawner` a `_on_meteor_spawner_timeout` en la escena.
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.1, 3.3, 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 8.1, 10.1, 10.2_
  - [ ]* 6.2 Escribir tests de propiedades para JupiterScope
    - **Propiedad 4: Posición de spawn del Meteorito dentro del Viewport** — Para cualquier ancho de viewport, `0 <= meteor.position.x <= viewport_width` y `meteor.position.y == -20`. **Valida: Requisito 3.1**
    - **Propiedad 7: El HUD refleja el estado actual de GameManager** — Para cualquier valor emitido por `score_changed` o `lives_changed`, el texto del label correspondiente contiene el valor correcto. **Valida: Requisitos 6.3, 6.4**
    - **Propiedad 8: Posición inicial del Jugador es dinámica al Viewport** — Para cualquier tamaño de viewport, al ejecutar `_ready()` la posición del Jugador es `(width/2, height-50)`. **Valida: Requisito 8.1**

- [x] 7. Checkpoint final — Verificar integración completa
  - Asegurarse de que todos los tests pasan. Verificar que el minijuego aparece en el menú principal, que se puede iniciar, que la nave se mueve y dispara, que los meteoritos aparecen y destruyen, que el HUD se actualiza, y que al perder todas las vidas se regresa al menú.
  - Preguntar al usuario si hay algo que ajustar antes de dar el minijuego por terminado.

---

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para una versión MVP más rápida.
- GDScript 4 es el lenguaje de implementación (ya establecido por el proyecto).
- El tamaño del viewport es dinámico; usar siempre `get_viewport_rect().size` en lugar de valores hardcodeados.
- La carpeta del minijuego tiene un espacio: `Jupiter Scope/`. Respetar ese nombre exacto en todas las rutas.
- `GameManager.lose_life()` ya maneja el `game_over()` internamente cuando `lives <= 0`. La llamada a `finish("lose")` en `JupiterScope` es complementaria para emitir la señal `minigame_finished` antes de cambiar de escena.
- Los sprites se pueden dejar como rectángulos de color sólido (ColorRect o Sprite2D vacío) en la primera iteración; el arte se puede agregar después sin cambiar la lógica.

---

## Grafo de dependencias de tareas

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2.1", "3.1", "4.1"] },
    { "id": 2, "tasks": ["2.2", "3.2", "4.2"] },
    { "id": 3, "tasks": ["6.1"] },
    { "id": 4, "tasks": ["6.2"] }
  ]
}
```
