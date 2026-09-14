extends Node
# user:// altinda tek bir JSON. Android'de bu uygulamanin ozel alanina
# yaziliyor, kaldirilinca siliniyor. Bulut kaydi istersek Play Games
# Saved Games devreye girecek, o zaman buradaki sozlugu oldugu gibi
# yukleyip indirebiliriz.

const PATH := "user://zincir.save"

var coins := 0
var owned: Array = ["retro"]
var theme := "retro"
var best_scores: Dictionary = {}   # mod adi -> en yuksek skor
var music_on := true
var sfx_on := true


func _ready() -> void:
	read()
	# Test icin jeton. Cfg.DEV_MODE yayin surumunde false olacak.
	if Cfg.DEV_MODE and coins < Cfg.DEV_COINS:
		coins = Cfg.DEV_COINS
		write()


func read() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", 0))
	owned = parsed.get("owned", ["retro"])
	theme = parsed.get("theme", "retro")
	best_scores = parsed.get("best_scores", {})
	music_on = bool(parsed.get("music_on", true))
	sfx_on = bool(parsed.get("sfx_on", true))
	if not owned.has(Skins.FREE):
		owned.append(Skins.FREE)
	if not owned.has(theme):
		theme = Skins.FREE


func write() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"coins": coins,
		"owned": owned,
		"theme": theme,
		"best_scores": best_scores,
		"music_on": music_on,
		"sfx_on": sfx_on,
	}))
	f.close()


func add_coins(n: int) -> void:
	coins += n
	write()


func spend(n: int) -> bool:
	if coins < n:
		return false
	coins -= n
	write()
	return true


func unlock(k: String) -> void:
	if not owned.has(k):
		owned.append(k)
	write()


func record(mode: String, score: int) -> bool:
	# Yeni rekor mu? Oyun sonu ekraninda gostermek icin geri donuyor.
	var prev := int(best_scores.get(mode, 0))
	if score > prev:
		best_scores[mode] = score
		write()
		return true
	return false
