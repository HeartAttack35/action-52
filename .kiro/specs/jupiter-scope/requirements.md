# Documento de Requisitos: Jupiter Scope

## Introducción

Jupiter Scope es el primer minijuego real del clon de Action 52 en Godot 4. Es un shooter de pantalla fija estilo NES (Tier 1): el jugador controla una nave que se desplaza horizontalmente en la base de la pantalla y dispara láseres hacia arriba para destruir meteoritos que caen desde la parte superior. El minijuego se integra en el sistema de autoloads existente (`GameManager`, `SceneManager`, `MinigameRegistry`) y hereda de `MinigameBase`.

## Glosario

- **JupiterScope**: Escena raíz del minijuego, extiende `MinigameBase`. Archivo: `jupiter_scope.tscn` / `jupiter_scope.gd`.
- **Jugador**: Nodo `CharacterBody2D` que representa la nave controlada por el usuario. Pertenece al grupo `"jugador"`.
- **Láser**: Nodo `Area2D` que representa el proyectil disparado por el Jugador. Pertenece al grupo `"proyectiles"`.
- **Meteorito**: Nodo `Area2D` que representa un meteorito descendente. Pertenece al grupo `"meteoros"`.
- **MeteorSpawner**: Nodo `Timer` que controla la aparición periódica de Meteoritos.
- **HUD**: Nodo `CanvasLayer` que contiene las etiquetas de puntuación y vidas.
- **GameManager**: Autoload singleton. Gestiona `lives`, `score`, `add_score()`, `lose_life()`, señales `lives_changed`, `score_changed`.
- **SceneManager**: Autoload singleton. Gestiona `start_minigame()`, `return_to_menu()`, `game_over()`.
- **MinigameRegistry**: Autoload singleton. Catálogo de minijuegos disponibles.
- **MinigameBase**: Clase base GDScript de la que hereda `JupiterScope`. Provee `finish(result)` y manejo de ESC.
- **Viewport**: Área visible de la pantalla. Se consulta con `get_viewport_rect().size`.

---

## Requisitos

### Requisito 1: Movimiento horizontal del Jugador

**Historia de usuario:** Como jugador, quiero mover la nave izquierda y derecha con las teclas de dirección, para posicionarme y esquivar meteoritos.

#### Criterios de aceptación

1. WHEN el jugador presiona `ui_left`, THE JupiterScope SHALL mover al Jugador hacia la izquierda a una velocidad constante de 300 px/s.
2. WHEN el jugador presiona `ui_right`, THE JupiterScope SHALL mover al Jugador hacia la derecha a una velocidad constante de 300 px/s.
3. WHILE el Jugador alcanza el borde izquierdo de la pantalla, THE JupiterScope SHALL impedir que el Jugador salga del área visible.
4. WHILE el Jugador alcanza el borde derecho de la pantalla, THE JupiterScope SHALL impedir que el Jugador salga del área visible.

---

### Requisito 2: Disparo del Jugador

**Historia de usuario:** Como jugador, quiero disparar láseres presionando `ui_accept`, para destruir meteoritos.

#### Criterios de aceptación

1. WHEN el jugador presiona `ui_accept`, THE JupiterScope SHALL instanciar un Láser en la posición del punto de disparo del Jugador (`ShootPoint`) y añadirlo a la escena activa.
2. THE Jugador SHALL emitir la señal `shoot_requested(position: Vector2)` para delegar la creación del Láser a la escena `JupiterScope`.
3. WHEN el Láser es instanciado, THE Láser SHALL desplazarse hacia arriba a una velocidad constante de 500 px/s.
4. WHEN el Láser sale completamente de la pantalla visible, THE Láser SHALL eliminarse de la escena (`queue_free()`).

---

### Requisito 3: Aparición de Meteoritos

**Historia de usuario:** Como jugador, quiero que los meteoritos aparezcan periódicamente desde arriba en posiciones aleatorias, para que el juego sea desafiante.

#### Criterios de aceptación

1. WHEN el `MeteorSpawner` completa su ciclo de espera (1,0 s), THE JupiterScope SHALL instanciar un Meteorito en una posición X aleatoria dentro del ancho del Viewport y en Y = −20 (por encima del borde superior).
2. THE Meteorito SHALL descender verticalmente a una velocidad constante de 150 px/s.
3. THE JupiterScope SHALL añadir cada Meteorito instanciado como hijo de la escena activa.

---

### Requisito 4: Colisión Láser–Meteorito (destrucción)

