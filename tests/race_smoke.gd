extends SceneTree
## CI regression: exercise monster selection, race startup, physics, item use and finish.
func _initialize() -> void:
 call_deferred("_run_tests")

func _run_tests() -> void:
 var packed = load("res://scenes/Main.tscn")
 if packed == null:
  push_error("Main scene missing")
  quit(1)
  return
 var game = packed.instantiate()
 root.add_child(game)
 await process_frame
 assert(game.interface.selection_buttons.size() == 12, "12 selectable monster cars")
 assert(game.interface.settings != null, "settings screen")
 assert(game.interface.pause_page != null, "pause screen")
 assert(game.circuit.themed_landmarks == 4, "four decorated track zones")
 assert(game.audio.music_player.stream != null, "original music stream")
 assert(game.audio.cues.has("finish"), "race sound effects")
 game.interface._open_settings("menu")
 assert(game.interface.settings.visible, "settings can be opened")
 game.interface._close_settings()
 assert(game.interface.menu.visible, "settings return to garage")
 for i in range(12):
  game._preview(i)
  assert(game.selected == i, "Monster selection must work")
 game._start_race()
 assert(game.opponents.size() == 7, "seven AI opponents")
 assert(game.player != null, "playable monster car")
 assert(game.pickups.size() == 16, "collectible items")
 for i in range(250):
  game._physics_process(1.0 / 60.0)
 assert(game.race_state == "racing", "race countdown must finish")
 game._pause_race()
 assert(game.race_state == "paused" and game.interface.pause_page.visible, "pause from race")
 var paused_timer = game.race_time
 game._physics_process(1.0)
 assert(is_equal_approx(game.race_time, paused_timer), "pause freezes time")
 game.interface._open_settings("pause")
 assert(game.interface.settings.visible, "options from pause")
 game.interface._close_settings()
 assert(game.interface.pause_page.visible, "settings returns to pause")
 game._resume_race()
 assert(game.race_state == "racing" and game.interface.hud.visible, "resume race")
 game.interface.left_held = true
 game.interface.drift_held = true
 for i in range(95):
  game._physics_process(1.0 / 60.0)
 assert(game.speed > 4.0, "player auto accelerates")
 game.interface.drift_held = false
 game._physics_process(1.0 / 60.0)
 assert(game.boost_time > 0.0, "drifting must provide mini turbo")
 game.current_item = "SHIELD"
 game._use_item()
 assert(game.shield_time > 0.0, "shield item works")
 game.current_item = "TURBO"
 game._use_item()
 assert(game.boost_time > 2.0, "boost item works")
 game.current_item = "BANANA"
 game._use_item()
 assert(game.hazards.size() == 1, "hazard drops")
 game._finish()
 assert(game.race_state == "finished", "finish panel")
 game._return_to_menu()
 assert(game.race_state == "menu", "back to garage")
 print("MONSTER KART SMOKE OK: 12 cars, 4 track zones, music, settings, pause, 7 AI, drift, items and finish")
 game.queue_free()
 quit(0)
