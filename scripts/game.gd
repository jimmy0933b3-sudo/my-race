extends Node3D
## Monster Kart 3D: three-lap arcade racing with drift, rivals and item battles.
const Kart = preload("res://scripts/monster_kart.gd")
const Circuit = preload("res://scripts/track.gd")
const RaceUI = preload("res://scripts/race_ui.gd")
const LAPS = 3
var circuit
var camera: Camera3D
var interface
var display_kart
var player
var opponents: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var race_state := "menu"
var selected := 0
var yaw := 0.0
var speed := 0.0
var heading_steer := 0.0
var drift_charge := 0.0
var previously_drifting := false
var boost_time := 0.0
var shield_time := 0.0
var bump_wait := 0.0
var race_time := 0.0
var count_time := 3.4
var current_item := ""
var player_lap := 1
var player_prev_index := 3
var race_rank := 1
var rng := RandomNumberGenerator.new()
var effect_nodes: Array[Dictionary] = []

func _ready() -> void:
 rng.seed = 19432
 circuit = Circuit.new()
 circuit.name = "CandyMonsterCircuit"
 add_child(circuit)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 68
 camera.far = 320
 add_child(camera)
 interface = RaceUI.new()
 add_child(interface)
 interface.start_race.connect(_start_race)
 interface.retry_race.connect(_start_race)
 interface.return_to_menu.connect(_return_to_menu)
 interface.selection_changed.connect(_preview)
 interface.item_used.connect(_use_item)
 _preview(selected)
 _menu_camera(1.0)

func _spawn(index: int, at: Vector3, angle: float) -> Node3D:
 var car = Kart.new()
 add_child(car)
 car.configure(index)
 car.position = at
 car.rotation.y = angle
 return car

func _preview(index: int) -> void:
 selected = index
 if race_state != "menu":
  return
 if is_instance_valid(display_kart):
  display_kart.queue_free()
 display_kart = _spawn(index, Vector3(7.3, 0.55, 0), -0.33)
 display_kart.scale = Vector3.ONE * 1.9

func _menu_camera(weight: float) -> void:
 var p = Vector3(1.0, 4.7, 14.0)
 camera.position = camera.position.lerp(p, weight)
 camera.look_at(Vector3(4.5, 1.7, 0.0), Vector3.UP)
 camera.fov = lerpf(camera.fov, 58.0, weight)

func _clear_race() -> void:
 if is_instance_valid(player):
  player.queue_free()
 player = null
 for ai in opponents:
  if is_instance_valid(ai["car"]):
   ai["car"].queue_free()
 opponents.clear()
 for item in pickups:
  if is_instance_valid(item["node"]):
   item["node"].queue_free()
 pickups.clear()
 for hazard in hazards:
  if is_instance_valid(hazard["node"]):
   hazard["node"].queue_free()
 hazards.clear()
 for effect in effect_nodes:
  if is_instance_valid(effect["node"]):
   effect["node"].queue_free()
 effect_nodes.clear()

func _start_race() -> void:
 _clear_race()
 if is_instance_valid(display_kart):
  display_kart.queue_free()
 display_kart = null
 yaw = _angle_for(circuit.direction(3.0))
 player = _spawn(selected, circuit.sample(3.0, 1.6) + Vector3(0, 0.14, 0), yaw)
 speed = 0.0
 heading_steer = 0.0
 drift_charge = 0.0
 previously_drifting = false
 boost_time = 0.0
 shield_time = 0.0
 bump_wait = 0.0
 current_item = ""
 race_time = 0.0
 player_lap = 1
 player_prev_index = 3
 race_rank = 1
 for j in range(7):
  var row = int(j / 2)
  var progress = 3.0 - float(row + 1) * 2.1
  var lane = -3.5 if j % 2 == 0 else 3.5
  var c = _spawn((selected + j + 2) % 12, circuit.sample(progress, lane) + Vector3(0, 0.14, 0), _angle_for(circuit.direction(progress)))
  opponents.append({"car": c, "progress": progress, "lane": lane, "speed": 29.0 + float(j % 4) * 1.65, "stun": 0.0, "seed": float(j) * 1.7, "boost": 0.0})
 _create_pickups()
 race_state = "countdown"
 count_time = 3.4
 interface.show_race()
 interface.update_hud(1, 1, 0.0, 0.0, "")
 interface.show_countdown("3")
 _follow_camera(1.0)

