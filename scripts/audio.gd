extends Node
## Original, fully offline synthesised chiptune music and arcade sound effects.
## Preferences persist across launches and audio never relies on licensed files.
const RATE = 22050
const BPM = 132.0
const CONFIG_PATH = "user://monster_kart_audio.cfg"
var music_level := 0.60
var sfx_level := 0.75
var race_active := false
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var cues: Dictionary = {}

func _ready() -> void:
 _load_preferences()
 music_player = AudioStreamPlayer.new()
 music_player.name = "OriginalArcadeMusic"
 add_child(music_player)
 music_player.stream = _build_song()
 for i in range(4):
  var p = AudioStreamPlayer.new()
  p.name = "ArcadeSFX%d" % i
  add_child(p)
  sfx_players.append(p)
 cues["select"] = _build_cue(620.0, 0.10, 0.28, 1)
 cues["countdown"] = _build_cue(430.0, 0.16, 0.28, 1)
 cues["go"] = _build_cue(790.0, 0.37, 0.40, 2)
 cues["pickup"] = _build_cue(880.0, 0.24, 0.38, 2)
 cues["boost"] = _build_cue(490.0, 0.29, 0.35, 3)
 cues["item"] = _build_cue(680.0, 0.18, 0.35, 2)
 cues["hit"] = _build_cue(180.0, 0.28, 0.42, 0)
 cues["finish"] = _build_cue(740.0, 0.62, 0.38, 2)
 _apply_levels()
 music_player.play()

func _load_preferences() -> void:
 var cfg = ConfigFile.new()
 if cfg.load(CONFIG_PATH) == OK:
  music_level = clampf(float(cfg.get_value("audio", "music", 0.60)), 0.0, 1.0)
  sfx_level = clampf(float(cfg.get_value("audio", "effects", 0.75)), 0.0, 1.0)

func _save_preferences() -> void:
 var cfg = ConfigFile.new()
 cfg.set_value("audio", "music", music_level)
 cfg.set_value("audio", "effects", sfx_level)
 var err = cfg.save(CONFIG_PATH)
 if err != OK:
  push_warning("Could not save audio settings: %d" % err)

func set_music_level(value: float) -> void:
 music_level = clampf(value, 0.0, 1.0)
 _apply_levels()
 _save_preferences()

func set_sfx_level(value: float) -> void:
 sfx_level = clampf(value, 0.0, 1.0)
 _apply_levels()
 _save_preferences()

func set_race_active(value: bool) -> void:
 race_active = value
 _apply_levels()

func _apply_levels() -> void:
 if music_player:
  var adjusted = music_level * (1.0 if race_active else 0.74)
  music_player.volume_db = -80.0 if adjusted < 0.001 else linear_to_db(adjusted)
  music_player.pitch_scale = 1.075 if race_active else 1.0
 for player in sfx_players:
  player.volume_db = -80.0 if sfx_level < 0.001 else linear_to_db(sfx_level)

func play_cue(key: String) -> void:
 if sfx_level < 0.001 or not cues.has(key) or sfx_players.is_empty():
  return
 var player = sfx_players[sfx_cursor % sfx_players.size()]
 sfx_cursor += 1
 player.stop()
 player.stream = cues[key]
 player.play()

func _wav(bytes: PackedByteArray, frames: int, looping: bool) -> AudioStreamWAV:
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = RATE
 stream.stereo = false
 stream.data = bytes
 if looping:
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin = 0
  stream.loop_end = frames
 return stream

func _write_sample(bytes: PackedByteArray, index: int, value: float) -> void:
 var sample = int(clampf(value, -0.98, 0.98) * 32767.0)
 if sample < 0:
  sample += 65536
 bytes[index * 2] = sample & 255
 bytes[index * 2 + 1] = (sample >> 8) & 255

func _hz(note: int) -> float:
 return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

func _build_song() -> AudioStreamWAV:
 # Four original bars: melody, arpeggio, warm bass, kick and glittery hi-hat.
 var seconds_per_beat = 60.0 / BPM
 var frames = int(round(16.0 * seconds_per_beat * float(RATE)))
 var bytes = PackedByteArray()
 bytes.resize(frames * 2)
 var melody = [76, 79, 81, 79, 76, 74, 72, 74, 79, 81, 83, 79, 76, 74, 72, 71, 76, 79, 84, 83, 81, 79, 76, 74, 74, 76, 79, 76, 74, 71, 72, 74]
 var bass = [48, 45, 41, 43]
 var arp = [60, 64, 67, 57, 60, 64, 53, 57, 60, 55, 59, 62]
 for i in range(frames):
  var t = float(i) / float(RATE)
  var beat = t / seconds_per_beat
  var eighth = int(floor(beat * 2.0))
  var note_age = fposmod(beat * 2.0, 1.0)
  var note_envelope = pow(1.0 - note_age, 1.9)
  var lead_freq = _hz(melody[eighth % melody.size()])
  var lead = (sin(TAU * lead_freq * t) * 0.29 + sin(TAU * lead_freq * 2.0 * t) * 0.065) * note_envelope
  var bass_freq = _hz(bass[int(floor(beat / 4.0)) % bass.size()])
  var bass_envelope = 0.65 + 0.35 * (1.0 - fposmod(beat, 1.0))
  var low = sin(TAU * bass_freq * t) * 0.21 * bass_envelope
  var arp_freq = _hz(arp[int(floor(beat * 2.0)) % arp.size()])
  var bell = sin(TAU * arp_freq * t) * 0.082 * pow(1.0 - note_age, 2.8)
  var beat_age = fposmod(beat, 1.0) * seconds_per_beat
  var kick = sin(TAU * (65.0 * beat_age + 24.0 * (1.0 - exp(-26.0 * beat_age)))) * exp(-19.0 * beat_age) * 0.30
  var hat_age = fposmod(beat * 2.0, 1.0) * seconds_per_beat * 0.5
  var hiss = sin(TAU * 5431.0 * t) * sin(TAU * 7291.0 * t) * exp(-48.0 * hat_age) * 0.085
  var snare = 0.0
  if int(floor(beat)) % 4 == 1 or int(floor(beat)) % 4 == 3:
   snare = sin(TAU * 2167.0 * t) * sin(TAU * 3621.0 * t) * exp(-28.0 * beat_age) * 0.065
  var seam = minf(1.0, minf(float(i), float(frames - i - 1)) / (float(RATE) * 0.012))
  _write_sample(bytes, i, (lead + low + bell + kick + hiss + snare) * seam * 0.85)
 return _wav(bytes, frames, true)

func _build_cue(frequency: float, seconds: float, gain: float, shape: int) -> AudioStreamWAV:
 var frames = int(float(RATE) * seconds)
 var bytes = PackedByteArray()
 bytes.resize(frames * 2)
 for i in range(frames):
  var t = float(i) / float(RATE)
  var ratio = float(i) / float(frames)
  var sweep = frequency
  match shape:
   0:
    sweep *= 1.0 - ratio * 0.70
   2:
    sweep *= 1.0 + ratio * 0.65
   3:
    sweep *= 1.0 + sin(ratio * PI) * 0.8
  var envelope = pow(1.0 - ratio, 2.0)
  var value = (sin(TAU * sweep * t) + 0.20 * sin(TAU * sweep * 2.0 * t)) * gain * envelope
  _write_sample(bytes, i, value)
 return _wav(bytes, frames, false)
