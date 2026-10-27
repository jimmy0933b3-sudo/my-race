extends CanvasLayer
## Landscape-first, touch-safe responsive HUD. All buttons also work with a mouse.
signal start_race
signal selection_changed(index: int)
signal retry_race
signal return_to_menu
signal item_used

const KART = preload("res://scripts/monster_kart.gd")
var chosen := 0
var left_held := false
var right_held := false
var drift_held := false
var main: Control
var menu: Control
var hud: Control
var result: Control
var selection_buttons: Array[Button] = []
var selection_name: Label
var selection_stats: Label
var lap_label: Label
var place_label: Label
var speed_label: Label
var time_label: Label
var item_button: Button
var countdown_label: Label
var finish_label: Label
var finish_time: Label

func _ready() -> void:
 main = Control.new()
 main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 main.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(main)
 _make_menu()
 _make_hud()
 _make_result()
 show_menu()

func _style(bg: Color, edge: Color = Color("#ffffff"), width: int = 0, rad: int = 18) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = bg
 style.border_color = edge
 style.set_border_width_all(width)
 style.set_corner_radius_all(rad)
 style.shadow_color = Color(0.12, 0.14, 0.24, 0.22)
 style.shadow_size = 6
 return style

func _panel(parent: Control, pos: Vector2, sz: Vector2, bg: Color, edge: Color = Color.TRANSPARENT, radius: int = 22) -> Panel:
 var p = Panel.new()
 p.position = pos
 p.size = sz
 p.add_theme_stylebox_override("panel", _style(bg, edge, 2 if edge.a > 0.01 else 0, radius))
 parent.add_child(p)
 return p

func _text(parent: Control, caption: String, pos: Vector2, sz: Vector2, font_size: int, col: Color = Color.WHITE, center := false) -> Label:
 var l = Label.new()
 l.text = caption
 l.position = pos
 l.size = sz
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", col)
 l.add_theme_color_override("font_shadow_color", Color(0.08, 0.12, 0.25, 0.4))
 l.add_theme_constant_override("shadow_offset_x", 1)
 l.add_theme_constant_override("shadow_offset_y", 2)
 if center:
  l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(l)
 return l

func _button(parent: Control, caption: String, pos: Vector2, sz: Vector2, bg: Color, size: int = 23) -> Button:
 var b = Button.new()
 b.text = caption
 b.position = pos
 b.size = sz
 b.focus_mode = Control.FOCUS_NONE
 b.add_theme_font_size_override("font_size", size)
 b.add_theme_color_override("font_color", Color("#ffffff"))
 b.add_theme_color_override("font_hover_color", Color("#ffffff"))
 b.add_theme_stylebox_override("normal", _style(bg, Color("#ffffff63"), 2, 17))
 b.add_theme_stylebox_override("hover", _style(bg.lightened(0.16), Color("#ffffff"), 2, 17))
 b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.22), Color("#fff8c1"), 3, 17))
 parent.add_child(b)
 return b

func _make_menu() -> void:
 menu = Control.new()
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
 main.add_child(menu)
 var bg = _panel(menu, Vector2(27, 25), Vector2(590, 668), Color("#17233aeb"), Color("#b5ddff66"), 28)
 _text(menu, "MONSTER KART", Vector2(56, 42), Vector2(522, 55), 43, Color("#ffdb82"))
 _text(menu, "怪獸甩尾盃  ·  3D", Vector2(58, 95), Vector2(486, 42), 25, Color("#b5e9ff"))
 _text(menu, "挑選你的怪獸座駕", Vector2(59, 144), Vector2(420, 40), 21, Color("#eff3ff"))
 for i in range(12):
  var row = i / 4
  var col = i % 4
  var data = KART.ROSTER[i]
  var p = Vector2(54.0 + float(col) * 135.5, 192.0 + float(row) * 91.0)
  var color = Color(data["color"]).darkened(0.40)
  var btn = _button(menu, str(data["eng"]) + "\n" + str(data["name"]), p, Vector2(126, 82), color, 16)
  btn.pressed.connect(_select.bind(i))
  selection_buttons.append(btn)
 _panel(menu, Vector2(54, 484), Vector2(536, 88), Color("#283b55"), Color("#ffffff3b"), 18)
 selection_name = _text(menu, "", Vector2(73, 487), Vector2(270, 40), 27, Color("#fff3c9"))
 selection_stats = _text(menu, "", Vector2(75, 533), Vector2(472, 31), 19, Color("#c2f5f0"))
 var start = _button(menu, "🏁  開始怪獸大賽", Vector2(54, 586), Vector2(536, 77), Color("#ef617a"), 29)
 start.pressed.connect(func(): start_race.emit())
 _text(menu, "DRIFT · BOOST · BATTLE", Vector2(682, 561), Vector2(544, 52), 23, Color("#ffffff"), true)
 _text(menu, "自動加速  ·  左右轉向  ·  按住甩尾  ·  道具攻擊", Vector2(657, 609), Vector2(592, 45), 19, Color("#e9f7ff"), true)
 _select(0)

