# Action 52 (NES, 1991) — Guía de referencia para tu clon en Godot

Action 52 fue un multicart no licenciado de Active Enterprises con 52 minijuegos originales metidos en un solo cartucho, vendido a $199. Es célebre por su pésima calidad (glitches, controles toscos, niveles rotos), pero como *estructura de proyecto* es un caso de estudio perfecto para practicar: un menú selector + docenas de mini-experiencias que comparten pocos sistemas base.

**Nota importante:** la versión NES no tiene una clasificación oficial de dificultad (eso solo existió en la versión de Sega Genesis de 1993, donde el menú sí coloreaba los juegos como Beginner/Intermediate/Expert). El orden de abajo es mi propia clasificación por **complejidad técnica de implementación**, no por dificultad de juego — es decir, qué tan simple es el controlador/sistema que necesitas programar en Godot para reproducir cada uno.

---

## Cómo leer esto
Cada tier agrupa juegos que comparten el mismo tipo de controlador o sistema base. La idea es que construyas **un controlador reutilizable por tier** (ej. `ShooterEstatico.gd`, `PlataformasFijas.gd`, `TopDown4Direcciones.gd`) y luego generes variantes de contenido (sprites, spawns, temas) para cada juego individual — tal como probablemente hicieron los 4 programadores originales en 3 meses.

---

## Tier 1 — Shooters de pantalla fija (los más simples)
Cámara estática, sin scroll, patrón "aparecen enemigos → disparas". Es el punto de partida ideal para tu primer prototipo.

| Juego | Mecánica |
|---|---|
| **Jupiter Scope** | Nave se mueve izq/der en la base de la pantalla, dispara a meteoros que caen. |
| **Shooting Gallery** | Pistolero se mueve por abajo, dispara blancos que aparecen arriba. |
| **Dedant** | Una hormiga dispara hacia arriba a otras hormigas invasoras. |
| **Spread-Fire** | Shooter de pantalla fija, temática sci-fi. |
| **They Came From Outer Space** | Nave que solo gira en ángulos de 90°, temática espacial. |
| **Beeps and Blips** | Shooter de pantalla fija, temática abstracta. |

**Sistema base a construir:** spawner de enemigos con timer, movimiento del jugador en 1 eje, pool de proyectiles.

---

## Tier 2 — Plataformas de pantalla fija
Sin scroll de cámara, salto básico + ataque a distancia corta. Segundo paso lógico: agregas gravedad y colisión con plataformas.

| Juego | Mecánica |
|---|---|
| **Chill-Out** | Esquimales se tiran bolas de nieve entre sí. |
| **French Baker** | Panadero lanza utensilios a comida rebelde. |
| **Cry Baby** | Bebé rocía leche de su mamadera a distintos personajes. |
| **Underground** | Héroe navega un laberinto de escaleras en una caverna. |
| **Hambo's Adventures** | Cerdo antropomorfo trepa esquivando bolas rodantes. |
| **Illuminator** | Sube y baja pisos con escaleras; dispara con un foco para "vaporizar" sombras — el edificio se oscurece periódicamente y hay que matar enemigos para reiluminarlo (mecánica extra de luz/oscuridad). |
| **Lollipop** | Mundo de dulces, el héroe usa una paleta como garrote. |
| **The Evil Empire** | Plataformas de pantalla fija ambientadas en Arabia. |

**Sistema base a construir:** `CharacterBody2D` con gravedad + salto, tilemap de plataformas fijas, ataque cuerpo a cuerpo/corto alcance.

---

## Tier 3 — Acción top-down de movimiento libre
El jugador se mueve en 4/8 direcciones por un área abierta (no scroll de cámara todavía).

| Juego | Mecánica |
|---|---|
| **Silver Sword** | El héroe sube por la pantalla lanzando espadas a criaturas. |
| **Dam Busters** | Osos se lanzan fresas entre sí. |
| **Sombrero's** | Un hombre esquiva tráfico y dispara a ladrones mientras camina por la calle. |
| **Crazy Shuffle** | Shooter top-down de temática abstracta. |
| **Storm Over the Desert** | Combate de tanques top-down: disparas a tanques, infantería y hasta soldados gigantes. |

**Sistema base a construir:** movimiento top-down libre (8 direcciones), disparo direccional, esquiva de obstáculos.

---

## Tier 4 — Shoot 'em up con scroll automático (vertical u horizontal)
Agregas cámara/fondo en scroll continuo — el salto real en complejidad respecto a los tiers anteriores.

| Juego | Mecánica |
|---|---|
| **Star-Evil** | Shmup vertical, temática espacial sci-fi. |
| **Thrusters** | Shmup vertical, temática espacial. |
| **Atmos-Quake** | Shmup vertical, temática sci-fi. |
| **Operation Full-Moon** | Shmup vertical con un buggy lunar. |
| **Space Dreams** | Shmup vertical con temática infantil/rara. |
| **G-Force Fighters** | Shmup horizontal, temática sci-fi. |
| **Critical Bypass** | Shmup horizontal, temática sci-fi. |
| **Megalonia** | Shmup horizontal, temática sci-fi. |
| **Micro-Mike** | Shmup horizontal de diseño bizarro. |
| **Lazer League** | Shmup horizontal, héroe con jetpack. |
| **Rocket Jockey** | Shmup horizontal: vaquero futurista sobre un cohete enlazando robo-vacas voladoras. |
| **Fire Breathers** | Shooter top-down de dos dragones lanzándose bolas de fuego — único juego con **multijugador simultáneo real** (no por turnos). |

**Sistema base a construir:** parallax scrolling, spawner de oleadas sincronizado al scroll, patrón de disparo del jugador.

---

