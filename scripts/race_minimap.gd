extends Control
## Full-course live tactical map, independently scaled to each circuit.
## Blue/white arrow = player, colored numbered circles = seven other karts.
## Static circuit points are cached; only markers are redrawn during gameplay.
const FRAME_PAD := 15.0
var circuit
var mapped_points := PackedVector2Array()
var world_min := Vector2.ZERO
var world_range := Vector2.ONE
var course_color := Color("#92eaf7")
var racers: Array[Dictionary] = []
var player_pos := Vector3.ZERO
var player_heading := 0.0
var is_ready := false
var bounds_valid := false
var show_numbers := true

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true

func configure(track: Node3D) -> void:
 circuit = track
 is_ready = false
 mapped_points.clear()
 if track == null or track.centers.size() < 3:
  bounds_valid = false
  queue_redraw()
  return
 var min_x = INF
 var min_z = INF
 var max_x = -INF
 var max_z = -INF
 for p in track.centers:
  min_x = minf(min_x, p.x)
  max_x = maxf(max_x, p.x)
  min_z = minf(min_z, p.z)
  max_z = maxf(max_z, p.z)
 var padding_x = (max_x - min_x) * 0.13
 var padding_z = (max_z - min_z) * 0.13
 world_min = Vector2(min_x - padding_x, min_z - padding_z)
 world_range = Vector2(max_x - min_x + padding_x * 2.0, max_z - min_z + padding_z * 2.0)
 bounds_valid = true
 course_color = [
  Color("#ffc7df"), Color("#8cf2c8"),
  Color("#ffe19e"), Color("#a0d8ff")
 ][clampi(track.map_index, 0, 3)]
 for point in track.centers:
  mapped_points.append(_map_point(point))
 mapped_points.append(mapped_points[0])
 is_ready = true
 queue_redraw()

func _map_point(pos: Vector3) -> Vector2:
 var available = Vector2(maxf(1.0, size.x - FRAME_PAD * 2.0), maxf(1.0, size.y - FRAME_PAD * 2.0))
 var ratio = minf(available.x / maxf(1.0, world_range.x), available.y / maxf(1.0, world_range.y))
 var rendered = world_range * ratio
 var starting = (size - rendered) * 0.5
 return starting + Vector2((pos.x - world_min.x) * ratio, (pos.z - world_min.y) * ratio)

func update_racers(hero: Vector3, heading: float, bots: Array[Dictionary]) -> void:
 player_pos = hero
 player_heading = heading
 racers.clear()
 for j in range(bots.size()):
  var bot = bots[j]
  if is_instance_valid(bot["car"]):
   racers.append({"position": bot["car"].position, "color": bot["color"] if bot.has("color") else Color("#ffaab9"), "num": j + 2})
 queue_redraw()

func _draw() -> void:
 var base = Color("#0a1630de")
 draw_rect(Rect2(Vector2.ZERO,size),base)
 for n in range(1,4):
  var px = float(n) * size.x / 4.0
  var pz = float(n) * size.y / 4.0
  draw_line(Vector2(px,0),Vector2(px,size.y),Color("#b4eaff10"),1.0)
  draw_line(Vector2(0,pz),Vector2(size.x,pz),Color("#b4eaff10"),1.0)
 if not is_ready or mapped_points.size() < 3:
  return
 # Whole track fits inside this map, respecting both width and height.
 draw_polyline(mapped_points, Color("#192e4d"), 18.0, true)
 draw_polyline(mapped_points, course_color, 14.0, true)
 draw_polyline(mapped_points, Color("#253551"), 9.2, true)
 draw_polyline(mapped_points, Color("#bccfda8a"), 1.0, true)
 var start = mapped_points[0]
 draw_line(start + Vector2(-8,-8),start + Vector2(8,8),Color("#fff6c1"),3.0,true)
 for bot in racers:
  var dot = _map_point(bot["position"])
  draw_circle(dot,7.4,Color("#14243f"))
  draw_circle(dot,5.45,bot["color"])
  if show_numbers:
   draw_string(ThemeDB.fallback_font,dot+Vector2(-2.8,3.2),str(bot["num"]),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("#102038"))
 var hero = _map_point(player_pos)
 var direction = Vector2(-sin(player_heading),-cos(player_heading)).normalized()
 var side = Vector2(-direction.y,direction.x)
 var triangle = PackedVector2Array([
  hero + direction * 11.3,
  hero - direction * 6.7 + side * 6.4,
  hero - direction * 6.7 - side * 6.4
 ])
 draw_colored_polygon(triangle,Color("#ffffff"))
 draw_polyline(PackedVector2Array([triangle[0],triangle[1],triangle[2],triangle[0]]),Color("#183357"),2.0,true)
 draw_circle(hero,2.2,Color("#2981ea"))
