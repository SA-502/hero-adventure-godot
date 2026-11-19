# E2E MCP Verification Protocol (M6 Phase 1)

**Target Project**: Classic 2D Mario-Style Platformer (`Godot 4.7.2`, `Forward Plus`, `640×360` scaled `2×` to `1280×720`)  
**Scope**: M6 Phase 1 Live Godot MCP Acceptance (`AC1`–`AC5` in `ORIGINAL_REQUEST.md` & `PROJECT.md`)  
**Prerequisite Gate**: Milestones `M1`–`M5` complete AND `E2E` `TEST_READY.md` published (`272` automated tests across `game_core` + Tiers 1–4).

---

## Critical `godot-ai` MCP Rules & Edge Cases

Before running any stage, observe these verified runtime contracts from `addons/godot_ai/`:

1. **Single-Operator MCP Control**: Never execute `project_run`, `scene_open`, or `test_run` concurrently with another agent editing scenes/scripts.
2. **`test_run` Preload Cache & Scene Warning**:
   - `ResourceLoader.CACHE_MODE_IGNORE` on `test_*.gd` does **not** invalidate GDScript's internal `preload()` cache for dependencies edited earlier in the same editor session (`cache_warning` is emitted). Restart the Godot editor before final M6 sign-off if `.gd` dependencies were modified in the running session.
   - Always call `scene_open(path="res://scenes/main.tscn")` before `test_run` so `edited_scene == application/run/main_scene` (prevents `scene_warning`).
   - Do **not** wrap `test_run` or `input_sequence` inside `batch_execute` (disallowed by `test_handler.gd` / `editor_handler.gd`).
3. **`project_run` Idempotency & Boot Error Gate**:
   - `project_run` is a no-op if already playing (`was_already_running: true`). Always call `project_manage(op="stop")` first when restarting or switching launch mode.
   - `project_manage(op="stop")` **must** take empty params (`{"op": "stop"}` or `{"op": "stop", "params": {}}` — passing `force`/`reason` fails schema validation).
   - If boot encounters a GDScript parse error, `game_status.status` becomes `"break"` (`pre_live: true`) before `_mcp_game_helper` attaches. Stop the project and inspect `logs_read(source="editor", include_details=true)`.
4. **`game_manage` Property & Input Contracts**:
   - `get_node_info` only serializes `PROPERTY_USAGE_EDITOR` properties (`Node2D.position`, `@export` fields). Read runtime HUD values (`score`, `coins`, `lives`, `stage`, `time`) via `get_ui_elements()`, and inspect `Player.position` via `get_node_info()`.
   - `input_sequence` runs deterministically on `process_frame`, is focus-independent, requires non-decreasing `at_frame` values, and enforces `steps[-1].at_frame + settle_frames <= 600` (~10s at 60 FPS). **Every pressed action MUST be explicitly released** (`"pressed": false`); always assert `actions_pressed_at_end == []`.
   - `input_mouse` coordinate fallback: `get_ui_elements` returns `global_rect` in `640×360` canvas coordinates while the window is `1280×720` (`stretch/mode="canvas_items"`, `2×` scale). Click center `(cx, cy)` first; if UI state does not change, retry at `[cx * 2.0, cy * 2.0]`, or focus and press `Enter` (`ui_accept`).
5. **2D Screenshots & Windows `stale_frame` Gate**:
   - Never pass `source="viewport"` on this 2D project (`EDITOR_VIEWPORT_NOT_3D`). Use `source="viewport_2d"` for editor scenes and `source="game"` (`max_resolution=640`) for the running game.
   - On Windows, minimizing/backgrounding the game window freezes `Engine.get_frames_drawn()`, returning a cached framebuffer with `"stale_frame": true`. Every `editor_screenshot(source="game")` MUST verify `stale_frame != true` (if `true`, unminimize/focus the game window and retry).
6. **Dual Log Audit**:
   - `logs_read(source="game")` only captures logs **after** `_mcp_game_helper._ready()`. Boot-time parse/load errors appear only in `logs_read(source="editor")` and the Editor Errors tab. Both sources MUST be audited.

---

## Stage 0 — Preconditions & Baseline

