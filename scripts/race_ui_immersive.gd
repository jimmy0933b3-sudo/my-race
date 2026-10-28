extends "res://scripts/race_ui_rework.gd"
## Complete art-directed third-generation garage and race layout.
## Keeps the proven controller, pause, item and settings contracts intact.
const TRACK_POSTER = preload("res://scripts/track_poster.gd")
const TELEMETRY = preload("res://scripts/race_telemetry.gd")
var telemetry
var course_detail:Label
var race_stage:Label
var current_driver_icon
var stage_marker:Control

func _decorate_dot(parent:Control,pos:Vector2,color:Color,diameter:float=7.0)->void:
 var rect=ColorRect.new()
 rect.color=color
 rect.position=pos
 rect.size=Vector2(diameter,diameter)
 rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(rect)

func _make_menu()->void:
 menu=Control.new()
 menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 menu.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(menu)
 # Permanently legible chaptered navigation instead of generic stacked buttons.
 _glow_panel(menu,Vector2(14,14),Vector2(351,690),PALETTE["mint"],Color("#111f36ee"),26)
 _glow_panel(menu,Vector2(899,14),Vector2(367,690),PALETTE["pink"],Color("#14243cef"),26)
 _glow_panel(menu,Vector2(382,19),Vector2(496,112),Color("#9ceaff"),Color("#10203bdc"),24)
 _text(menu,"M O N S T E R  K A R T",Vector2(37,34),Vector2(298,43),25,PALETTE["mint"])
 _text(menu,"怪獸甩尾大賽",Vector2(36,80),Vector2(306,48),31,PALETTE["paper"])
 _small_label(menu,"CHOOSE YOUR HERO  /  01",Vector2(37,138),300)
 _text(menu,"12 隻怪獸 · 選出你的夥伴",Vector2(36,174),Vector2(307,34),19,PALETTE["gold"])
 var settings_button=_button(menu,"⚙",Vector2(306,28),Vector2(45,44),Color("#405e72"),22)
 settings_button.pressed.connect(func():_open_settings("menu"))
 # Each racer is an illustrated vinyl-art figure badge, not a name-only list.
 for i in range(12):
  var col=i%3
  var row=int(i/3)
  var data=KART.ROSTER[i]
  var tone=Color(str(data["color"]))
  var p=Vector2(35+col*105,218+row*86)
  var b=_button(menu,"",p,Vector2(100,80),tone.darkened(0.64),12)
  b.pressed.connect(_select.bind(i))
  var portrait=BADGE.new()
  portrait.position=Vector2(9,5)
  portrait.size=Vector2(53,53)
  b.add_child(portrait)
  portrait.setup_monster(i)
  var name_tag=_text(b,str(data["eng"]),Vector2(2,61),Vector2(96,17),12,Color("#f8f6ec"),true)
  name_tag.mouse_filter=Control.MOUSE_FILTER_IGNORE
  selection_buttons.append(b)
 _glow_panel(menu,Vector2(30,576),Vector2(319,107),PALETTE["gold"],Color("#284061e6"),15)
 _small_label(menu,"YOUR MONSTER",Vector2(45,582),280)
 selection_name=_text(menu,"",Vector2(45,609),Vector2(285,34),21,PALETTE["paper"])
 selection_stats=_text(menu,"",Vector2(45,646),Vector2(289,25),15,PALETTE["mint"])
 # Showroom title is delicately inset above the rotating real 3D model.
 _text(menu,"MONSTER 3D GARAGE",Vector2(410,35),Vector2(445,41),26,PALETTE["paper"],true)
 _small_label(menu,"全 3D 怪獸車 · 輪圈細節 · 真實光影",Vector2(468,83),380)
 _text(menu,"★  收藏你的冠軍 ★",Vector2(417,563),Vector2(440,40),23,PALETTE["gold"],true)
 _glow_panel(menu,Vector2(393,628),Vector2(474,57),PALETTE["mint"],Color("#1b3250df"),15)
 _text(menu,"左 / 右轉向    ·    按住甩尾    ·    點擊使用道具",Vector2(401,640),Vector2(454,34),18,PALETTE["paper"],true)
 # World-selector poster cards tell a coherent environmental story.
 _text(menu,"CHOOSE YOUR WORLD",Vector2(921,37),Vector2(316,36),24,PALETTE["gold"])
 _small_label(menu,"02  /  FOUR WORLDS TO EXPLORE",Vector2(921,78),306)
 var names=["夢幻怪獸樂園","翠綠風車草原","黃金沙漠遺跡","星環太空基地"]
 var sub=["FESTIVAL  ·  摩天輪","MEADOW  ·  風車與花田","DESERT  ·  階梯神殿","SPACE  ·  太空星環"]
 var tint=[Color("#dc91ac"),Color("#8ddfba"),Color("#eac099"),Color("#a1a2ea")]
 for i in range(4):
  var y=122.0+108.0*float(i)
  var p=Vector2(916,y)
  var card=_button(menu,"",p,Vector2(330,98),tint[i].darkened(0.63),18)
  card.pressed.connect(_select_map.bind(i))
  var painting=TRACK_POSTER.new()
  painting.position=Vector2(8,8)
  painting.size=Vector2(96,82)
  card.add_child(painting)
  painting.setup(i)
  var t=_text(card,names[i],Vector2(115,12),Vector2(202,35),21,PALETTE["paper"])
  t.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var small=_text(card,sub[i],Vector2(117,48),Vector2(197,28),14,Color("#d2e1ec"))
  small.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var arrow=_text(card,"▶",Vector2(286,70),Vector2(30,22),16,tint[i],true)
  arrow.mouse_filter=Control.MOUSE_FILTER_IGNORE
  map_buttons.append(card)
 map_info=_text(menu,"",Vector2(918,561),Vector2(323,30),15,PALETTE["mint"],true)
 var play_button=_button(menu,"▶   出發！開始冒險",Vector2(917,607),Vector2(330,76),Color("#d96787"),25)
 play_button.pressed.connect(func():start_race.emit())
 _select_map(0)
 _select(0)

