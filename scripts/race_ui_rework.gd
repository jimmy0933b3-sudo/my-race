extends "res://scripts/race_ui.gd"
## Complete skin/layout rebuild with one cohesive graphic identity.
## Inherits battle controls and signals from the tested UI interface.
signal quality_changed(level: int)
var quality_level := 3
var quality_buttons: Array[Button] = []
var quality_description: Label
const BADGE = preload("res://scripts/garage_badge.gd")
const LIVE_MAP = preload("res://scripts/race_minimap.gd")
var race_minimap
const PALETTE = {
 "night": Color("#101c35ee"),
 "panel": Color("#1d2c49ec"),
 "paper": Color("#f5f3e9"),
 "mint": Color("#87eee0"),
 "pink": Color("#ff839e"),
 "gold": Color("#ffe19a"),
 "muted": Color("#b8c7db")
}
var boost_bar: ProgressBar
var map_title: Label

func _glow_panel(container:Control,p:Vector2,s:Vector2,accent:Color,base:Color=Color("#15233aef"),roundness:int=24)->Panel:
 var panel=_panel(container,p,s,base,Color("#ffffff46"),roundness)
 var stripe=ColorRect.new()
 stripe.position=Vector2(0,14)
 stripe.size=Vector2(5,s.y-28)
 stripe.color=accent
 stripe.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_child(stripe)
 return panel

func _small_label(parent:Control,text:String,pt:Vector2,width:int=320)->Label:
 return _text(parent,text,pt,Vector2(width,28),15,PALETTE["muted"])

func _make_menu() -> void:
 menu=Control.new()
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(menu)
 # Three-column gaming dashboard: character deck, 3D showroom, course library.
 _glow_panel(menu,Vector2(19,18),Vector2(364,677),PALETTE["mint"])
 _text(menu,"M   K",Vector2(42,36),Vector2(140,38),30,PALETTE["mint"])
 _text(menu,"MONSTER KART",Vector2(42,78),Vector2(318,49),35,PALETTE["paper"])
 _small_label(menu,"怪獸甩尾盃  /  CHAMPIONSHIP",Vector2(44,130))
 _text(menu,"01  選擇怪獸車",Vector2(42,168),Vector2(322,43),24,PALETTE["gold"])
 var sett=_button(menu,"⚙",Vector2(315,39),Vector2(48,44),Color("#344663"),22)
 sett.pressed.connect(func():_open_settings("menu"))
 var divider=ColorRect.new()
 divider.position=Vector2(44,208)
 divider.size=Vector2(308,2)
 divider.color=Color("#a8c7d350")
 menu.add_child(divider)
 for i in range(12):
  var col=i%3
  var row=i/3
  var data=KART.ROSTER[i]
  var p=Vector2(39+col*109,222+row*80)
  var color=Color(data["color"])
  var b=_button(menu,"",p,Vector2(103,74),color.darkened(0.54),14)
  var portrait=BADGE.new()
  portrait.position=Vector2(1,10)
  portrait.size=Vector2(53,53)
  b.add_child(portrait)
  portrait.setup_monster(i)
  var card_name=_text(b,str(data["eng"]),Vector2(52,21),Vector2(49,22),12,PALETTE["paper"],true)
  card_name.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var number=_text(b,"%02d" % (i+1),Vector2(54,45),Vector2(44,18),12,PALETTE["gold"],true)
  number.mouse_filter=Control.MOUSE_FILTER_IGNORE
  b.pressed.connect(_select.bind(i))
  selection_buttons.append(b)
 _small_label(menu,"SELECTED DRIVER",Vector2(43,555),294)
 selection_name=_text(menu,"",Vector2(42,580),Vector2(316,34),22,PALETTE["paper"])
 selection_stats=_text(menu,"",Vector2(43,619),Vector2(319,27),15,PALETTE["mint"])
 _glow_panel(menu,Vector2(899,18),Vector2(363,677),PALETTE["pink"])
 _text(menu,"02  選擇賽道",Vector2(923,45),Vector2(321,45),28,PALETTE["gold"])
 _small_label(menu,"PICK YOUR WORLD",Vector2(923,93),315)
 var maps=["怪獸嘉年華","翠綠大草原","黃金沙漠","星環太空"]
 var tags=["MONSTER PARK","EMERALD VALLEY","DUNE EXPEDITION","ORBITAL CIRCUIT"]
 var accent=[Color("#f68aaf"),Color("#7ed9a6"),Color("#ffc57d"),Color("#a6a7fc")]
 for i in range(4):
  var y=141+i*97
  var card=_glow_panel(menu,Vector2(917,y),Vector2(324,88),accent[i],accent[i].darkened(0.68),16)
  card.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var button=_button(menu,"",Vector2(926,y+5),Vector2(303,53),accent[i].darkened(0.58),22)
  var image=BADGE.new()
  image.position=Vector2(7,4)
  image.size=Vector2(45,45)
  button.add_child(image)
  image.setup_course(i)
  var title=_text(button,maps[i],Vector2(62,6),Vector2(225,40),22,PALETTE["paper"])
  title.mouse_filter=Control.MOUSE_FILTER_IGNORE
  button.pressed.connect(_select_map.bind(i))
  map_buttons.append(button)
  _small_label(menu,tags[i],Vector2(956,y+56),255)
 map_info=_text(menu,"",Vector2(921,537),Vector2(320,43),17,PALETTE["mint"],true)
 _select_map(0)
 var begin=_button(menu,"▶   開始比賽",Vector2(920,598),Vector2(324,76),Color("#f06c88"),29)
 begin.pressed.connect(func():start_race.emit())
 # Floating transparent lower third. The rotating 3D hero stays unobstructed.
 _text(menu,"3D MONSTER GARAGE",Vector2(405,50),Vector2(482,45),24,PALETTE["paper"],true)
 _small_label(menu,"12 ORIGINAL KARTS   •   4 TRACKS   •   8 RACERS",Vector2(450,97),438)
 _text(menu,"NO LIMITS. JUST FUN.",Vector2(411,635),Vector2(466,37),20,PALETTE["gold"],true)
 _select(0)