func _select(index: int) -> void:
 chosen = index
 var data = KART.ROSTER[chosen]
 for i in range(selection_buttons.size()):
  var btn = selection_buttons[i]
  var col = Color(KART.ROSTER[i]["color"])
  btn.add_theme_stylebox_override("normal", _style(col.darkened(0.26) if i == chosen else col.darkened(0.68), Color("#fff2b0") if i == chosen else Color("#8db0c277"), 3 if i == chosen else 1, 16))
 selection_name.text = str(data["name"]) + "  ·  " + str(data["eng"])
 selection_stats.text = "極速 " + "★".repeat(int(data["speed"])) + "   操控 " + "★".repeat(int(data["grip"]))
 selection_changed.emit(chosen)

func _make_hud() -> void:
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 main.add_child(hud)
 _panel(hud, Vector2(24, 22), Vector2(314, 111), Color("#1a2645e8"), Color("#ffffff55"))
 place_label = _text(hud, "第 1 / 8 名", Vector2(44, 34), Vector2(277, 49), 29, Color("#fff1af"))
 lap_label = _text(hud, "第 1 / 3 圈", Vector2(45, 84), Vector2(290, 38), 20, Color("#d3f6ff"))
 _panel(hud, Vector2(1002, 22), Vector2(250, 111), Color("#1a2645e8"), Color("#ffffff55"))
 speed_label = _text(hud, "0 KM/H", Vector2(1014, 34), Vector2(228, 50), 32, Color("#ffe795"), true)
 time_label = _text(hud, "00:00", Vector2(1026, 84), Vector2(200, 31), 19, Color("#d2faff"), true)
 countdown_label = _text(hud, "", Vector2(410, 112), Vector2(460, 160), 80, Color("#fff5b4"), true)
 var left = _button(hud, "◀", Vector2(28, 556), Vector2(136, 133), Color("#344d79d9"), 55)
 var right = _button(hud, "▶", Vector2(175, 556), Vector2(136, 133), Color("#344d79d9"), 55)
 left.button_down.connect(func(): left_held = true)
 left.button_up.connect(func(): left_held = false)
 right.button_down.connect(func(): right_held = true)
 right.button_up.connect(func(): right_held = false)
 var drift = _button(hud, "↪\n甩尾", Vector2(1005, 543), Vector2(133, 144), Color("#bc5daedb"), 26)
 drift.button_down.connect(func(): drift_held = true)
 drift.button_up.connect(func(): drift_held = false)
 item_button = _button(hud, "🎁\n道具", Vector2(1144, 543), Vector2(108, 144), Color("#e3a454e8"), 24)
 item_button.pressed.connect(func(): item_used.emit())
 _text(hud, "自動加速", Vector2(500, 644), Vector2(260, 40), 22, Color("#fff8e7"), true)

func update_hud(place: int, lap: int, speed: float, time: float, item: String) -> void:
 place_label.text = "第 %d / 8 名" % place
 lap_label.text = "第 %d / 3 圈" % mini(lap, 3)
 speed_label.text = "%d KM/H" % int(speed * 3.0)
 time_label.text = "%02d:%02d" % [int(time) / 60, int(time) % 60]
 item_button.text = item if item != "" else "🎁\n道具"
 item_button.disabled = item == ""

func show_countdown(s: String) -> void:
 countdown_label.text = s

func _make_result() -> void:
 result = Control.new()
 result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 main.add_child(result)
 _panel(result, Vector2(345, 134), Vector2(592, 459), Color("#172743f2"), Color("#b6eaffaa"), 31)
 _text(result, "🏆  怪獸衝線！", Vector2(377, 161), Vector2(530, 73), 42, Color("#ffdf86"), true)
 finish_label = _text(result, "", Vector2(399, 248), Vector2(483, 89), 48, Color("#ffffff"), true)
 finish_time = _text(result, "", Vector2(399, 339), Vector2(483, 51), 24, Color("#b7f5fa"), true)
 var retry = _button(result, "再賽一場", Vector2(388, 437), Vector2(234, 94), Color("#e95f82"), 28)
 var home = _button(result, "選擇怪獸", Vector2(654, 437), Vector2(240, 94), Color("#456a96"), 27)
 retry.pressed.connect(func(): retry_race.emit())
 home.pressed.connect(func(): return_to_menu.emit())

func show_menu() -> void:
 menu.visible = true
 hud.visible = false
 result.visible = false
 left_held = false
 right_held = false
 drift_held = false

func show_race() -> void:
 menu.visible = false
 hud.visible = true
 result.visible = false

func show_result(rank: int, time: float) -> void:
 menu.visible = false
 hud.visible = false
 result.visible = true
 finish_label.text = "第 %d 名！" % rank
 finish_time.text = "完成時間  %02d:%02d" % [int(time) / 60, int(time) % 60]
