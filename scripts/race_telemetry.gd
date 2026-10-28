extends Control
## Custom glossy analog speed dial and progress strip for children. No images,
## no heavy shader passes, scalable 2D rendering on the Android race HUD.
var pace_factor := 0.48
var speed_value := 0.0
var drifting := false
var race_lap := 1
var rank := 1
var boost := false
var elapsed := 0.0
var accent := Color("#a7f1df")

func configure(theme:int)->void:
 accent=[Color("#f7b7c4"),Color("#9de6b7"),Color("#f6d1a0"),Color("#adb5fd")][clampi(theme,0,3)]
 queue_redraw()

func update_racing(speed_now:float,pace_now:float,lap_now:int,place:int,drift_now:bool,boost_now:bool,delta:float)->void:
 speed_value=speed_now
 pace_factor=pace_now
 race_lap=lap_now
 rank=place
 drifting=drift_now
 boost=boost_now
 elapsed+=delta
 queue_redraw()

func _draw()->void:
 var w=maxf(size.x,100.0)
 var h=maxf(size.y,80.0)
 var bounds=Rect2(Vector2.ZERO,Vector2(w,h))
 draw_rect(bounds,Color("#0f203bc8"))
 draw_rect(Rect2(4,4,w-8,h-8),Color("#253b59ab"),false,2.0)
 draw_rect(Rect2(12,7,w-24,3),accent)
 var center=Vector2(80,h*0.55)
 var radius=minf(h*0.36,57.0)
 draw_arc(center,radius,PI*0.80,PI*2.18,48,Color("#4d6281"),10.0,true)
 var velocity_ratio=clampf(speed_value/(53.0*pace_factor),0.0,1.0)
 var angle=PI*0.80+(PI*1.38)*velocity_ratio
 draw_arc(center,radius,PI*0.80,angle,48,Color("#fff0ba") if boost else accent,9.0,true)
 for i in range(9):
  var a=PI*0.80+float(i)*PI*1.38/8.0
  var inner=center+Vector2(cos(a),sin(a))*(radius-15.0)
  var outer=center+Vector2(cos(a),sin(a))*(radius-8.0)
  draw_line(inner,outer,Color("#c6d4dd"),1.7,true)
 var tip=center+Vector2(cos(angle),sin(angle))*(radius-17.0)
 draw_line(center,tip,Color("#fff9db"),3.2,true)
 draw_circle(center,6.0,Color("#f7f4dc"))
 draw_circle(center,3.0,Color("#506987"))
 var font=ThemeDB.fallback_font
 draw_string(font,Vector2(154,37),"SPEED",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#b4cce0"))
 draw_string(font,Vector2(145,79),str(int(round(speed_value*3.0))),HORIZONTAL_ALIGNMENT_LEFT,-1,35,Color("#fff7de"))
 draw_string(font,Vector2(155,97),"KM/H",HORIZONTAL_ALIGNMENT_LEFT,-1,14,accent)
 var status="BOOST!" if boost else ("DRIFT!" if drifting else "AUTO DRIVE")
 draw_string(font,Vector2(126,h-14),status,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffdfa8") if boost else Color("#e1f3f6"))