func _make_hud() -> void:
 hud=Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(hud)
 _glow_panel(hud,Vector2(22,22),Vector2(265,117),PALETTE["gold"])
 _small_label(hud,"POSITION  /  RANK",Vector2(44,29),239)
 place_label=_text(hud,"1 / 8",Vector2(43,55),Vector2(230,45),33,PALETTE["gold"])
 lap_label=_text(hud,"第 1 / 3 圈",Vector2(44,101),Vector2(228,27),18,PALETTE["paper"])
 _glow_panel(hud,Vector2(1004,22),Vector2(254,120),PALETTE["mint"])
 _small_label(hud,"SPEED / RACE TIME",Vector2(1025,29),231)
 speed_label=_text(hud,"0 KM/H",Vector2(1024,54),Vector2(223,44),29,PALETTE["mint"],true)
 time_label=_text(hud,"00:00",Vector2(1024,98),Vector2(223,33),19,PALETTE["paper"],true)
 _glow_panel(hud,Vector2(1004,156),Vector2(254,254),PALETTE["mint"],Color("#111f38ef"),22)
 _small_label(hud,"全賽道  •  8 位選手",Vector2(1024,167),220)
 race_minimap=LIVE_MAP.new()
 race_minimap.position=Vector2(1014,197)
 race_minimap.size=Vector2(234,202)
 race_minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(race_minimap)
 _glow_panel(hud,Vector2(441,18),Vector2(392,75),Color("#a5d6fa"),Color("#17233be3"),18)
 map_title=_text(hud,"MONSTER GRAND PRIX",Vector2(452,22),Vector2(370,29),18,PALETTE["paper"],true)
 boost_bar=ProgressBar.new()
 boost_bar.position=Vector2(465,60)
 boost_bar.size=Vector2(345,13)
 boost_bar.min_value=0
 boost_bar.max_value=100
 boost_bar.value=0
 boost_bar.show_percentage=false
 boost_bar.add_theme_stylebox_override("background",_style(Color("#40516d"),Color("#ffffff20"),1,8))
 boost_bar.add_theme_stylebox_override("fill",_style(PALETTE["mint"],PALETTE["mint"],0,8))
 hud.add_child(boost_bar)
 countdown_label=_text(hud,"",Vector2(417,170),Vector2(450,154),75,PALETTE["gold"],true)
 var left=_button(hud,"◀",Vector2(25,544),Vector2(145,145),Color("#294b73e8"),59)
 var right=_button(hud,"▶",Vector2(179,544),Vector2(145,145),Color("#294b73e8"),59)
 left.button_down.connect(func():left_held=true)
 left.button_up.connect(func():left_held=false)
 right.button_down.connect(func():right_held=true)
 right.button_up.connect(func():right_held=false)
 var drift=_button(hud,"↪\nDRIFT",Vector2(972,546),Vector2(138,143),Color("#9b57afea"),24)
 drift.button_down.connect(func():drift_held=true)
 drift.button_up.connect(func():drift_held=false)
 item_button=_button(hud,"✦\nITEM",Vector2(1119,546),Vector2(138,143),Color("#c99050ee"),23)
 item_button.pressed.connect(func():item_used.emit())
 var pause=_button(hud,"Ⅱ",Vector2(855,27),Vector2(58,62),Color("#425778e5"),28)
 pause.pressed.connect(func():pause_requested.emit())
 var home=_button(hud,"⌂",Vector2(925,27),Vector2(61,62),Color("#425778e5"),27)
 home.pressed.connect(func():return_to_menu.emit())
 _text(hud,"AUTO DRIVE",Vector2(481,649),Vector2(330,33),17,PALETTE["paper"],true)

