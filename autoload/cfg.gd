extends Node
# Tarayicidaki denge studyosunda ayarladigimiz degerler. Yayin surumunde
# bu ekran kaldirilacak ve buradaki sayilar sabitlenecek; simdilik AYAR
# ekrani bunlari degistirebiliyor.

const COLS := 5
const ROWS := 7
const COIN_PER_SCORE := 400
const AD_REWARD := 50

var mode := "timer"          # endless | timer | moves

var timer_start := 60.0
var timer_gain := 0.8

var moves_start := 30
var moves_refund := 4

var combo_window := 2.6
var combo_min := 2
var combo_max := 9
var combo_decay := "reset"   # reset | step
var combo_per_tile := 0.18

var spawn_count := 4
var spawn_bias := 1.6
var cap_div := 16

const PRESETS := {
	"kolay": {
		"mode": "endless", "combo_window": 3.2, "combo_min": 2, "combo_max": 12,
		"combo_decay": "step", "spawn_count": 3, "spawn_bias": 2.2, "cap_div": 32,
	},
	"dengeli": {
		"mode": "timer", "timer_start": 60.0, "timer_gain": 0.8, "combo_window": 1.8,
		"combo_min": 3, "combo_max": 9, "combo_decay": "step",
		"spawn_count": 4, "spawn_bias": 1.6, "cap_div": 16,
	},
	"sert": {
		"mode": "moves", "moves_start": 25, "moves_refund": 4, "combo_window": 1.2,
		"combo_min": 3, "combo_max": 15, "combo_decay": "reset",
		"spawn_count": 5, "spawn_bias": 1.1, "cap_div": 8,
	},
}


func apply_preset(name: String) -> void:
	if not PRESETS.has(name):
		return
	for k in PRESETS[name]:
		set(k, PRESETS[name][k])


func mode_label() -> String:
	match mode:
		"timer": return "SÜRE"
		"moves": return "HAMLE"
		_: return "SONSUZ"
