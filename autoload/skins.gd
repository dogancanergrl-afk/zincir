extends Node
# Tum gorsel kimlik burada. Bir temayi degistirmek sadece renkleri degil
# yazi tipini, kose yuvarlakligini, golge tipini ve tarama cizgilerini de
# degistiriyor — yoksa dort tane ayni oyunun renk varyasyonu olurdu.

signal changed

const DEFS := {
	"basic": {
		"name": "BASIC", "price": 200,
		"desc": "Süssüz ve okunaklı. Dikkati tamamen tahtaya bırakır.",
		"void": "14161c", "deep": "1d2029", "panel": "22262f", "slot": "2b303b",
		"edge": "0b0d11", "line": "3a4152", "acc": "e7ecf5", "acc2": "8b93a5",
		"cream": "e7ecf5", "muted": "7d8598",
		"glow": "00000000", "sky": "1b1f28",
		"radius": 4, "scan": 0.0, "pixel": false, "hard": false,
		"palette": ["5b7fa8","5fa3a8","5fa87f","8aa85f","a8985f","a8795f",
					"a85f5f","a85f86","8a5fa8","6b5fa8","5fa8a0","d7dce5"],
	},
	"retro": {
		"name": "RETRO", "price": 0,
		"desc": "1983 atari salonu. Piksel tipografi, sert gölgeler, CRT tarama çizgileri.",
		"void": "0d0720", "deep": "1a0f38", "panel": "241552", "slot": "2e1c63",
		"edge": "0a0518", "line": "5b3fa8", "acc": "f2c94c", "acc2": "ef5fa7",
		"cream": "e8e2ff", "muted": "8d7bc4",
		"glow": "ef5fa733", "sky": "2b1a5e",
		"radius": 0, "scan": 0.26, "pixel": true, "hard": true,
		"palette": ["3b7dd8","4fc1e0","3fd07a","b8e04a","f2c94c","f59a3e",
					"ef5f5f","ef5fa7","b56ee8","7a6ef0","4de0c3","e8e2ff"],
	},
	"modern": {
		"name": "MODERN", "price": 500,
		"desc": "Yumuşak köşeler, dağınık gölgeler, sakin pastel palet. Bugünün mobil oyun dili.",
		"void": "0f1115", "deep": "171a21", "panel": "1d212a", "slot": "252a35",
		"edge": "0a0c0f", "line": "2f3542", "acc": "7c9cf5", "acc2": "ee72a8",
		"cream": "eef1f6", "muted": "8992a3",
		"glow": "7c9cf522", "sky": "1a1f2b",
		"radius": 14, "scan": 0.0, "pixel": false, "hard": false,
		"palette": ["7c9cf5","5fc6ec","4fd6ae","93dc6b","f5ce5e","f7a45e",
					"f5766f","ee72a8","b07cf0","8a7cf0","5fdcce","ffffff"],
	},
	"cyberpunk": {
		"name": "CYBERPUNK", "price": 800,
		"desc": "Neredeyse siyah zemin, neon camgöbeği ve macenta. En yüksek kontrast.",
		"void": "05060a", "deep": "0a0d16", "panel": "0d1220", "slot": "131a2c",
		"edge": "000000", "line": "1f3a5c", "acc": "00ffd5", "acc2": "ff00a0",
		"cream": "d9f7ff", "muted": "5f7f9c",
		"glow": "ff00a033", "sky": "0a1c2e",
		"radius": 0, "scan": 0.34, "pixel": true, "hard": true,
		"palette": ["00d4ff","00ffd5","00ff85","aaff00","ffe600","ff9d00",
					"ff2d55","ff00a0","c400ff","6a00ff","00ffc8","ffffff"],
	},
}

const ORDER := ["retro", "basic", "modern", "cyberpunk"]
const FREE := "retro"

var key := "retro"

var _pixel_font: FontVariation
var _body_font: FontVariation


func _ready() -> void:
	# DIKKAT: variation_opentype anahtari metin degil TAMSAYI etiket olmali.
	# {"wght": 600} yazarsan sessizce yok sayiliyor ve font varsayilan
	# ornegine dusuyor — Outfit'te bu 100, yani Thin. Yazilar incecik cikar.
	var tag := TextServerManager.get_primary_interface().name_to_tag("weight")

	_pixel_font = FontVariation.new()
	_pixel_font.base_font = load("res://fonts/PixelifySans.ttf")
	_pixel_font.variation_opentype = {tag: 700}

	_body_font = FontVariation.new()
	_body_font.base_font = load("res://fonts/Outfit.ttf")
	_body_font.variation_opentype = {tag: 500}


func cur() -> Dictionary:
	return DEFS[key]


func col(name: String) -> Color:
	return Color(cur()[name])


func palette() -> Array:
	return cur()["palette"]


func tint(value: int) -> Color:
	var pal: Array = palette()
	var n := int(log(value) / log(2.0)) - 1
	return Color(pal[n % pal.size()])


func radius() -> int:
	return cur()["radius"]


func scan() -> float:
	return cur()["scan"]


func is_pixel() -> bool:
	return cur()["pixel"]


func has_hard_shadow() -> bool:
	return cur()["hard"]


func ui_font() -> Font:
	return _pixel_font if is_pixel() else _body_font


func body_font() -> Font:
	return _body_font


func apply(k: String) -> void:
	if not DEFS.has(k) or k == key:
		return
	key = k
	SaveData.theme = k
	SaveData.write()
	changed.emit()
