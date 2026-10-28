extends CanvasLayer
## Landscape-first, touch-safe responsive HUD. All buttons also work with a mouse.
signal start_race
signal selection_changed(index: int)
signal map_selection_changed(index: int)
signal retry_race
signal return_to_menu
signal item_used
signal pause_requested
signal resume_requested
signal music_volume_changed(value: float)
signal sfx_volume_changed(value: float)

const KART = preload("res://scripts/monster_kart.gd")
var chosen := 0
var map_chosen := 0
var map_buttons: Array[Button] = []
var map_info: Label
var left_held := false
var right_held := false
var drift_held := false
var main: Control
var menu: Control
var build_version_label: Label
var hud: Control
var result: Control
var pause_page: Control
var settings: Control
var settings_origin := "menu"
var music_slider: HSlider
var sfx_slider: HSlider
var music_value: Label
var sfx_value: Label
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
 _make_pause()
 _make_settings()
 _add_build_version_badges()
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
 _text(menu, "挑選你的怪獸座駕", Vector2(59, 144), Vector2(380, 40), 21, Color("#eff3ff"))
 var settings_button = _button(menu, "⚙ 設定", Vector2(456, 140), Vector2(134, 43), Color("#365d88"), 19)
 settings_button.pressed.connect(func(): _open_settings("menu"))
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
 _text(menu, "選擇你的冒險賽道", Vector2(678, 361), Vector2(510, 43), 25, Color("#ffffff"), true)
 var maps = ["🎡  怪獸樂園", "🌿  翠綠草原", "🏜  黃金沙漠", "🪐  星環太空"]
 for i in range(4):
  var cx: int = i % 2
  var cy: int = i / 2
  var p = Vector2(668 + cx * 277, 413 + cy * 64)
  var btn = _button(menu, maps[i], p, Vector2(263, 57), Color("#456487"), 21)
  btn.pressed.connect(_select_map.bind(i))
  map_buttons.append(btn)
 map_info = _text(menu, "", Vector2(661, 546), Vector2(567, 41), 18, Color("#fff1ba"), true)
 _select_map(0)
 _text(menu, "DRIFT · BOOST · BATTLE", Vector2(682, 587), Vector2(544, 42), 22, Color("#ffffff"), true)
 _text(menu, "自動加速  ·  左右轉向  ·  按住甩尾  ·  道具攻擊", Vector2(657, 630), Vector2(592, 42), 19, Color("#e9f7ff"), true)
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

func _select_map(index: int) -> void:
 map_chosen = clampi(index, 0, 3)
 var descriptions = ["四大主題魔法樂園 · 夢幻飄浮城堡", "風車牧場 · 花海綠丘 · 森林小屋", "金色沙丘 · 仙人掌 · 古代神殿", "行星星環 · 太空基地 · 銀河賽道"]
 for i in range(map_buttons.size()):
  var color = [Color("#f784b3"), Color("#4ab98f"), Color("#dca46b"), Color("#8175d0")][i]
  map_buttons[i].add_theme_stylebox_override("normal", _style(color if i == map_chosen else color.darkened(0.48), Color("#fff2c4") if i == map_chosen else Color("#ffffff40"), 3 if i == map_chosen else 1, 16))
 map_info.text = descriptions[map_chosen]
 map_selection_changed.emit(map_chosen)

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
 var pause_button = _button(hud, "Ⅱ  暫停", Vector2(483, 24), Vector2(150, 68), Color("#435d8aeb"), 23)
 pause_button.pressed.connect(func(): pause_requested.emit())
 var home_button = _button(hud, "⌂  首頁", Vector2(646, 24), Vector2(150, 68), Color("#435d8aeb"), 23)
 home_button.pressed.connect(func(): return_to_menu.emit())
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
 var result_settings = _button(result, "⚙ 音效設定", Vector2(542, 541), Vector2(200, 43), Color("#406386"), 19)
 result_settings.pressed.connect(func(): _open_settings("result"))

func show_menu() -> void:
 menu.visible = true
 hud.visible = false
 result.visible = false
 pause_page.visible = false
 settings.visible = false
 _release_controls()


func show_race() -> void:
 menu.visible = false
 hud.visible = true
 result.visible = false
 pause_page.visible = false
 settings.visible = false

func show_result(rank: int, time: float) -> void:
 menu.visible = false
 hud.visible = false
 pause_page.visible = false
 settings.visible = false
 _release_controls()
 result.visible = true
 finish_label.text = "第 %d 名！" % rank
 finish_time.text = "完成時間  %02d:%02d" % [int(time) / 60, int(time) % 60]

func _release_controls() -> void:
 left_held = false
 right_held = false
 drift_held = false