func configure_minimap(track:Node3D,map_index:int)->void:
 if race_minimap != null:
  race_minimap.configure(track)
 map_title.text=["MONSTER FESTIVAL GP","EMERALD MEADOWS GP","GOLDEN DUNES GP","ORBITAL STAR RING GP"][clampi(map_index,0,3)]

func update_minimap(hero:Vector3,heading:float,bots:Array[Dictionary])->void:
 if race_minimap != null:
  race_minimap.update_racers(hero,heading,bots)

func update_hud(place:int,lap:int,speed:float,time:float,item:String)->void:
 super.update_hud(place,lap,speed,time,item)
 boost_bar.value=clampf(speed/52.0,0.0,1.0)*100.0
 item_button.text=item if item!="" else "✦\nITEM"

func _make_result() -> void:
 result=Control.new()
 result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(result)
 _panel(result,Vector2.ZERO,Vector2(1280,720),Color("#0a152acc"))
 _glow_panel(result,Vector2(347,104),Vector2(586,506),PALETTE["gold"],Color("#152540f9"),34)
 _text(result,"MONSTER GRAND PRIX",Vector2(390,131),Vector2(500,38),24,PALETTE["mint"],true)
 _text(result,"🏆  衝線！",Vector2(399,192),Vector2(484,62),45,PALETTE["gold"],true)
 finish_label=_text(result,"",Vector2(386,269),Vector2(510,69),49,PALETTE["paper"],true)
 finish_time=_text(result,"",Vector2(404,360),Vector2(480,52),25,PALETTE["mint"],true)
 var again=_button(result,"再賽一場",Vector2(388,461),Vector2(230,89),Color("#e87891"),26)
 again.pressed.connect(func():retry_race.emit())
 var garage=_button(result,"回車庫",Vector2(650,461),Vector2(237,89),Color("#416b93"),27)
 garage.pressed.connect(func():return_to_menu.emit())
 var settings_button=_button(result,"⚙ 設定",Vector2(555,555),Vector2(168,42),Color("#384b6f"),17)
 settings_button.pressed.connect(func():_open_settings("result"))

func _make_pause() -> void:
 pause_page=Control.new()
 pause_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_page.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(pause_page)
 _panel(pause_page,Vector2.ZERO,Vector2(1280,720),Color("#0b1428c5"))
 _glow_panel(pause_page,Vector2(339,91),Vector2(601,539),PALETTE["mint"],Color("#172743fa"),32)
 _text(pause_page,"PAUSE MENU",Vector2(380,117),Vector2(520,46),26,PALETTE["mint"],true)
 _text(pause_page,"Ⅱ  比賽暫停",Vector2(392,180),Vector2(500,64),45,PALETTE["paper"],true)
 _small_label(pause_page,"休息一下，賽道與怪獸都在等你",Vector2(448,258),425)
 var go=_button(pause_page,"▶  繼續比賽",Vector2(400,325),Vector2(478,69),Color("#36a494"),28)
 go.pressed.connect(func():resume_requested.emit())
 var retry=_button(pause_page,"⟲  再來一次",Vector2(401,412),Vector2(224,72),Color("#ce6885"),22)
 retry.pressed.connect(func():retry_race.emit())
 var home=_button(pause_page,"⌂  回車庫",Vector2(645,412),Vector2(234,72),Color("#456c91"),23)
 home.pressed.connect(func():return_to_menu.emit())
 var opts=_button(pause_page,"⚙  聲音與設定",Vector2(401,512),Vector2(478,66),Color("#394f76"),24)
 opts.pressed.connect(func():_open_settings("pause"))

