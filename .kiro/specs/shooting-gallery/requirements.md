# Documento de Requisitos — Shooting Gallery

## Introducción

Shooting Gallery es el segundo minijuego del Tier 1 (shooters de pantalla fija) del proyecto
Action 52 en Godot 4. Un pistolero se mueve horizontalmente por la base de la pantalla y dispara
a blancos que aparecen en posiciones fijas predefinidas en la parte superior. Los blancos son
estáticos: si el jugador no los elimina a tiempo, desaparecen solos sin penalización. El juego
termina cuando el jugador se queda sin vidas (condición que puede extenderse en futuras iteraciones,
pero por ahora las vidas solo se pierden si se introduce esa mecánica; ver Requisito 5). La escena
hereda de `MinigameBase` y se integra con `GameManager` y `SceneManager` de la misma forma que
Jupiter Scope.

---

## Glosario

- **ShootingGallery**: escena principal del minijuego; hereda de `MinigameBase`.
- **Pistolero**: personaje controlado por el jugador; nodo raíz `CharacterBody2D`.
- **Bala**: proyectil disparado por el Pistolero; nodo raíz `Area2D`, grupo `"proyectiles"`.
- **Blanco**: objetivo estático que aparece en la parte superior de la pantalla; nodo raíz `Area2D`.
- **SpawnPoints**: nodo `Node2D` hijo de ShootingGallery que contiene varios `Marker2D` con las
  posiciones fijas donde pueden aparecer los Blancos.
- **TargetSpawner**: `Timer` hijo de ShootingGallery que controla el ritmo de aparición de Blancos.
- **LifeTimer**: `Timer` interno del Blanco; al expirar el Blanco se destruye solo.
- **GameManager**: autoload que gestiona `score` y `lives`; expone `add_score(points)`,
  `lose_life()`, señales `score_changed(new_score)` y `lives_changed(new_lives)`.
- **SceneManager**: autoload que expone `return_to_menu()` y `game_over()`.
- **MinigameBase**: clase base GDScript que provee `finish(result: String)` y gestión de ESC.
- **HUD**: capa de interfaz hija de ShootingGallery que muestra puntuación y vidas actuales.

---

## Requisitos

### Requisito 1: Movimiento del Pistolero

**Historia de usuario:** Como jugador, quiero mover al pistolero horizontalmente por la base de la
pantalla, para apuntar hacia los blancos que aparecen arriba.

#### Criterios de aceptación

1. WHEN el jugador pulsa la acción de entrada `"ui_right"`, THE Pistolero SHALL desplazarse hacia la derecha a una velocidad de 300 px/s hasta que la acción sea liberada.
2. WHEN el jugador pulsa la acción de entrada `"ui_left"`, THE Pistolero SHALL desplazarse hacia la izquierda a una velocidad de 300 px/s hasta que la acción sea liberada.
3. WHEN no se pulsa ninguna acción de movimiento, THE Pistolero SHALL tener velocidad horizontal igual a 0 px/s.
4. WHILE el Pistolero esté activo, THE Pistolero SHALL permanecer confinado dentro de los límites horizontales del viewport usando el semiancho del sprite como referencia, de forma que el personaje nunca quede parcialmente fuera de la pantalla.
5. THE ShootingGallery SHALL posicionar al Pistolero en el centro horizontal y a 50 px del borde inferior del viewport al iniciar la escena.

---

### Requisito 2: Disparo del Pistolero

**Historia de usuario:** Como jugador, quiero disparar balas hacia arriba al pulsar el botón de
acción, para eliminar los blancos.

#### Criterios de aceptación

1. WHEN el jugador pulsa la acción de entrada `"ui_accept"`, THE Pistolero SHALL emitir la señal `shoot_requested` con la posición global del `Marker2D` de disparo (`ShootPoint`).
2. WHEN el ShootingGallery recibe la señal `shoot_requested`, THE ShootingGallery SHALL instanciar una Bala y añadirla como hijo de la escena en la posición indicada por la señal.
3. WHILE una Bala esté activa, THE Bala SHALL desplazarse verticalmente hacia arriba a una velocidad constante de 500 px/s en cada llamada a `_physics_process`.
4. WHEN una Bala sale completamente del área visible del viewport por la parte superior, detectado por `VisibleOnScreenNotifier2D`, THE Bala SHALL eliminarse de la escena con `queue_free()`.
5. THE Bala SHALL pertenecer al grupo `"proyectiles"` al momento de ser instanciada, antes de que se procese cualquier colisión.
6. WHILE el Pistolero esté activo, múltiples Balas podrán coexistir en la escena simultáneamente sin interferir entre sí.

---

### Requisito 3: Comportamiento del Blanco

**Historia de usuario:** Como jugador, quiero que los blancos aparezcan en la parte superior de la
pantalla y desaparezcan solos si no los elimino a tiempo, para experimentar la mecánica de galería
de tiro con tiempo límite por objetivo.

#### Criterios de aceptación