func _make_hud()->void:
 hud=Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(hud)
 _glow_panel(hud,Vector2(17,15),Vector2(278,132),PALETTE["gold"],Color("#172942f1"),21)
 _small_label(hud,"RACE POSITION",Vector2(36,24),237)
 current_driver_icon=BADGE.new()
 current_driver_icon.position=Vector2(38,67)
 current_driver_icon.size=Vector2(70,70)
 hud.add_child(current_driver_icon)
 current_driver_icon.setup_monster(0)
 place_label=_text(hud,"第 1 / 8 名",Vector2(120,53),Vector2(161,55),31,PALETTE["gold"])
 lap_label=_text(hud,"第 1 / 3 圈",Vector2(119,104),Vector2(161,29),18,PALETTE["paper"])
 # Sky-box central ribbon with large contrasting stage label.
 _glow_panel(hud,Vector2(324,14),Vector2(585,93),Color("#97d7f5"),Color("#142947ed"),20)
 race_stage=_text(hud,"🏁  MONSTER CHAMPIONSHIP",Vector2(349,21),Vector2(533,27),16,PALETTE["mint"],true)
 map_title=_text(hud,"MONSTER FESTIVAL GP",Vector2(346,48),Vector2(535,30),22,PALETTE["paper"],true)
 boost_bar=ProgressBar.new()
 boost_bar.position=Vector2(383,92)
 boost_bar.size=Vector2(467,8)
 boost_bar.min_value=0
 boost_bar.max_value=100
 boost_bar.value=0
 boost_bar.show_percentage=false
 boost_bar.add_theme_stylebox_override("background",_style(Color("#354b68"),Color.TRANSPARENT,0,6))
 boost_bar.add_theme_stylebox_override("fill",_style(PALETTE["mint"],Color.TRANSPARENT,0,6))
 hud.add_child(boost_bar)
 # Distinct pause/home action zones with large touch targets.
 var pause_button=_button(hud,"Ⅱ",Vector2(922,24),Vector2(61,73),Color("#304c67ef"),30)
 pause_button.pressed.connect(func():pause_requested.emit())
 var home_button=_button(hud,"⌂",Vector2(991,24),Vector2(61,73),Color("#304c67ef"),31)
 home_button.pressed.connect(func():return_to_menu.emit())
 _glow_panel(hud,Vector2(1061,16),Vector2(205,116),PALETTE["mint"],Color("#172942f1"),20)
 _small_label(hud,"RACE TIME",Vector2(1086,25),166)
 time_label=_text(hud,"00:00",Vector2(1077,51),Vector2(172,39),27,PALETTE["paper"],true)
 speed_label=_text(hud,"0 KM/H",Vector2(1075,93),Vector2(180,27),18,PALETTE["mint"],true)
 # Real entire-course minimap, individually colored live markers.
 _glow_panel(hud,Vector2(1001,151),Vector2(265,270),Color("#a7cced"),Color("#142943ed"),23)
 _small_label(hud,"全賽道小地圖 / 8 位車手",Vector2(1020,165),229)
 race_minimap=LIVE_MAP.new()
 race_minimap.position=Vector2(1015,207)
 race_minimap.size=Vector2(237,202)
 race_minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(race_minimap)
 # A useful instrument that gives young players more speed feedback
 # than tiny HUD text, but leaves the actual road ahead unobstructed.
 telemetry=TELEMETRY.new()
 telemetry.position=Vector2(490,560)
 telemetry.size=Vector2(298,143)
 telemetry.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hud.add_child(telemetry)
 # Child-size control pads: steady left/right, easy drift and item targets.
 var steer_l=_button(hud,"◀",Vector2(20,548),Vector2(155,153),Color("#2e5e82e7"),58)
 var steer_r=_button(hud,"▶",Vector2(186,548),Vector2(155,153),Color("#2e5e82e7"),58)
 steer_l.button_down.connect(func():left_held=true)
 steer_l.button_up.connect(func():left_held=false)
 steer_r.button_down.connect(func():right_held=true)
 steer_r.button_up.connect(func():right_held=false)
 var drift_button=_button(hud,"↪\n甩尾",Vector2(950,551),Vector2(148,148),Color("#9664b1ec"),28)
 drift_button.button_down.connect(func():drift_held=true)
 drift_button.button_up.connect(func():drift_held=false)
 item_button=_button(hud,"✦\n道具",Vector2(1109,551),Vector2(149,148),Color("#b98b5aeb"),28)
 item_button.pressed.connect(func():item_used.emit())
 countdown_label=_text(hud,"",Vector2(430,167),Vector2(433,147),80,PALETTE["gold"],true)
 _panel(hud,Vector2(391,110),Vector2(503,36),Color("#122a47dc"),Color("#9ac6d680"),12)
 course_detail=_text(hud,"左、右轉向  ·  自動前進",Vector2(395,111),Vector2(495,33),17,Color("#f8f0e1"),true)