func _make_settings() -> void:
 settings=Control.new()
 settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 settings.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(settings)
 _panel(settings,Vector2.ZERO,Vector2(1280,720),Color("#0b142be1"))
 _glow_panel(settings,Vector2(319,37),Vector2(644,654),PALETTE["pink"],Color("#172743fa"),32)
 _text(settings,"SETTINGS  /  AUDIO + GRAPHICS",Vector2(356,59),Vector2(565,45),23,PALETTE["mint"],true)
 _text(settings,"⚙ 遊戲設定",Vector2(365,111),Vector2(546,51),36,PALETTE["paper"],true)
 _glow_panel(settings,Vector2(366,186),Vector2(548,271),PALETTE["mint"],Color("#263955"),18)
 music_value=_text(settings,"背景配樂 60%",Vector2(393,202),Vector2(470,36),22,PALETTE["paper"])
 music_slider=HSlider.new()
 music_slider.position=Vector2(408,243)
 music_slider.size=Vector2(460,34)
 music_slider.min_value=0
 music_slider.max_value=1
 music_slider.step=0.05
 music_slider.value=0.6
 settings.add_child(music_slider)
 music_slider.value_changed.connect(func(v:float):
  music_value.text="背景配樂  %d%%" % roundi(v*100.0)
  music_volume_changed.emit(v))
 sfx_value=_text(settings,"遊戲音效 75%",Vector2(393,320),Vector2(470,36),22,PALETTE["paper"])
 sfx_slider=HSlider.new()
 sfx_slider.position=Vector2(408,367)
 sfx_slider.size=Vector2(460,34)
 sfx_slider.min_value=0
 sfx_slider.max_value=1
 sfx_slider.step=0.05
 sfx_slider.value=0.75
 settings.add_child(sfx_slider)
 sfx_slider.value_changed.connect(func(v:float):
  sfx_value.text="遊戲音效  %d%%" % roundi(v*100.0)
  sfx_volume_changed.emit(v))
 _text(settings,"畫質  /  GRAPHICS",Vector2(388,470),Vector2(509,33),22,PALETTE["gold"])
 var names = ["省電", "標準", "精緻", "極致"]
 for i in range(3):
  var button=_button(settings,names[i],Vector2(386+i*132,510),Vector2(122,49),Color("#426182"),20)
  button.pressed.connect(_select_quality.bind(i))
  quality_buttons.append(button)
 quality_description=_text(settings,"",Vector2(378,570),Vector2(528,29),17,PALETTE["muted"],true)
 set_quality_level(quality_level,false)
 var back=_button(settings,"儲存並返回",Vector2(395,609),Vector2(487,66),Color("#3bab9d"),26)
 back.pressed.connect(_close_settings)

func set_quality_level(value: int, notify: bool = false) -> void:
 quality_level=clampi(value,0,3)
 var descriptions = [
  "省電：關閉額外光影和抗鋸齒，低功耗遊玩",
  "標準：2× 平滑邊緣、柔和光影、較豐富場景",
  "精緻：4× 抗鋸齒、環境泛光、更多場景細節",
  "極致：8× 抗鋸齒、遠距柔影、完整場景細節"
 ]
 if quality_description!=null:
  quality_description.text=descriptions[quality_level]
 for i in range(quality_buttons.size()):
  var selected = i==quality_level
  quality_buttons[i].add_theme_stylebox_override("normal",_style(Color("#489f9c") if selected else Color("#314762"),Color("#ffe4a2") if selected else Color("#71829b"),3 if selected else 1,14))
 if notify:
  quality_changed.emit(quality_level)

func _select_quality(level: int) -> void:
 set_quality_level(level,true)