func _return_to_menu() -> void:
 _clear_race()
 race_state = "menu"
 interface.show_menu()
 _preview(selected)
 _menu_camera(1.0)

func _angle_for(v: Vector3) -> float:
 return atan2(-v.x, -v.z)

func _process(delta: float) -> void:
 if race_state == "menu":
  if is_instance_valid(display_kart):
   display_kart.rotation.y += delta * 0.65
   display_kart.animate_kart(delta, 2.0, false)
  _menu_camera(minf(1.0, delta * 2.0))
 elif race_state != "finished":
  for item in pickups:
   var node: Node3D = item["node"]
   if item["cooldown"] > 0.0:
    node.visible = false
   else:
    node.visible = true
    node.rotation.y += delta * 1.5
    node.position.y = 1.65 + sin(Time.get_ticks_msec() * 0.002 + float(item["index"])) * 0.30
  for effect in effect_nodes:
   var n: Node3D = effect["node"]
   n.position.y += delta * 1.8
   n.scale *= maxf(0.45, 1.0 - delta * 1.35)

func _physics_process(dt: float) -> void:
 if race_state == "countdown":
  count_time -= dt
  var number = int(ceil(count_time))
  interface.show_countdown(str(number) if number > 0 else "GO!")
  _follow_camera(dt * 3.0)
  if count_time <= -0.52:
   race_state = "racing"
   interface.show_countdown("")
  return
 if race_state != "racing":
  return
 race_time += dt
 boost_time = maxf(0.0, boost_time - dt)
 shield_time = maxf(0.0, shield_time - dt)
 bump_wait = maxf(0.0, bump_wait - dt)
 _update_player(dt)
 _update_ai(dt)
 _update_items(dt)
 _update_effects(dt)
 _update_rank()
 interface.update_hud(race_rank, player_lap, speed, race_time, _item_label())
 _follow_camera(minf(1.0, dt * 4.8))

func _update_player(dt: float) -> void:
 var left = interface.left_held or Input.is_action_pressed("ui_left")
 var right = interface.right_held or Input.is_action_pressed("ui_right")
 var drift = interface.drift_held or Input.is_key_pressed(KEY_SHIFT)
 var steer = float(int(right) - int(left))
 heading_steer = move_toward(heading_steer, steer, dt * 6.5)
 var nearest = circuit.nearest_index(player.position)
 var offset = player.position.distance_to(circuit.centers[nearest])
 var offroad = offset > Circuit.HALF_WIDTH - 0.1
 var chosen_stats = Kart.ROSTER[selected]
 var max_speed = 35.0 + float(chosen_stats["speed"]) * 1.6
 if offroad:
  max_speed *= 0.61
 if boost_time > 0.0:
  max_speed += 17.0
 var acceleration = 15.0 if offroad else 21.0
 speed = move_toward(speed, max_speed, dt * acceleration)
 var turning = 0.87 + float(chosen_stats["grip"]) * 0.09
 var turn_power = turning * (0.60 + clampf(speed / 34.0, 0.0, 1.0))
 var active_drift = drift and absf(heading_steer) > 0.16 and speed > 10.0
 if active_drift:
  drift_charge += dt
  turn_power *= 1.32
  speed *= 1.0 - 0.048 * dt
 elif previously_drifting and drift_charge > 0.65:
  boost_time = maxf(boost_time, clampf(drift_charge * 0.74, 0.9, 2.7))
  _flash(player.position, Color("#9ee9ff"))
  drift_charge = 0.0
 elif not drift:
  drift_charge = 0.0
 previously_drifting = active_drift
 yaw -= heading_steer * dt * turn_power
 var forward = Vector3(-sin(yaw), 0.0, -cos(yaw))
 player.position += forward * speed * dt
 player.position.y = 0.26
 if offset > Circuit.HALF_WIDTH + 6.0:
  var correction = (circuit.centers[nearest] - player.position).normalized()
  player.position += correction * dt * 17.0
  speed = minf(speed, 15.0)
 player.rotation.y = yaw
 player.animate_kart(dt, speed, active_drift)
 var index = circuit.nearest_index(player.position)
 if player_prev_index > Circuit.SEGMENTS - 24 and index < 24:
  var tangent = circuit.direction(float(index))
  if forward.dot(tangent) > 0.0:
   player_lap += 1
   if player_lap > LAPS:
    _finish()
 elif player_prev_index < 24 and index > Circuit.SEGMENTS - 24:
  player_lap = maxi(1, player_lap - 1)
 player_prev_index = index
 if active_drift and rng.randf() < 0.22:
  _flash(player.position + Vector3(rng.randf_range(-0.6, 0.6), 0.1, 1.1).rotated(Vector3.UP, yaw), Color("#b5a9ff"))
 if boost_time > 0.0 and rng.randf() < 0.38:
  _flash(player.position + Vector3(0, 0.5, 1.6).rotated(Vector3.UP, yaw), Color("#ffdb79"))

