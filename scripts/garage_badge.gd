extends Control
## Vector UI illustrations for every monster and track. They are resolution-
## independent, deterministic and do not require bundled fonts or image files.
var index := 0
var is_course := false
const COLORS = [
 "#ff795c","#70dfe2","#ac8cf5","#8265c9","#74d698","#88bdee",
 "#f9d35b","#ff8ebf","#f5bf8b","#78c97b","#dbe5fa","#a1d8f2"
]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func setup_monster(value:int)->void:
 index=clampi(value,0,11)
 is_course=false
 queue_redraw()

func setup_course(value:int)->void:
 index=clampi(value,0,3)
 is_course=true
 queue_redraw()

func _draw()->void:
 if is_course:
  _draw_course()
 else:
  _draw_monster()

func _round_rect(rect:Rect2,color:Color,radius:float=8.0)->void:
 draw_circle(rect.position+Vector2(radius,radius),radius,color)
 draw_circle(rect.position+Vector2(rect.size.x-radius,radius),radius,color)
 draw_circle(rect.position+Vector2(radius,rect.size.y-radius),radius,color)
 draw_circle(rect.position+Vector2(rect.size.x-radius,rect.size.y-radius),radius,color)
 draw_rect(Rect2(rect.position+Vector2(radius,0),Vector2(rect.size.x-radius*2.0,rect.size.y)),color)
 draw_rect(Rect2(rect.position+Vector2(0,radius),Vector2(rect.size.x,rect.size.y-radius*2.0)),color)

func _ellipse(center:Vector2,radius:Vector2,color:Color)->void:
 var vertices = PackedVector2Array()
 for i in range(25):
  var a = TAU * float(i) / 24.0
  vertices.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
 draw_colored_polygon(vertices, color)

func _triangle(a:Vector2,b:Vector2,c:Vector2,col:Color)->void:
 draw_colored_polygon(PackedVector2Array([a,b,c]),col)

func _draw_monster()->void:
 var w=size.x
 var h=size.y
 var s=minf(w,h)/62.0
 draw_set_transform(Vector2((w-62.0*s)*0.5,(h-62.0*s)*0.5),0,Vector2(s,s))
 var primary=Color(COLORS[index])
 _round_rect(Rect2(1,1,60,60),primary.darkened(0.53),14)
 _ellipse(Vector2(31,36),Vector2(22,21),primary)
 # Signature silhouette readable at 45 pixels.
 match index:
  0,2,4,9,11:
   for side in [-1.0,1.0]:
    var c=Color("#fff0b9") if index!=11 else Color("#d5eeff")
    _triangle(Vector2(31+side*13,20),Vector2(31+side*22,3),Vector2(31+side*5,22),c)
  1,7:
   for side in [-1.0,1.0]:
    _ellipse(Vector2(31+side*20,20),Vector2(7,11),primary.lightened(0.25))
   _ellipse(Vector2(32,8),Vector2(11,5),primary.lightened(0.35))
  3,6:
   _triangle(Vector2(18,21),Vector2(0,10),Vector2(9,41),primary.lightened(0.18))
   _triangle(Vector2(44,21),Vector2(62,10),Vector2(53,41),primary.lightened(0.18))
  5:
   _round_rect(Rect2(14,9,34,14),Color("#c5ebff"),5)
   draw_circle(Vector2(31,8),5,Color("#ffcf83"))
  8:
   _triangle(Vector2(12,24),Vector2(13,2),Vector2(31,19),Color("#ffe3ca"))
   _triangle(Vector2(50,24),Vector2(49,2),Vector2(31,19),Color("#ffe3ca"))
  10:
   for j in range(4):
    draw_circle(Vector2(18+j*9,52+(j%2)*2),7,Color("#e7efff"))
 # Accent tuft, crest, translucent armor.
 if index==2:
  _ellipse(Vector2(31,34),Vector2(12,12),Color.WHITE)
  draw_circle(Vector2(31,36),5,Color("#333356"))
 elif index==5:
  _round_rect(Rect2(17,27,28,14),Color("#35436d"),5)
  for a in [-1,1]:
   _ellipse(Vector2(31+a*7,33),Vector2(4,5),Color("#9bf5fb"))
 else:
  for side in [-1.0,1.0]:
   _ellipse(Vector2(31+side*9,34),Vector2(7,9),Color.WHITE)
   _ellipse(Vector2(31+side*8,36),Vector2(3.6,5.5),Color("#293452"))
   draw_circle(Vector2(31+side*7,33),1.6,Color.WHITE)
 draw_arc(Vector2(31,43),6,0.1,PI-0.1,15,Color("#713b62"),2.5,true)
 for side in [-1.0,1.0]:
  _ellipse(Vector2(31+side*16,43),Vector2(4,3),Color("#ffaab7"))
 _ellipse(Vector2(22,17),Vector2(7,3),Color(1,1,1,0.26))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _draw_course()->void:
 var w=size.x
 var h=size.y
 var s=minf(w,h)/62.0
 draw_set_transform(Vector2((w-62.0*s)*0.5,(h-62.0*s)*0.5),0,Vector2(s,s))
 var sky=[Color("#eeb3ce"),Color("#a8e6d8"),Color("#ffd5ad"),Color("#354c83")][index]
 _round_rect(Rect2(0,0,62,62),sky,14)
 match index:
  0:
   _ellipse(Vector2(32,53),Vector2(30,21),Color("#8bd7a2"))
   _round_rect(Rect2(24,16,17,32),Color("#ffbdd5"),5)
   _triangle(Vector2(20,18),Vector2(32,0),Vector2(46,18),Color("#fff0ac"))
   _round_rect(Rect2(4,39,55,5),Color("#fef1d1"),2)
  1:
   _ellipse(Vector2(27,58),Vector2(40,24),Color("#7ac99c"))
   _ellipse(Vector2(52,49),Vector2(21,19),Color("#5eae86"))
   _round_rect(Rect2(12,20,5,30),Color("#ffead7"),2)
   _triangle(Vector2(14,21),Vector2(3,13),Vector2(4,30),Color.WHITE)
   _triangle(Vector2(14,21),Vector2(24,11),Vector2(24,31),Color.WHITE)
  2:
   _ellipse(Vector2(23,48),Vector2(36,15),Color("#ebaa72"))
   _ellipse(Vector2(50,53),Vector2(38,19),Color("#f4c183"))
   _triangle(Vector2(20,39),Vector2(36,7),Vector2(55,39),Color("#d98f61"))
   _triangle(Vector2(17,43),Vector2(34,12),Vector2(37,43),Color("#ffe1ac"))
  3:
   for p in [Vector2(10,9),Vector2(47,16),Vector2(7,44),Vector2(52,47),Vector2(29,5)]:
    draw_circle(p,1.4,Color("#fff7d8"))
   draw_circle(Vector2(35,30),19,Color("#a8a8ee"))
   draw_arc(Vector2(34,30),26,-0.7,2.9,30,Color("#d9eaff"),4,true)
   draw_circle(Vector2(27,25),5,Color("#c4bdff"))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