## Tier 5 — Plataformas de scroll lateral (cámara sigue al jugador)
Aquí necesitas cámara que sigue al personaje, niveles más largos, y generalmente un arma o ataque a distancia.

| Juego | Mecánica |
|---|---|
| **Ooze** | El héroe esquiva limo y vaporiza alienígenas en un mundo lleno de baba. |
| **Alfredo and the Fettucinni's** | Un chef golpea ingredientes con sus utensilios. |
| **Haunted Halls of Wentworth** | Temática de terror, el protagonista lanza cruces a los enemigos. |
| **Non-Human** | Temática realmente extraña. |
| **Mash-Man** | Héroe de pies gigantes, temática bizarra. |
| **Fuzz Power** | Criatura peluda de pies grandes destruye productos de cuidado capilar. |
| **Bits and Pieces** | Temática de terror, el héroe es un zombie. |
| **Time Warp Tickers** | Temática bizarra. |
| **Jigsaw** | Un obrero destruye herramientas rebeldes. |
| **Ninja Assault** | El héroe es un ninja en combate cuerpo a cuerpo/distancia. |
| **Robbie and the Robots** | El héroe dispara a distintos robots. |
| **Manchester Beat** | Salta sobre bloques musicales y golpea a otros tipos. |
| **Boss** | Un lagarto antropomorfo con arma dispara a otros reptiles. |

**Sistema base a construir:** cámara con seguimiento + límites de nivel, sistema de niveles/checkpoints, arma equipable.

---

## Tier 6 — Plataformas con mecánica de movimiento especial
Mismo esqueleto que el Tier 5, pero cada uno agrega una mecánica de movimiento no trivial.

| Juego | Mecánica |
|---|---|
| **Streemerz** | El payaso protagonista solo se mueve hacia arriba enganchándose a plataformas con su serpentina de fiesta — un swing/grappling al estilo *Bionic Commando*. |
| **Billy-Bob** | Plataformas de precisión al estilo *Prince of Persia*: un aventurero escapando de un templo que se derrumba (trampas, timing exacto). |
| **City of Doom** | Escalada vertical de un edificio esquivando insectos mutantes. |
| **Meong** | Híbrido acción-puzzle: mueves tu ficha por un tablero evitando huecos y trampas. |

**Sistema base a construir:** cuerda/grappling hook con física de péndulo, trampas con timing, sistema de "board/grid" para el puzzle.

---

## Tier 7 — Híbridos multi-modo / combate más profundo
El salto de complejidad más grande antes del jefe final: combinan dos sistemas de juego distintos o combate con múltiples enemigos simultáneos.

| Juego | Mecánica |
|---|---|
| **Bubble Gum Rossie** | Una niña escupe chicles a enemigos en un mundo de dulces. Alterna entre **plataformas de scroll lateral** y **manejo top-down con scroll vertical** — dos modos de juego distintos en un mismo título. |
| **Slashers** | Beat 'em up de scroll lateral tipo *Double Dragon*: combos, múltiples enemigos en pantalla, hitboxes de golpe cuerpo a cuerpo. |

**Sistema base a construir:** máquina de estados para cambiar de modo de juego, sistema de combate con múltiples enemigos e input buffering básico.

---

## Tier 8 — El "jefe final": Action Gamemaster (Cheetahmen)
El juego 52 y buque insignia del cartucho. Es, por lejos, el más complejo de todos:

- **Cutscenes** — el único juego de los 52 con secuencias narrativas (un niño es absorbido al mundo del juego).
- **Tres personajes jugables** con movesets distintos: Aries (marcial, primera parte), Hércules (fuerza bruta, segunda parte), Apolo (arquero, parte final) — necesitas cambiar de controlador según el tramo del nivel.
- **Mezcla de géneros dentro del mismo juego**: el nivel 1 se presenta como beat 'em up de scroll lateral, pero el resto funciona como plataformas de scroll lateral normal.
- Los enemigos son "reciclados" (palette swaps) de los 51 juegos anteriores — un patrón de diseño interesante y barato que podrías replicar para ahorrar tiempo de arte.

**Sistema base a construir:** todo lo de los tiers anteriores combinado + sistema de cutscenes + cambio de personaje controlado por progreso de nivel.

---

## Recomendación de orden de desarrollo en Godot

1. **Arma primero el "cascarón" del multicart**, no un minijuego: menú de selección (autoload de estado global con vidas/puntaje/juego actual), un `SceneManager` para cargar/descargar minijuegos, y una escena base `Minigame.tscn` de la que heredan todas las demás (con señales estándar tipo `game_over`, `life_lost`, `score_changed`).
2. **Prototipa un juego de cada tier, en orden**, para ir construyendo tus controladores reutilizables: Tier 1 → Tier 2 → Tier 3 → Tier 4 → Tier 5 → Tier 6 → Tier 7 → Tier 8. Cada tier nuevo reutiliza el trabajo del anterior y agrega una sola pieza nueva (scroll, grappling, cambio de modo, etc.).
3. **Componentiza en vez de duplicar código.** Muchos de estos juegos son literalmente el mismo controlador con distinto arte y tema (p. ej. Chill-Out, French Baker, Cry Baby y Lollipop son casi el mismo juego). Un componente `HealthComponent`, `ProjectilePool`, `TopDownController` y `PlatformerController` bien hechos te cubren fácilmente 35+ de los 52 juegos.
4. **Deja el Tier 8 para el final**, tal como en el cartucho original — es donde conviene reutilizar assets y enemigos ya creados en los tiers anteriores (el propio Action 52 hace esto con los sprites de los "villanos" reciclados).

Si quieres, puedo ayudarte después a diseñar la arquitectura de escenas/autoloads en Godot para el cascarón del menú, o a prototipar el controlador base de alguno de los tiers.
