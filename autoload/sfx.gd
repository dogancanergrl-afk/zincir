extends Node
# Projede tek bir ses dosyasi yok. Dalga bicimleri calisma aninda ham
# ornek olarak uretiliyor, perde kaydirmasi pitch_scale ile yapiliyor.
# Bu hem APK boyutunu kucuk tutuyor hem de tinilari kodla ayarlanabilir
# kiliyor.

const RATE := 22050
const BPM := 72.0
const EIGHTH := 60.0 / BPM / 2.0

# La minor: Am - F - C - G, her akor bir olcu
const PROG := [
	{"bass": 45, "notes": [57, 60, 64]},
	{"bass": 41, "notes": [53, 57, 60]},
	{"bass": 48, "notes": [60, 64, 67]},
	{"bass": 43, "notes": [55, 59, 62]},
]

var music_on := true
var sfx_on := true

var _square: AudioStreamWAV       # efektler
var _tone_short: AudioStreamWAV   # arpej
var _tone_long: AudioStreamWAV    # bas
var _pad: AudioStreamWAV          # altta duran ped

var _sfx_pool: Array[AudioStreamPlayer] = []
var _mus_pool: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var _mus_i := 0

var _t := 0.0
var _step := 0


func _ready() -> void:
	_square     = _wave("square",   440.0, 0.10, 2.0)
	_tone_short = _wave("triangle", 440.0, 0.45, 2.4)
	_tone_long  = _wave("triangle", 440.0, 0.95, 2.0)
	_pad        = _pad_wave(220.0, EIGHTH * 8.0)

	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_mus_pool.append(p)

	music_on = SaveData.music_on
	sfx_on = SaveData.sfx_on


# ------------------------------------------------------------ dalga uretimi

func _wave(kind: String, freq: float, dur: float, decay: float) -> AudioStreamWAV:
	var count := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(RATE)
		var phase: float = fmod(t * freq, 1.0)
		var s: float
		if kind == "square":
			s = 1.0 if phase < 0.5 else -1.0
		else:  # triangle
			s = 4.0 * abs(phase - 0.5) - 1.0
		var env: float = pow(1.0 - float(i) / float(count), decay)
		data.encode_s16(i * 2, int(clamp(s * env, -1.0, 1.0) * 30000.0))
	return _pack(data)


func _pad_wave(freq: float, dur: float) -> AudioStreamWAV:
	# Yavas acilip kapanan, ust harmonikleri kisilmis testere dalgasi.
	var count := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var attack := count * 0.22
	var release := count * 0.35
	for i in count:
		var t := float(i) / float(RATE)
		var s: float = fmod(t * freq, 1.0) * 2.0 - 1.0
		s = s * 0.55 + (4.0 * abs(fmod(t * freq, 1.0) - 0.5) - 1.0) * 0.45
		var env := 1.0
		if i < attack:
			env = float(i) / attack
		elif i > count - release:
			env = float(count - i) / release
		data.encode_s16(i * 2, int(clamp(s * env, -1.0, 1.0) * 9000.0))
	return _pack(data)


func _pack(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


# ------------------------------------------------------------ efektler

func blip(freq: float, db: float = -14.0) -> void:
	if not sfx_on:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	p.stream = _square
	p.pitch_scale = clamp(freq / 440.0, 0.1, 4.0)
	p.volume_db = db
	p.play()


func arp(freqs: Array, step := 0.055) -> void:
	for i in freqs.size():
		var f: float = freqs[i]
		get_tree().create_timer(step * i).timeout.connect(func(): blip(f, -13.0))


# ------------------------------------------------------------ muzik

func _process(delta: float) -> void:
	if not music_on:
		return
	_t += delta
	while _t >= EIGHTH:
		_t -= EIGHTH
		_play_step(_step)
		_step += 1


func _play_step(step: int) -> void:
	var chord: Dictionary = PROG[int(step / 8.0) % PROG.size()]
	var beat := step % 8
	var notes: Array = chord["notes"]

	if beat == 0 or beat == 4:
		_note(_tone_long, chord["bass"], -20.0)
	if beat == 0:
		_note(_pad, notes[0] - 12, -26.0, 220.0)
	_note(_tone_short, notes[step % notes.size()], -25.0)
	if beat == 6:
		_note(_tone_short, notes[2] + 12, -30.0)


func _note(stream: AudioStreamWAV, midi_note: int, db: float, base_freq := 440.0) -> void:
	var p: AudioStreamPlayer = _mus_pool[_mus_i]
	_mus_i = (_mus_i + 1) % _mus_pool.size()
	p.stream = stream
	p.pitch_scale = clamp(_freq(midi_note) / base_freq, 0.05, 6.0)
	p.volume_db = db
	p.play()


func _freq(m: int) -> float:
	return 440.0 * pow(2.0, (float(m) - 69.0) / 12.0)


# ------------------------------------------------------------ anahtarlar

func set_music(on: bool) -> void:
	music_on = on
	SaveData.music_on = on
	SaveData.write()
	if not on:
		for p in _mus_pool:
			p.stop()


func set_sfx(on: bool) -> void:
	sfx_on = on
	SaveData.sfx_on = on
	SaveData.write()


func duck(on: bool) -> void:
	# Reklam oynarken muzigi kis.
	for p in _mus_pool:
		p.stop()
	music_on = on and SaveData.music_on
