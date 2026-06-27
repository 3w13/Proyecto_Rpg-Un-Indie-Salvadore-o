# CLAUDE.md

Este archivo le da contexto a Claude Code (claude.ai/code) al trabajar con el código de este repositorio.

## Proyecto

"Proyecto RPG" — un RPG indie 2D top-down construido en **Godot 4.6** (renderizador GL Compatibility). El código, los comentarios y los nombres de assets/nodos están predominantemente en **español**; sigue esta convención al agregar código (comentarios en español, nombres de `class_name`/métodos en inglés, tal como lo hace el código existente). El documento de diseño del juego vive en `TDD` (Technical Design Document) y en `Documentacion/`.

## Ejecución y herramientas

No hay suite de pruebas por línea de comandos ni script de build — este es un proyecto de Godot manejado desde el editor.

- Ábrelo en el editor de Godot; la escena principal se define mediante UID en `project.godot` (`run/main_scene`).
- Ejecuta el juego con F5 en el editor, o en modo headless: `godot --path . ` (requiere Godot 4.6).
- El plugin `addons/dialogue_manager/` (Dialogue Manager) está habilitado y autocargado como el singleton `DialogueManager`. Los archivos `.dialogue` viven en `dialogues/`.
- Acciones de entrada (ver `project.godot [input]`): `up/down/left/right` (WASD), `Run` (Shift), `interact` (E).
- Los archivos `.gd.uid` son archivos de ID de script generados por Godot — súbelos al repo junto con su `.gd` correspondiente, nunca los edites a mano.

## Arquitectura

### Patrón de Máquina de Estados (núcleo de todos los actores)

Cada actor (jugador, NPC, enemigo, contenedor/cofre) es controlado por un nodo de máquina de estados jerárquica. Hay **dos implementaciones paralelas** — ten cuidado con cuál estás extendiendo:

1. **Base genérica** en `scripts/Maquina de Estados Base/` (`state_machine.gd` + `state_base.gd`). Usa `change_to(NodePath)`, resuelve el nodo controlado mediante la propiedad exportada `controlled_node_path`, e inyecta `controlled_node`/`state_machine` en los estados mediante `set()` con duck-typing. Lo usan los enemigos, NPCs y contenedores.
2. **Específica del jugador** `scripts/characters/protagonists/state_machine_player.gd` (`class_name PlayerStateMachine`). Usa `change_to(String)` (el **nombre** del nodo hijo, no su path), exporta `default_state: StateBase` tipado, y agrega lógica de diálogo/inventario/seguimiento de grupo (party-follow).

**Convención de estados:** cada estado es un nodo hijo de la máquina de estados. Los estados extienden `StateBase` y opcionalmente implementan `start()`, `end()`, `on_process(delta)`, `on_physics_process(delta)`, `on_input(event)`, `on_unhandled_input`, `on_unhandled_key_input`. La máquina reenvía los callbacks de Godot solo a los estados que los definen (mediante `has_method`). Los scripts de estado viven en subcarpetas `Estados/` junto a su máquina correspondiente.

### Estados del jugador y sistema de grupo (party)

Los estados del jugador están en `scripts/characters/protagonists/Estados/` (idle, running, dialogue, chase, enter_inventory). El `PlayerStateMachine`:
- Se enlaza automáticamente a `DialogueManager.dialogue_started`/`dialogue_ended` para forzar al jugador a entrar en `PlayerStateDialogue` durante las conversaciones, y restaura `post_dialogue_state_name` al finalizar.
- Maneja la tecla de inventario (I) en `_unhandled_key_input`, guardando/restaurando el estado anterior.
- Funciona también como **seguidor de grupo (party follower)** cuando se llama a `set_party_follower(true)`: se ignora la entrada del jugador y el actor persigue un objetivo de seguimiento en su lugar.

**Seguimiento de grupo (Party follow)** (`scripts/system/party_follow_controller.gd`, `class_name PartyFollowController`): se asigna al `CharacterBody2D` líder. Registra un rastro posicional y envía puntos del rastro con retraso a los cuerpos seguidores (llamados `ChibiBrown`, `ChibiBlue`, `ChibiPurple` — ver `FOLLOWER_ORDER`) mediante su `PlayerStateMachine.set_follow_target(...)`. Los seguidores transicionan entre idle y `PlayerStateChase` según una histéresis de distancia con `can_start_chase`/`should_stop_chase` (distancias de detención/reanudación con debouncing por frames de confirmación). La dirección hacia la que mira el personaje se pasa entre cuerpos mediante la clave de metadata del nodo `player_facing_direction`.

### Constantes compartidas

`scripts/system/game_constants.gd` (`class_name GameConstants`) centraliza nombres de grupos (`player`, `enemy`, `npc`, `container`, `interactable`), capas/máscaras de física, y rutas/nombres de nodos conocidos. **Usa estas constantes** en lugar de strings hardcodeados al referenciar grupos, capas de física, o rutas estándar de nodos hijos (p. ej. `StateMachine`, `DetectionArea`, `InteractArea`).

### Otros sistemas

- **Transiciones de escena:** `scripts/interactive/scene_transition_trigger.gd` — un trigger Area2D que detecta al jugador y cambia de escena. Los mapas están en `scenes/maps/EcenaProtoMap0X.tscn`.
- **UI de diálogo:** `scripts/system/box_dialogues.gd` + `scenes/ui/Box_Dialogues.tscn`.
- **Contenedores (cofres):** `scripts/interactive/Contenedores/` — su propia máquina de estados (`cofre_closed`/`cofre_open`) más `cofre_inventory.gd`.
- **NPCs:** `scripts/characters/npc/` con estados idle/patrol/random_move/waiting/dialogue.
- **Enemigos:** `scripts/characters/enemy/` con estados idle/chase/combat/return.

## Notas sobre la estructura del repositorio

- `scripts/` refleja la estructura de `scenes/` (characters/protagonists, characters/npc, characters/enemy, interactive, system, ui).
- Los archivos `*.txt` sueltos en la raíz (`actual_*`, `expected_*`, `raw_*`) son salidas de depuración/diff de prueba, no forman parte del juego.
- Los colores de carpeta en `project.godot [file_customization]` reflejan su propósito: assets=verde, dialogues=naranja, resources=azul, scenes=rojo, scripts=morado.