func _make_pause() -> void:
 pause_page = Control.new()
 pause_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
 main.add_child(pause_page)
 _panel(pause_page, Vector2.ZERO, Vector2(1280, 720), Color("#091426bf"))
 _panel(pause_page, Vector2(347, 94), Vector2(586, 540), Color("#1a2946f5"), Color("#b8ebff99"), 30)
 _text(pause_page, "Ⅱ  比賽暫停", Vector2(390, 117), Vector2(500, 75), 43, Color("#ffdf91"), true)
 _text(pause_page, "休息一下，怪獸會等你！", Vector2(397, 195), Vector2(484, 49), 22, Color("#c5ecfa"), true)
 var resume_button = _button(pause_page, "▶  繼續比賽", Vector2(395, 260), Vector2(486, 73), Color("#42a785"), 29)
 resume_button.pressed.connect(func(): resume_requested.emit())
 var retry_button = _button(pause_page, "⟲  重新開始", Vector2(395, 346), Vector2(232, 74), Color("#ce6788"), 23)
 retry_button.pressed.connect(func(): retry_race.emit())
 var options_button = _button(pause_page, "⚙  設定", Vector2(647, 346), Vector2(234, 74), Color("#496d9d"), 24)
 options_button.pressed.connect(func(): _open_settings("pause"))
 var home_button = _button(pause_page, "⌂  回首頁選車", Vector2(395, 437), Vector2(486, 77), Color("#3b526f"), 25)
 home_button.pressed.connect(func(): return_to_menu.emit())
 _text(pause_page, "手機觸控或按 ESC 都能繼續", Vector2(390, 547), Vector2(498, 42), 18, Color("#b4c9df"), true)

func _make_settings() -> void:
 settings = Control.new()
 settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
 main.add_child(settings)
 _panel(settings, Vector2.ZERO, Vector2(1280, 720), Color("#081021dd"))
 _panel(settings, Vector2(313, 68), Vector2(654, 587), Color("#192943f7"), Color("#b4eaffaa"), 28)
 _text(settings, "⚙  遊戲設定", Vector2(353, 99), Vector2(574, 68), 42, Color("#ffe3a2"), true)
 _text(settings, "聲音與操控", Vector2(361, 167), Vector2(558, 35), 21, Color("#c0eafe"), true)
 _panel(settings, Vector2(350, 225), Vector2(580, 267), Color("#283b59e6"), Color("#ffffff33"), 18)
 music_value = _text(settings, "🎵  背景配樂  60%", Vector2(382, 239), Vector2(520, 42), 24, Color("#ffffff"))
 music_slider = HSlider.new()
 music_slider.position = Vector2(395, 285)
 music_slider.size = Vector2(490, 38)
 music_slider.min_value = 0.0
 music_slider.max_value = 1.0
 music_slider.step = 0.05
 music_slider.value = 0.60
 settings.add_child(music_slider)
 music_slider.value_changed.connect(func(value: float):
  music_value.text = "🎵  背景配樂  %d%%" % roundi(value * 100.0)
  music_volume_changed.emit(value)
 )
 sfx_value = _text(settings, "🔊  遊戲音效  75%", Vector2(382, 350), Vector2(520, 42), 24, Color("#ffffff"))
 sfx_slider = HSlider.new()
 sfx_slider.position = Vector2(395, 399)
 sfx_slider.size = Vector2(490, 38)
 sfx_slider.min_value = 0.0
 sfx_slider.max_value = 1.0
 sfx_slider.step = 0.05
 sfx_slider.value = 0.75
 settings.add_child(sfx_slider)
 sfx_slider.value_changed.connect(func(value: float):
  sfx_value.text = "🔊  遊戲音效  %d%%" % roundi(value * 100.0)
  sfx_volume_changed.emit(value)
 )
 _text(settings, "操作：自動加速、左右轉向、按住甩尾、點擊道具", Vector2(356, 505), Vector2(572, 45), 19, Color("#dcebf8"), true)
 var close_button = _button(settings, "✔  儲存並返回", Vector2(384, 556), Vector2(514, 73), Color("#46a58e"), 28)
 close_button.pressed.connect(_close_settings)

func set_audio_levels(music: float, effects: float) -> void:
 music_slider.set_value_no_signal(clampf(music, 0.0, 1.0))
 sfx_slider.set_value_no_signal(clampf(effects, 0.0, 1.0))
 music_value.text = "🎵  背景配樂  %d%%" % roundi(music_slider.value * 100.0)
 sfx_value.text = "🔊  遊戲音效  %d%%" % roundi(sfx_slider.value * 100.0)

func _open_settings(origin: String) -> void:
 settings_origin = origin
 menu.visible = false
 hud.visible = false
 result.visible = false
 pause_page.visible = false
 settings.visible = true
 _release_controls()

func _close_settings() -> void:
 match settings_origin:
  "pause":
   show_pause()
  "result":
   settings.visible = false
   result.visible = true
  _:
   show_menu()

func close_settings() -> void:
 if settings.visible:
  _close_settings()

func show_pause() -> void:
 menu.visible = false
 hud.visible = false
 result.visible = false
 settings.visible = false
 pause_page.visible = true
 _release_controls()

func _add_build_version_badges() -> void:
 # Called after all dynamically dispatched screens are created. The actual game
 # uses race_ui_immersive.gd, which overrides the menu/pause/settings builders.
 var version_text = "版本 v" + _build_version()
 build_version_label = _text(menu, version_text, Vector2(637, 110), Vector2(216, 31), 18, Color("#f3f7ff"), true)
 build_version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var pause_badge = _text(pause_page, version_text, Vector2(717, 599), Vector2(211, 29), 16, Color("#d4e9ff"), true)
 pause_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var settings_badge = _text(settings, version_text, Vector2(735, 94), Vector2(196, 30), 17, Color("#d4e9ff"), true)
 settings_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_version() -> String:
 return str(ProjectSettings.get_setting("application/config/version", "0.1.0-dev"))
