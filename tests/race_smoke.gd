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
 print("MONSTER KART SMOKE OK: 12 cars, 7 AI, race, drift, items and finish")
 game.queue_free()
 quit(0)