1. Confirm single-operator MCP control (no parallel `project_run`, `scene_open`, or file edits).
2. Call `editor_state()`:
   - Verify `readiness == "ready"`.
   - If `is_playing == true` or `readiness == "playing"`, call `project_manage(op="stop", params={})` and re-call `editor_state()` until `readiness == "ready"`.
3. Call `logs_read(source="editor", count=50)`:
   - Record baseline `next_cursor`.
   - Confirm 0 unresolved script/editor errors before starting.
4. If `.gd` files were modified in the current Godot editor session, restart Godot cleanly and re-record the Stage 0 baseline cursor before final sign-off.

---

## Stage 1 — AC1: Autoloads, Project Config & Legacy Cleanup

1. `autoload_manage(op="list")`:
   - **PASS** iff `GameState` (`*res://scripts/autoload/game_state.gd`), `AudioManager` (`*res://scripts/autoload/audio_manager.gd`), and `_mcp_game_helper` (`*res://addons/godot_ai/runtime/game_helper.gd`) are registered and enabled.
2. Project settings verification via `project_manage(op="settings_get", ...)`:
   - `application/run/main_scene` == `"res://scenes/main.tscn"`
   - `display/window/size/viewport_width` == `640`
   - `display/window/size/viewport_height` == `360`
   - `display/window/size/window_width_override` == `1280`
   - `display/window/size/window_height_override` == `720`
   - `display/window/stretch/mode` == `"canvas_items"`
   - `display/window/stretch/aspect` == `"keep"`
   - `rendering/textures/canvas_textures/default_texture_filter` == `0`
3. Legacy cleanup check via `filesystem_manage` / `search_filesystem`:
   - `res://scripts/main.gd` (+ `.uid`) and `res://scripts/player.gd` (+ `.uid`) MUST NOT exist.
   - Organized scripts exist under `res://scripts/{autoload,player,objects,enemies,ui,levels}/`.

---

## Stage 2 — AC2: Automated GDScript Test Suites (`test_run`)

1. Call `scene_open(path="res://scenes/main.tscn")` so `edited_scene == application/run/main_scene`.
2. Call `test_run(verbose=False)` (runs all `res://tests/test_*.gd` suites):
   - **PASS** iff:
     - `failed == 0`
     - `total >= 272` (`14` in `game_core` + `110` in `e2e_tier1_features` + `110` in `e2e_tier2_boundaries` + `25` in `e2e_tier3_combinations` + `13` in `e2e_tier4_scenarios`)
     - `skipped == 0` (if `skipped > 0`, re-run with `verbose=True` to inspect skip reasons and fail if unexpected)
     - `load_errors` is empty/absent and no `TEST_RUN_TIMEOUT` occurred
     - `suites_run` contains all 5 suite names: `game_core`, `e2e_tier1_features`, `e2e_tier2_boundaries`, `e2e_tier3_combinations`, `e2e_tier4_scenarios`.

---

## Stage 3 — AC3: Live Launch & Boot Error Gate (`project_run` + `logs_read`)

1. Call `project_run(mode="main", autosave=true)`:
   - If `was_already_running == true`: call `project_manage(op="stop", params={})`, wait for `editor_state().readiness == "ready"`, then re-run `project_run(mode="main", autosave=true)`.
   - If `game_status.status == "break"`: call `project_manage(op="stop", params={})`, inspect `logs_read(source="editor", include_details=true)`, and **FAIL** Stage 3.
2. Poll `editor_state()` until ALL of:
   - `game_capture_ready == true`
   - `game_status.status == "live"`
   - `helper_live == true`
3. Inspect boot logs:
   - `logs_read(source="game", count=100)` -> `editor_errors_count` absent or `0`, `stale_run_id == false`, `0` error lines.
   - `logs_read(source="editor", count=100, since_cursor="<stage0_cursor>")` -> `0` new error entries and `0` live Errors-tab rows.

---

## Stage 4 — AC4 & AC5 (A): Title Screen (`main.tscn`) -> Level 1-1

1. Call `game_manage(op="get_scene_tree", params={"depth": 5})`:
   - Confirm root is the Title Screen (`main.tscn`), NOT legacy `Node2D` coin spawner.
