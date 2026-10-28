extends Control
## Dedicated vector-painted level art, not generic icon badges.
## Every poster contains a distinct painted skyline, track, landmark and
## foreground objects, at any Android resolution.
var course := 0
var accent := Color.WHITE

func setup(index:int)->void:
 course=clampi(index,0,3)
 accent=[Color("#ed91b1"),Color("#87e5a7"),Color("#f5bf88"),Color("#a4a2fa")][course]
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func _paint_rect(r:Rect2,c:Color)->void:
 draw_rect(r,c)

func _polygon(pts:Array[Vector2],color:Color)->void:
 draw_colored_polygon(PackedVector2Array(pts),color)

func _circle(p:Vector2,r:float,c:Color)->void:
 draw_circle(p,r,c)

func _line(a:Vector2,b:Vector2,c:Color,weight:float=2.0)->void:
 draw_line(a,b,c,weight,true)

func _draw()->void:
 var scaling=Vector2(maxf(1.0,size.x)/96.0,maxf(1.0,size.y)/78.0)
 draw_set_transform(Vector2.ZERO,0,scaling)
 var sky=[Color("#9ec5d1"),Color("#97c9d2"),Color("#d7a577"),Color("#141e47")][course]
 for y in range(78):
  var f=float(y)/78.0
  _paint_rect(Rect2(0,y,96,1),sky.lerp(Color("#d5e9d4") if course==1 else (Color("#c3aaac") if course==0 else (Color("#e7b287") if course==2 else Color("#4d4778"))),f*0.75))
 if course==0:
  _festival()
 elif course==1:
  _grassland()
 elif course==2:
  _desert()
 else:
  _space()
 # Glancing perspective asphalt. Strong contrasting curbs.
 _polygon([Vector2(28,77),Vector2(66,77),Vector2(59,46),Vector2(43,46)],Color("#d9e5dd") if course==3 else Color("#ede4d4"))
 _polygon([Vector2(32,77),Vector2(62,77),Vector2(56,46),Vector2(46,46)],Color("#3b445e") if course!=3 else Color("#283958"))
 _polygon([Vector2(45,77),Vector2(49,77),Vector2(51,46),Vector2(50,46)],Color("#fff1c6"))
 for n in range(4):
  var y=50+n*8
  var left=44-float(n)*2.8
  _line(Vector2(left,y),Vector2(left-1.9,y+3),accent,1.8)
  _line(Vector2(60.0-(left-44.0),y),Vector2(61.0-(left-44.0),y+3),accent,1.8)
 _paint_rect(Rect2(0,69,96,9),Color("#142a43a2"))
 _line(Vector2(4,72),Vector2(29,72),accent,2.0)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _festival()->void:
 _circle(Vector2(76,12),9,Color("#ffe6bb"))
 _polygon([Vector2(0,52),Vector2(12,31),Vector2(29,51)],Color("#88b8a5"))
 _polygon([Vector2(67,51),Vector2(82,24),Vector2(96,49)],Color("#78aa9e"))
 # Ferris wheel with gondolas, tent stripes and lit flags.
 draw_arc(Vector2(22,31),18,0,TAU,48,Color("#f8d9d9"),2.5,true)
 for i in range(10):
  var a=float(i)*TAU/10.0
  var q=Vector2(22,31)+Vector2(cos(a),sin(a))*18.0
  _line(Vector2(22,31),q,Color("#eef0dd"),0.8)
  _circle(q,2.7,[Color("#f8a2b5"),Color("#ffe4a0"),Color("#b7d9e1")][i%3])
 _line(Vector2(22,31),Vector2(15,54),Color("#655f81"),2)
 _line(Vector2(22,31),Vector2(29,54),Color("#655f81"),2)
 _polygon([Vector2(67,52),Vector2(81,18),Vector2(96,52)],Color("#ffbed0"))
 _polygon([Vector2(74,52),Vector2(81,18),Vector2(88,52)],Color("#ffe6ac"))
 _paint_rect(Rect2(67,52,29,7),Color("#a9677e"))
 _line(Vector2(2,47),Vector2(63,42),Color("#ffe4bc"),1)
 for i in range(5):
  var x=5+i*12
  _polygon([Vector2(x,47),Vector2(x+5,47),Vector2(x+2.5,53)],Color("#ffacc4"))

func _grassland()->void:
 _circle(Vector2(76,16),10,Color("#fff5c9"))
 _polygon([Vector2(0,55),Vector2(21,24),Vector2(44,54)],Color("#62b6a1"))
 _polygon([Vector2(39,54),Vector2(67,25),Vector2(96,53)],Color("#8ed8ab"))
 for x in [9,82,92]:
  _line(Vector2(x,50),Vector2(x,37),Color("#786e58"),3)
  for off in [-7,0,8]:
   _circle(Vector2(x+off,33),8,Color("#3f9d7d"))
 _polygon([Vector2(22,51),Vector2(33,27),Vector2(45,51)],Color("#e9e3d3"))
 _polygon([Vector2(18,32),Vector2(33,19),Vector2(48,32)],Color("#c46e74"))
 _paint_rect(Rect2(27,37,11,14),Color("#8a8476"))
 _line(Vector2(70,48),Vector2(70,12),Color("#fff0d2"),5)
 _circle(Vector2(70,23),3,Color("#f8f0d3"))
 for i in range(4):
  var a=TAU*float(i)/4.0
  _line(Vector2(70,23),Vector2(70,23)+Vector2(cos(a),sin(a))*13,Color("#fff9dc"),3)

func _desert()->void:
 _circle(Vector2(78,17),12,Color("#fff0bc"))
 _polygon([Vector2(0,55),Vector2(20,38),Vector2(47,55)],Color("#bd876b"))
 _polygon([Vector2(38,55),Vector2(70,31),Vector2(96,54)],Color("#dbaa78"))
 _polygon([Vector2(7,56),Vector2(28,19),Vector2(49,56)],Color("#e4b186"))
 _polygon([Vector2(15,56),Vector2(28,19),Vector2(30,56)],Color("#f4d19a"))
 _paint_rect(Rect2(59,35,28,21),Color("#ac7567"))
 _paint_rect(Rect2(61,30,24,5),Color("#f3c58e"))
 _paint_rect(Rect2(65,25,16,5),Color("#c8936c"))
 _paint_rect(Rect2(70,19,6,6),Color("#f5cfaa"))
 for x in [4,90]:
  _line(Vector2(x,55),Vector2(x,34),Color("#4b786e"),4)
  _line(Vector2(x,42),Vector2(x+8,42),Color("#4b786e"),3)
  _line(Vector2(x+8,42),Vector2(x+8,35),Color("#4b786e"),3)

func _space()->void:
 for i in range(13):
  var x=float((i*47+13)%96)
  var y=float((i*19+4)%43)
  _circle(Vector2(x,y),0.8 if i%3 else 1.4,Color("#eff9ff"))
 _circle(Vector2(76,23),14,Color("#8e83d7"))
 _circle(Vector2(71,18),7,Color("#afb9ef"))
 draw_arc(Vector2(76,23),20,-0.7,2.55,34,Color("#e3caf6"),3.0,true)
 for x in [8,19,31]:
  _polygon([Vector2(x,55),Vector2(x+5,26),Vector2(x+11,55)],Color("#566ea7"))
  _line(Vector2(x+5,27),Vector2(x+5,53),Color("#8bf1fc"),1.6)
 _polygon([Vector2(60,54),Vector2(71,38),Vector2(90,54)],Color("#334870"))
 _line(Vector2(64,53),Vector2(76,39),Color("#b5e9fb"),2.3)