func configure_minimap(track:Node3D,map_index:int)->void:
 super.configure_minimap(track,map_index)
 if telemetry!=null:
  telemetry.configure(map_index)
 var descriptions=[
  "夢幻樂園：穿越摩天輪與糖果村莊",
  "風車草原：花海、農場與青綠山丘",
  "黃金沙漠：衝過遺跡、神殿和沙丘",
  "星環太空：穿梭發光行星與軌道站"
 ]
 if course_detail!=null:
  course_detail.text=descriptions[clampi(map_index,0,3)]
 if current_driver_icon!=null:
  current_driver_icon.setup_monster(chosen)

func update_hud(place:int,lap:int,speed:float,time:float,item:String)->void:
 super.update_hud(place,lap,speed,time,item)
 if telemetry!=null:
  telemetry.update_racing(speed,[0.32,0.48,0.63,0.82,1.0][pace_mode],lap,place,drift_held,item.find("衝刺")>=0,1.0/60.0)

func _make_result()->void:
 result=Control.new()
 result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(result)
 _panel(result,Vector2.ZERO,Vector2(1280,720),Color("#071327d4"))
 _glow_panel(result,Vector2(301,66),Vector2(678,592),PALETTE["gold"],Color("#1c3353fa"),30)
 _text(result,"★  MONSTER CUP  ★",Vector2(343,91),Vector2(596,52),32,PALETTE["mint"],true)
 _text(result,"🏆  太棒了！完成比賽",Vector2(356,173),Vector2(575,61),37,PALETTE["gold"],true)
 finish_label=_text(result,"",Vector2(365,275),Vector2(547,82),48,PALETTE["paper"],true)
 finish_time=_text(result,"",Vector2(380,373),Vector2(520,61),28,PALETTE["mint"],true)
 var again=_button(result,"↻  再玩一次",Vector2(365,478),Vector2(265,100),Color("#c97497"),28)
 again.pressed.connect(func():retry_race.emit())
 var garage=_button(result,"⌂  選擇新賽道",Vector2(652,478),Vector2(268,100),Color("#428f99"),26)
 garage.pressed.connect(func():return_to_menu.emit())

func _make_pause()->void:
 pause_page=Control.new()
 pause_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_page.mouse_filter=Control.MOUSE_FILTER_IGNORE
 main.add_child(pause_page)
 _panel(pause_page,Vector2.ZERO,Vector2(1280,720),Color("#0b1629ce"))
 _glow_panel(pause_page,Vector2(306,92),Vector2(669,550),PALETTE["mint"],Color("#1e3554fc"),27)
 _text(pause_page,"TAKE A BREAK  /  休息一下",Vector2(345,133),Vector2(585,52),31,PALETTE["gold"],true)
 _text(pause_page,"小怪獸正在等你回來！",Vector2(363,207),Vector2(547,49),27,PALETTE["paper"],true)
 var resume=_button(pause_page,"▶  繼續賽車",Vector2(358,303),Vector2(556,77),Color("#3b9d96"),27)
 resume.pressed.connect(func():resume_requested.emit())
 var restart=_button(pause_page,"↻  重新挑戰",Vector2(356,399),Vector2(260,78),Color("#ce7b8d"),25)
 restart.pressed.connect(func():retry_race.emit())
 var home=_button(pause_page,"⌂  換一張地圖",Vector2(642,399),Vector2(271,78),Color("#416f92"),25)
 home.pressed.connect(func():return_to_menu.emit())
 var settings_button=_button(pause_page,"⚙  速度、畫質與音量設定",Vector2(357,505),Vector2(555,73),Color("#395c7d"),24)
 settings_button.pressed.connect(func():_open_settings("pause"))