2. Call `game_manage(op="get_ui_elements", params={"include_hidden": false, "include_disabled": true})`:
   - Confirm visible, enabled Arabic controls:
     - Start Adventure button (`"ابدأ المغامرة"`)
     - Level Select buttons (`"1-1"`, `"1-2"`, `"1-3"`)
     - Mute toggle button
     - Best Score label (`"أعلى نتيجة"`)
   - Compute center of `"ابدأ المغامرة"` `global_rect`: `cx = position.x + size.x * 0.5`, `cy = position.y + size.y * 0.5`.
3. **Visual Check #1 (Title Screen)**:
   - Call `editor_screenshot(source="game", max_resolution=640, user_prompt="Verify Arabic Title Screen RTL text clarity, button layout, and crisp pixel-art scenery")`.
   - Assert `stale_frame != true` (if `true`, focus/unminimize game window and retry).
   - Visually verify Arabic title/buttons are unclipped, properly aligned RTL, and pixel art renders sharply without blur.
4. **Click `"ابدأ المغامرة"`**:
   - Send `game_manage(op="input_mouse", params={"event": "motion", "position": [cx, cy]})`
   - Send `game_manage(op="input_mouse", params={"event": "button", "button": "left", "pressed": true, "position": [cx, cy]})`
   - Send `game_manage(op="input_mouse", params={"event": "button", "button": "left", "pressed": false, "position": [cx, cy]})`
   - Wait ~10 frames (e.g. `input_sequence` with `settle_frames: 10` or poll `get_scene_tree()`).
   - **2× Coordinate Fallback**: If `get_scene_tree()` still shows Title Screen, repeat click at `[cx * 2.0, cy * 2.0]` (1280×720 window space). If still unchanged, send `input_key` `"Enter"` press + release.
5. **PASS** iff `get_scene_tree(depth=6)` shows Level `1-1` (`level_1.tscn`) loaded with `GroundLayer`, `Player`, `HUD`, `PauseMenu`, `Flagpole`, `FallZone`, `QuestionBlock`, and `WalkerEnemy`.

---

## Stage 5 — AC4 & AC5 (B): Level 1-1 Gameplay (`Player`, `?` Block, `Coin`, `WalkerEnemy`, `HUD`)

1. Discover live node paths via `game_manage(op="get_scene_tree", params={"depth": 6})` and HUD paths via `game_manage(op="get_ui_elements", params={"root_path": "<HUDPath>"})`.
2. Record `pos0 = get_node_info("<PlayerPath>").properties.position` and initial HUD Score/Coins/Lives/Stage/Time.
3. **Movement, Variable Jump & `TileMapLayer` Collision**:
   - Execute:
     ```json
     {
       "op": "input_sequence",
       "params": {
         "steps": [
           {"at_frame": 0, "action": "move_right", "pressed": true},
           {"at_frame": 10, "action": "jump", "pressed": true},
           {"at_frame": 25, "action": "jump", "pressed": false},
           {"at_frame": 40, "action": "move_right", "pressed": false}
         ],
         "settle_frames": 30
       }
     }
     ```
   - Assert `completed == true` and `actions_pressed_at_end == []`.
   - Call `get_node_info("<PlayerPath>")` -> verify `position.x > pos0.x` and player rests cleanly on `GroundLayer` (did not clip through floor).
   - Also execute a short-hop + `sprint` sequence (`<= 600` frames, all actions released, `actions_pressed_at_end == []`).
4. **`?` Block & `Coin` Interaction**:
   - Locate nearest `QuestionBlock` or `Coin` via `get_scene_tree` + `get_node_info`.
   - Execute a targeted `input_sequence` (`<= 600` frames, all actions released) to move beneath the `?` block / through the coin and jump.
   - Assert `actions_pressed_at_end == []`.
   - Verify via `get_ui_elements` that HUD Score/Coins incremented (`+100` / `+1`), or `QuestionBlock` switched state.
5. **Enemy Stomp (`WalkerEnemy`)**:
   - Locate nearest `WalkerEnemy` via `get_scene_tree` + `get_node_info`.
   - Execute a timed jump `input_sequence` (`<= 600` frames, all actions released) onto the enemy.
   - Verify via `get_scene_tree` / `get_ui_elements` that the `WalkerEnemy` was stomped (`+200` score / node freed) or player handled lateral contact safely without script errors.
