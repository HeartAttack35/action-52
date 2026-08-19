# Action 52 — Cascarón del menú principal (Godot 4.x)

Este paquete contiene el menú principal funcional + los 3 sistemas base
descritos en el documento de planificación, más un minijuego "demo" de
prueba para validar que todo el flujo funciona.

## 1. Copiar los archivos a tu proyecto

Copia las carpetas `autoloads/` y `scenes/` dentro de la carpeta `res://`
de tu proyecto Godot (si ya tienes carpetas con esos nombres, simplemente
fusiona el contenido).

## 2. Registrar los 3 autoloads

Ve a **Project > Project Settings > Autoload** y agrega, EN ESTE ORDEN,
los siguientes scripts. El nombre (columna "Node Name") debe coincidir
EXACTO con lo que se usa en el código, porque así se llama el singleton
global:

| Path | Node Name |
|---|---|
| `res://autoloads/minigame_registry.gd` | `MinigameRegistry` |
| `res://autoloads/game_manager.gd` | `GameManager` |
| `res://autoloads/scene_manager.gd` | `SceneManager` |

Alternativa rápida (si prefieres editar texto directamente): abre
`project.godot` con un editor de texto y agrega al final:

```
[autoload]

MinigameRegistry="*res://autoloads/minigame_registry.gd"
GameManager="*res://autoloads/game_manager.gd"
SceneManager="*res://autoloads/scene_manager.gd"
```

## 3. Definir la escena principal

En **Project > Project Settings > Application > Run > Main Scene**,
selecciona `res://scenes/main_menu/main_menu.tscn`.

## 4. Probar el flujo completo

Ejecuta el proyecto (F5). Deberías ver el menú con un solo botón,
"Demo / Prueba". Al presionarlo:

- Se carga `demo_minigame.tscn`.
- El botón "Simular victoria" suma 100 puntos y vuelve al menú.
- El botón "Simular derrota" resta una vida y vuelve al menú.
- ESC también vuelve al menú (heredado de `MinigameBase`).

Si eso funciona, el cascarón está listo y puedes borrar el minijuego
demo cuando quieras (o dejarlo como plantilla de referencia).

## 5. Agregar tu primer minijuego real (Tier 1)

1. Crea una carpeta `scenes/minigames/<id_del_juego>/` (ej. `jupiter_scope`).
2. Crea una escena con nodo raíz `Node2D`.
3. En el script de esa escena, en vez de `extends Node2D` usa
   `extends MinigameBase`.
4. Cuando el jugador gane o pierda, llama a `finish("win")` o
   `finish("lose")` — eso automáticamente vuelve al menú.
5. Agrega una entrada nueva en el array `minigames` dentro de
   `autoloads/minigame_registry.gd`, con su `id`, `name`, ruta de
   `scene`, y `tier`. El botón aparecerá solo en el menú, sin tocar
   la escena del menú.

## Notas de diseño

- `GameManager` guarda vidas/puntaje de forma global — se resetea
  automáticamente cada vez que `SceneManager.start_minigame()` arranca
  un juego nuevo.
- `MinigameRegistry` es la única fuente de verdad de qué minijuegos
  existen. El menú NO tiene botones hardcodeados: los genera desde
  esta lista, así que agregar los 51 juegos restantes es solo agregar
  entradas al array, sin tocar `main_menu.tscn`.
- `MinigameBase` es la clase de la que deben heredar todas las escenas
  de minijuegos, para que compartan la salida estándar (`finish()`) y
  el atajo de ESC para volver al menú.