func _update_ai(dt: float) -> void:
 var seg_len = circuit.total_length / float(Circuit.SEGMENTS)
 for bot in opponents:
  var stun: float = bot["stun"]
  var car = bot["car"]
  stun = maxf(0.0, stun - dt)
  bot["stun"] = stun
  var pace: float = bot["speed"] * (0.26 if stun > 0.0 else 1.0)
  var prog: float = bot["progress"] + dt * pace / seg_len
  bot["progress"] = prog
  var side: float = bot["lane"] + sin(prog * 0.10 + bot["seed"]) * 1.3
  side = clampf(side, -5.7, 5.7)
  var desired = circuit.sample(prog, side)
  car.position = desired + Vector3(0, 0.15 + absf(sin(prog)) * 0.03, 0)
  car.rotation.y = _angle_for(circuit.direction(prog))
  car.animate_kart(dt, pace, false)
  if car.position.distance_squared_to(player.position) < 7.5 and bump_wait <= 0.0 and shield_time <= 0.0:
   speed *= 0.72
   bump_wait = 0.85
   _flash(player.position + Vector3.UP, Color("#ffb6c7"))
  for h in hazards:
   if h["alive"] and car.position.distance_to(h["node"].position) < 2.1:
    bot["stun"] = 2.4
    h["alive"] = false
    h["node"].visible = false

func _update_rank() -> void:
 var progress = float(player_lap - 1) * float(Circuit.SEGMENTS) + float(player_prev_index)
 var rank = 1
 for bot in opponents:
  if float(bot["progress"]) > progress:
   rank += 1
 race_rank = rank

func _create_pickups() -> void:
 var orb_mesh = SphereMesh.new()
 orb_mesh.radius = 0.87
 orb_mesh.height = 1.74
 orb_mesh.radial_segments = 12
 orb_mesh.rings = 6
 var mat = StandardMaterial3D.new()
 mat.albedo_color = Color("#a6f5ff")
 mat.metallic = 0.28
 mat.roughness = 0.17
 mat.emission_enabled = true
 mat.emission = Color("#74d8ff")
 mat.emission_energy_multiplier = 2.1
 for i in range(16):
  var lane = -3.7 if i % 2 == 0 else 3.7
  var idx = 11 + i * 10
  var orb = Node3D.new()
  var sphere = MeshInstance3D.new()
  sphere.mesh = orb_mesh
  sphere.material_override = mat
  orb.add_child(sphere)
  for j in range(4):
   var sm = BoxMesh.new()
   sm.size = Vector3(0.17, 1.4, 0.17)
   var arm = MeshInstance3D.new()
   arm.mesh = sm
   arm.material_override = mat
   arm.rotation.z = float(j) * PI / 4.0
   orb.add_child(arm)
  var p = circuit.sample(float(idx), lane)
  orb.position = Vector3(p.x, 1.65, p.z)
  add_child(orb)
  pickups.append({"node": orb, "index": idx, "cooldown": 0.0})

func _update_items(dt: float) -> void:
 for item in pickups:
  item["cooldown"] = maxf(0.0, float(item["cooldown"]) - dt)
  if float(item["cooldown"]) > 0.0 or current_item != "":
   continue
  var orb: Node3D = item["node"]
  if player.position.distance_to(orb.position) < 3.2:
   current_item = ["TURBO", "SHIELD", "ZAP", "BANANA"][rng.randi_range(0, 3)]
   item["cooldown"] = 9.0
   _flash(orb.position, Color("#c6f8ff"))
 for h in hazards:
  if not h["alive"]:
   continue
  h["ttl"] = float(h["ttl"]) - dt
  if float(h["ttl"]) <= 0.0:
   h["alive"] = false
   h["node"].visible = false
  elif player.position.distance_to(h["node"].position) < 1.8 and shield_time <= 0.0 and bump_wait <= 0.0:
   speed *= 0.42
   bump_wait = 1.2
   h["alive"] = false
   h["node"].visible = false