1. THE Blanco SHALL iniciar su `LifeTimer` automáticamente al ser instanciado (`Autostart = true`), con una duración aleatoria entre 1,5 y 3,0 segundos (inclusivo) establecida en `_ready()` mediante `randf_range(1.5, 3.0)`.
2. WHEN el `LifeTimer` del Blanco expira, THE Blanco SHALL eliminarse de la escena con `queue_free()` sin modificar `GameManager.score` ni `GameManager.lives`.
3. WHEN una Bala del grupo `"proyectiles"` entra en la zona de colisión del Blanco, THE Blanco SHALL, en ese orden: invocar `GameManager.add_score(10)`, eliminar la Bala con `queue_free()` y eliminarse a sí mismo con `queue_free()`.
4. THE Blanco SHALL pertenecer al grupo `"blancos"` para facilitar consultas futuras.
5. IF el manejador `area_entered` del Blanco se dispara después de que el propio Blanco ya ha sido marcado para eliminar (`queue_free()` previo), THEN THE Blanco SHALL ignorar el evento sin llamar a `GameManager.add_score()` ni intentar liberar la Bala nuevamente.

---

### Requisito 4: Sistema de aparición de Blancos (Spawner)

**Historia de usuario:** Como diseñador de niveles, quiero que los blancos aparezcan en posiciones
fijas y predefinidas de la pantalla, para que el patrón de juego sea reconocible y diferente del
sistema aleatorio de Jupiter Scope.

#### Criterios de aceptación

1. THE ShootingGallery SHALL contener un nodo `SpawnPoints` (`Node2D`) con exactamente 5 nodos `Marker2D` como hijos, distribuidos equidistantemente a lo largo del eje horizontal en la parte superior del viewport (Y ≈ 50 px del borde superior).
2. WHEN el `TargetSpawner` hace timeout, THE ShootingGallery SHALL obtener todos los hijos de `SpawnPoints` con `get_children()` y seleccionar uno al azar con `pick_random()`.
3. WHEN se selecciona un `Marker2D`, THE ShootingGallery SHALL instanciar un Blanco en la `global_position` exacta de ese `Marker2D`.
4. THE ShootingGallery SHALL añadir el Blanco instanciado como hijo directo de la escena raíz mediante `add_child()`.
5. THE TargetSpawner SHALL tener un `wait_time` configurable desde el editor con valor por defecto de 1,0 segundo y `autostart = true`.

---

### Requisito 5: Condición de fin de partida

**Historia de usuario:** Como jugador, quiero que el juego termine cuando me quede sin vidas, para
que haya una condición de derrota clara.

#### Criterios de aceptación

1. WHEN la escena ShootingGallery termina su inicialización (`_ready()`), THE ShootingGallery SHALL conectarse a la señal `GameManager.lives_changed`.
2. WHEN `GameManager.lives_changed` emite un valor menor o igual a 0, THE ShootingGallery SHALL invocar `finish("lose")` independientemente de si hay Blancos activos en pantalla en ese momento.
3. IF `GameManager.lives_changed` ya está conectado a `_on_lives_changed` en el momento de la inicialización, THEN THE ShootingGallery SHALL omitir la conexión duplicada silenciosamente para evitar errores de Godot.
4. WHEN el jugador pulsa la acción `"ui_cancel"` (ESC), THE MinigameBase SHALL invocar `finish("quit")` (comportamiento heredado; sin lógica adicional en ShootingGallery).

---

### Requisito 6: HUD — Puntuación y Vidas

**Historia de usuario:** Como jugador, quiero ver mi puntuación y vidas actuales en pantalla
durante la partida, para saber mi progreso y estado en tiempo real.

#### Criterios de aceptación

1. THE HUD SHALL mostrar la puntuación actual en el formato `"Puntos: %d"` en el nodo `LabelScore` durante toda la partida.
2. THE HUD SHALL mostrar las vidas actuales en el formato `"Vidas: %d"` en el nodo `LabelLives` durante toda la partida.
3. WHEN `GameManager.score_changed` emite un nuevo valor, THE `LabelScore` SHALL actualizar su texto en el mismo frame en que se recibe la señal.
4. WHEN `GameManager.lives_changed` emite un nuevo valor, THE `LabelLives` SHALL actualizar su texto en el mismo frame en que se recibe la señal.
5. THE ShootingGallery SHALL inicializar `LabelScore` con `"Puntos: %d" % GameManager.score` y `LabelLives` con `"Vidas: %d" % GameManager.lives` durante `_ready()`, antes de que se renderice el primer frame.
6. WHEN `GameManager.lives_changed` emite un valor menor o igual a 0, THE ShootingGallery SHALL invocar `finish("lose")` tras actualizar el texto del `LabelLives`.

---

### Requisito 7: Integración con la arquitectura base

**Historia de usuario:** Como desarrollador, quiero que Shooting Gallery siga los mismos patrones
de integración que Jupiter Scope, para mantener la coherencia arquitectónica del proyecto.

#### Criterios de aceptación

1. THE ShootingGallery SHALL heredar de `MinigameBase` (`extends MinigameBase`).
2. THE MinigameRegistry SHALL contener una entrada con los campos `{ "id": "shooting_gallery", "name": "Shooting Gallery", "scene": "res://scenes/minigames/Shooting Gallery/shooting_gallery.tscn", "tier": 1 }`.
3. THE directorio `res://scenes/minigames/Shooting Gallery/` SHALL contener al menos los archivos: `shooting_gallery.tscn`, `shooting_gallery.gd`, `target.tscn`, `target.gd`, `bullet.tscn`, `bullet.gd`, `player.tscn`, `player.gd`.
4. WHEN `finish(result)` es invocado en ShootingGallery, THE MinigameBase SHALL emitir la señal `minigame_finished(result)` e invocar `SceneManager.return_to_menu()` (comportamiento heredado sin lógica adicional en ShootingGallery).