**Historia de usuario:** Como jugador, quiero que mis disparos destruyan los meteoritos, para acumular puntos.

#### Criterios de aceptación

1. WHEN un Láser colisiona con un Meteorito, THE GameManager SHALL aumentar la puntuación en 10 puntos mediante `add_score(10)`.
2. WHEN un Láser colisiona con un Meteorito, THE JupiterScope SHALL eliminar de la escena tanto el Meteorito como el Láser (`queue_free()` en ambos).

---

### Requisito 5: Colisión Meteorito–Jugador (pérdida de vida)

**Historia de usuario:** Como jugador, quiero que si un meteorito me alcanza pierda una vida, para que el juego tenga consecuencias.

#### Criterios de aceptación

1. WHEN un Meteorito colisiona con el Jugador, THE GameManager SHALL decrementar las vidas en uno mediante `lose_life()`.
2. WHEN un Meteorito colisiona con el Jugador y `GameManager.lives` es mayor que 0, THE JupiterScope SHALL eliminar únicamente el Meteorito de la escena (`queue_free()`).
3. WHEN `GameManager.lose_life()` es invocado y `GameManager.lives` llega a 0, THE GameManager SHALL invocar `SceneManager.game_over()` automáticamente (comportamiento ya implementado en `GameManager`).

---

### Requisito 6: HUD (visualización de estado)

**Historia de usuario:** Como jugador, quiero ver mi puntuación y vidas actuales en todo momento, para saber cómo voy en el juego.

#### Criterios de aceptación

1. THE HUD SHALL mostrar la puntuación actual del jugador en un `Label` visible en la pantalla durante toda la partida.
2. THE HUD SHALL mostrar las vidas restantes del jugador en un `Label` visible en la pantalla durante toda la partida.
3. WHEN `GameManager` emite la señal `score_changed(new_score)`, THE HUD SHALL actualizar el `Label` de puntuación con el nuevo valor de forma inmediata.
4. WHEN `GameManager` emite la señal `lives_changed(new_lives)`, THE HUD SHALL actualizar el `Label` de vidas con el nuevo valor de forma inmediata.

---

### Requisito 7: Condición de fin de partida

**Historia de usuario:** Como jugador, quiero que el juego termine cuando pierdo todas mis vidas, para que haya un estado de game over claro.

#### Criterios de aceptación

1. WHEN `GameManager.lives_changed` emite un valor de 0 o menor, THE JupiterScope SHALL invocar `finish("lose")`.
2. WHEN `finish("lose")` es invocado, THE MinigameBase SHALL emitir la señal `minigame_finished("lose")` e invocar `SceneManager.return_to_menu()`.

---

### Requisito 8: Posicionamiento inicial

**Historia de usuario:** Como jugador, quiero que la nave aparezca centrada en la base de la pantalla al inicio de la partida, para tener una posición de partida neutral.

#### Criterios de aceptación

1. WHEN la escena `JupiterScope` se carga, THE JupiterScope SHALL posicionar al Jugador en el centro horizontal del Viewport (x = `viewport_width / 2`) y cerca del borde inferior (y = `viewport_height − 50`).

---

### Requisito 9: Registro del minijuego

**Historia de usuario:** Como sistema, quiero que Jupiter Scope esté registrado en `MinigameRegistry`, para que el menú principal lo muestre y pueda ser iniciado.

#### Criterios de aceptación

1. THE MinigameRegistry SHALL contener una entrada con `"id": "jupiter_scope"`, `"name": "Jupiter Scope"`, `"scene": "res://scenes/minigames/Jupiter Scope/jupiter_scope.tscn"` y `"tier": 1`.
2. WHEN `MinigameRegistry.get_minigame("jupiter_scope")` es invocado, THE MinigameRegistry SHALL devolver el diccionario de la entrada correspondiente sin devolver un diccionario vacío.

---

### Requisito 10: Integración con MinigameBase

**Historia de usuario:** Como sistema, quiero que Jupiter Scope extienda `MinigameBase`, para heredar el comportamiento estándar de finalización y salida con ESC.

#### Criterios de aceptación

1. THE JupiterScope SHALL extender la clase `MinigameBase` en su script GDScript.
2. WHEN el jugador presiona la tecla `ui_cancel` (ESC), THE MinigameBase SHALL invocar `finish("quit")` y navegar de regreso al menú principal (comportamiento heredado de `MinigameBase._unhandled_input()`).