6. **Visual Check #2 (Level 1-1)**:
   - Call `editor_screenshot(source="game", max_resolution=640, user_prompt="Verify Level 1-1 pixel art tiles/player/blocks/enemies and Arabic RTL HUD top bar")`.
   - Assert `stale_frame != true`.
   - Confirm crisp pixel art (no blur/seams) and readable Arabic RTL HUD (`النقاط`/`النتيجة`, `العملات`, `المحاولات`, `المرحلة`, `الوقت`).

---

## Stage 6 — AC4 & AC5 (C): Pause Menu (`Esc`)

1. Trigger pause via `input_sequence`:
   ```json
   {
     "op": "input_sequence",
     "params": {
       "steps": [
         {"at_frame": 0, "action": "pause", "pressed": true},
         {"at_frame": 2, "action": "pause", "pressed": false}
       ],
       "settle_frames": 5
     }
   }
   ```
   - Assert `actions_pressed_at_end == []`.
2. Call `game_manage(op="debug_status")`:
   - **PASS** iff `tree_paused == true` and `suspended == false`.
3. Call `game_manage(op="get_ui_elements", params={"include_hidden": false})`:
   - **PASS** iff visible Arabic Pause Menu buttons appear: `"استئناف"`, `"إعادة المرحلة"`, `"القائمة الرئيسية"`, and Mute toggle.
4. **Visual Check #3 (Pause Menu)**:
   - Call `editor_screenshot(source="game", max_resolution=640, user_prompt="Verify Arabic Pause Menu overlay layout and text legibility")`.
   - Assert `stale_frame != true`.
5. Resume gameplay (`pause` sequence or click `"استئناف"` with `2×` fallback) and verify via `debug_status` that `tree_paused == false`.

---

## Stage 7 — AC4 & AC5 (D): Level Select Flow (`1-2` & `1-3`)

1. Return to Main Menu (via Pause Menu -> `"القائمة الرئيسية"`, or `project_manage(op="stop", params={})` + `project_run(mode="main", autosave=true)` + `editor_state()` readiness poll).
2. **Level `1-2` (`level_2.tscn`)**:
   - Locate `"1-2"` button via `get_ui_elements` and click it (`input_mouse` at `[cx, cy]` with `[cx * 2.0, cy * 2.0]` fallback).
   - `get_scene_tree(depth=6)` confirms `level_2.tscn` loaded with `MovingPlatform`, `WalkerEnemy`, `ShellEnemy`, and `Flagpole`.
   - Run a short `input_sequence` (`move_right` + `jump`, all released, `actions_pressed_at_end == []`) and confirm `Player.position` updates cleanly.
   - **Visual Check #4 (Level 1-2)**: `editor_screenshot(source="game", max_resolution=640, user_prompt="Verify Level 1-2 sunset palette, moving platforms, ShellEnemy, and Arabic HUD 1-2")` (`stale_frame != true`).
3. **Level `1-3` (`level_3.tscn`)**:
   - Return to Main Menu, locate `"1-3"` button via `get_ui_elements`, and click it (with `2×` fallback).
   - `get_scene_tree(depth=6)` confirms `level_3.tscn` loaded with castle `GroundLayer`, `MovingPlatform`, `HazardZone` (lava), and `Flagpole`.
   - Run a short `input_sequence` (`move_right` + `jump`, all released, `actions_pressed_at_end == []`) and confirm `Player.position` updates cleanly.
   - **Visual Check #5 (Level 1-3)**: `editor_screenshot(source="game", max_resolution=640, user_prompt="Verify Level 1-3 castle stone tiles, glowing lava HazardZone, and Arabic HUD 1-3")` (`stale_frame != true`).

---

## Stage 8 — Final Clean Shutdown & Dual-Log Audit (AC3 Final Gate)

1. Call `project_manage(op="stop", params={})` -> verify `stopped == true`.
2. Call `editor_state()` -> verify `is_playing == false` and `readiness == "ready"`.
3. Call `logs_read(source="game", count=200)` -> verify `0` runtime errors.
4. Call `logs_read(source="editor", count=200, since_cursor="<stage0_cursor>")` AND `logs_read(source="editor", count=200)` -> verify `0` new errors in the logger ring and `0` Errors-tab rows.
5. **M6 Phase 1 Sign-Off**: Passes iff Stages 1–8 all pass with `0` errors across both log sources and all 5 visual screenshots verified with `stale_frame != true`.