func _item_label() -> String:
 match current_item:
  "TURBO": return "⚡\n衝刺"
  "SHIELD": return "🛡\n護盾"
  "ZAP": return "✨\n閃電"
  "BANANA": return "🍌\n陷阱"
 return ""

func _use_item() -> void:
 if race_state != "racing" or current_item == "":
  return
 match current_item:
  "TURBO":
   boost_time = maxf(boost_time, 3.6)
   _flash(player.position, Color("#ffdc69"))
  "SHIELD":
   shield_time = 6.5
   _flash(player.position, Color("#95e9fe"))
  "ZAP":
   var hit_count = 0
   for bot in opponents:
    if bot["car"].position.distance_to(player.position) < 40.0:
     bot["stun"] = 2.8
     _flash(bot["car"].position + Vector3.UP, Color("#fff38f"))
     hit_count += 1
   if hit_count == 0:
    boost_time = 1.5
  "BANANA":
   var hz = Node3D.new()
   var p = player.position + Vector3(0, 0.34, 2.9).rotated(Vector3.UP, yaw)
   hz.position = p
   var mesh = CylinderMesh.new()
   mesh.top_radius = 0.05
   mesh.bottom_radius = 0.76
   mesh.height = 0.76
   var mat = StandardMaterial3D.new()
   mat.albedo_color = Color("#ffe575")
   mat.emission_enabled = true
   mat.emission = Color("#ffbd5b")
   var view = MeshInstance3D.new()
   view.mesh = mesh
   view.material_override = mat
   hz.add_child(view)
   add_child(hz)
   hazards.append({"node": hz, "ttl": 16.0, "alive": true})
 current_item = ""

func _flash(pos: Vector3, col: Color) -> void:
 if effect_nodes.size() > 42:
  return
 var mesh = SphereMesh.new()
 mesh.radius = 0.21
 mesh.height = 0.42
 mesh.radial_segments = 8
 mesh.rings = 4
 var mat = StandardMaterial3D.new()
 mat.albedo_color = col
 mat.emission_enabled = true
 mat.emission = col
 mat.emission_energy_multiplier = 1.65
 var n = MeshInstance3D.new()
 n.mesh = mesh
 n.material_override = mat
 n.position = pos + Vector3(rng.randf_range(-0.5, 0.5), 0.4, rng.randf_range(-0.5, 0.5))
 add_child(n)
 effect_nodes.append({"node": n, "ttl": 0.95})

func _update_effects(dt: float) -> void:
 for i in range(effect_nodes.size() - 1, -1, -1):
  effect_nodes[i]["ttl"] = float(effect_nodes[i]["ttl"]) - dt
  if effect_nodes[i]["ttl"] <= 0.0:
   effect_nodes[i]["node"].queue_free()
   effect_nodes.remove_at(i)

func _follow_camera(weight: float) -> void:
 if not is_instance_valid(player):
  return
 var forward = Vector3(-sin(yaw), 0.0, -cos(yaw))
 var behind = player.position - forward * 12.0 + Vector3(0, 6.1, 0)
 camera.position = camera.position.lerp(behind, weight)
 camera.look_at(player.position + forward * 8.2 + Vector3(0, 1.4, 0), Vector3.UP)
 camera.fov = lerpf(camera.fov, 72.0 + clampf(speed / 55.0, 0.0, 1.0) * 9.0, weight)

func _finish() -> void:
 if race_state != "racing":
  return
 _update_rank()
 race_state = "finished"
 interface.show_result(race_rank, race_time)

func _unhandled_key_input(event: InputEvent) -> void:
 if not (event is InputEventKey) or not event.pressed or event.echo:
  return
 if event.keycode == KEY_SPACE or event.keycode == KEY_E:
  _use_item()
 if event.keycode == KEY_ESCAPE and race_state == "finished":
  _return_to_menu()
