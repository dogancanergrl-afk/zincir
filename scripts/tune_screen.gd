class_name TuneScreen
extends Control
# Yayin surumunde bu ekran kaldirilacak. Simdilik dengeyi telefonda
# oynarken ayarlayabilmek icin duruyor.

var main


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
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)
	var h := UiKit.label("AYAR", 30, Skins.col("acc"))
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(h)
	var back := UiKit.button("‹ GERİ", 16)
	back.custom_minimum_size = Vector2(150, 62)
	back.pressed.connect(func(): main.go("title"))
	bar.add_child(back)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	# ---- hazir ayarlar ----
	var p := _card(list, "HAZIR AYARLAR")
	p.add_child(UiKit.body("Önce bunları dene. Aradaki farkı hissettikten sonra tek tek kolları oynatmak daha anlamlı gelir.", 15))
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	p.add_child(prow)
	for name in ["kolay", "dengeli", "sert"]:
		var b := UiKit.button(name.to_upper(), 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			Cfg.apply_preset(name)
			build())
		prow.add_child(b)

	# ---- kombo ----
	var k := _card(list, "KOMBO")
	_slider(k, "pencere", Cfg.combo_window, 0.6, 4.0, 0.1,
		func(x): Cfg.combo_window = x, "%.1f sn",
		"Bir sonraki birleştirme için kalan süre. Kısalttıkça kombo gerçek bir beceri testi olur.")
	_slider(k, "artış için min zincir", float(Cfg.combo_min), 2, 5, 1,
		func(x): Cfg.combo_min = int(x), "%.0f",
		"2 ise her birleştirme komboyu artırır. Yükselttikçe sadece büyük zincirler sayılır.")
	_slider(k, "tavan çarpan", float(Cfg.combo_max), 3, 20, 1,
		func(x): Cfg.combo_max = int(x), "%.0f", "")

	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	k.add_child(UiKit.body("süre dolunca", 15))
	k.add_child(drow)
	for pair in [["reset", "SIFIRLA"], ["step", "BİR KADEME DÜŞ"]]:
		var b := UiKit.button(pair[1], 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if Cfg.combo_decay == pair[0]:
			b.add_theme_color_override("font_color", Skins.col("acc"))
		b.pressed.connect(func():
			Cfg.combo_decay = pair[0]
			build())
		drow.add_child(b)

	# ---- zorluk ----
	var z := _card(list, "ZORLUK / DOĞUM")
	_slider(z, "havuzdaki değer sayısı", float(Cfg.spawn_count), 2, 6, 1,
		func(x): Cfg.spawn_count = int(x), "%.0f",
		"Kaç farklı değer düşüyor. Arttıkça zincir kurmak zorlaşır.")
	_slider(z, "küçük değere yatkınlık", Cfg.spawn_bias, 1.0, 3.0, 0.1,
		func(x): Cfg.spawn_bias = x, "%.1f",
		"1.0 = tüm değerler eşit olasılıkla (sert). Büyüdükçe küçük sayılar ağır basar (kolay).")
	_slider(z, "taban yükselme hızı", float(Cfg.cap_div), 4, 64, 4,
		func(x): Cfg.cap_div = int(x), "%.0f",
		"En büyük karen bu sayıya bölünerek havuzun tavanı bulunur.")


func _card(parent: VBoxContainer, title: String) -> VBoxContainer:
	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", UiKit.box(Skins.col("deep"), 3, Skins.col("line")))
	parent.add_child(outer)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	outer.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	v.add_child(UiKit.label(title, 20, Skins.col("acc")))
	return v


func _slider(parent: VBoxContainer, title: String, value: float, lo: float, hi: float,
		step: float, setter: Callable, fmt: String, why: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var t := UiKit.body(title, 15)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)

	var val := UiKit.body(fmt % value, 15)
	val.add_theme_color_override("font_color", Skins.col("acc"))
	row.add_child(val)

	var s := UiKit.slider(value, lo, hi, step)
	s.value_changed.connect(func(x: float):
		setter.call(x)
		val.text = fmt % x)
	parent.add_child(s)

	if why != "":
		var w := UiKit.body(why, 13)
		w.modulate.a = 0.75
		parent.add_child(w)
