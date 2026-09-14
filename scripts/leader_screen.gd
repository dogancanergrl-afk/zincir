class_name LeaderScreen
extends Control
# TASLAK. Gercek veri Play Games Services'ten gelecek:
# godot-play-game-services eklentisi tek bir tablo kimliginden
# gunluk / haftalik / tum zamanlar ve herkes / arkadaslar gorunumlerini
# veriyor. Buradaki _fake_rows() yerine load_player_centered_scores()
# cagrisi gelecek.

var main
var _span := "daily"
var _scope := "public"
var _rows: VBoxContainer

const NAMES := ["Kerem", "Zeynep", "Mert", "Elif", "Burak", "Deniz", "Ayla",
				"Onur", "Sinem", "Emre", "Pelin", "Kaan", "Derya", "Tolga"]


func build() -> void:
	for c in get_children():
		c.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)
	var h := UiKit.label("SIRALAMA", 28, Skins.col("acc"))
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(h)
	var back := UiKit.button("‹ GERİ", 16)
	back.custom_minimum_size = Vector2(150, 62)
	back.pressed.connect(func(): main.go("title"))
	bar.add_child(back)

	root.add_child(_tabs([["daily", "GÜNLÜK"], ["weekly", "HAFTALIK"], ["all", "TÜM ZAMANLAR"]],
		func(k): _span = k, func(): return _span))
	root.add_child(_tabs([["public", "HERKES"], ["friends", "ARKADAŞLAR"]],
		func(k): _scope = k, func(): return _scope))

	var note := UiKit.body("örnek veri — gerçek liste Play Games'ten gelecek", 13)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.modulate.a = 0.7
	root.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(_rows)

	_render()


func _tabs(items: Array, setter: Callable, getter: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for it in items:
		var b := UiKit.button(it[1], 14)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 62)
		if getter.call() == it[0]:
			b.add_theme_color_override("font_color", Skins.col("acc"))
			b.add_theme_stylebox_override("normal", UiKit.box(Skins.col("line"), 3, Skins.col("acc")))
		b.pressed.connect(func():
			setter.call(it[0])
			build())
		row.add_child(b)
	return row


func on_enter() -> void:
	_render()


func _render() -> void:
	if _rows == null:
		return
	for c in _rows.get_children():
		c.queue_free()

	for i in _fake_rows().size():
		var r: Dictionary = _fake_rows()[i]
		var mine: bool = r.get("me", false)

		var outer := PanelContainer.new()
		outer.add_theme_stylebox_override("panel",
			UiKit.box(Skins.col("deep"), 3, Skins.col("acc") if mine else Skins.col("line")))
		_rows.add_child(outer)

		var m := MarginContainer.new()
		for side in ["left", "right"]:
			m.add_theme_constant_override("margin_" + side, 14)
		m.add_theme_constant_override("margin_top", 12)
		m.add_theme_constant_override("margin_bottom", 12)
		outer.add_child(m)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		m.add_child(row)

		var rank := UiKit.label(str(i + 1), 20, Skins.col("acc") if i == 0 else Skins.col("muted"))
		rank.custom_minimum_size = Vector2(46, 0)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(rank)

		var who := UiKit.body(str(r["name"]), 17)
		who.add_theme_color_override("font_color", Skins.col("cream"))
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(who)

		var pts := UiKit.label(_thousands(int(r["pts"])), 18, Skins.col("acc"))
		row.add_child(pts)


func _fake_rows() -> Array:
	var n: int = 6 if _scope == "friends" else 12
	var mul: float = 9.0 if _span == "all" else (4.0 if _span == "weekly" else 1.0)
	var r := RandomNumberGenerator.new()
	r.seed = _span.length() * 31 + _scope.length() * 7 + 99
	var out := []
	for i in n:
		out.append({
			"name": NAMES[r.randi() % NAMES.size()],
			"pts": int((26000.0 - i * 1800.0 - r.randf() * 900.0) * mul),
		})
	out.sort_custom(func(a, b): return int(a["pts"]) > int(b["pts"]))
	var mine: int = mini(n - 1, 3 + (r.randi() % 3))
	out[mine] = {"name": "sen", "pts": out[mine]["pts"], "me": true}
	return out


func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return out
