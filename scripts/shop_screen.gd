class_name ShopScreen
extends Control

var main
var _coins: Label
var _list: VBoxContainer


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

	# baslik
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)

	var h := UiKit.label("MAĞAZA", 30, Skins.col("acc"))
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(h)

	var back := UiKit.button("‹ GERİ", 16)
	back.custom_minimum_size = Vector2(150, 62)
	back.pressed.connect(func(): main.go("title"))
	bar.add_child(back)

	_coins = UiKit.label("0 JETON", 24, Skins.col("acc"))
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_coins)

	# reklam karti
	var ad_card := _card()
	root.add_child(ad_card.outer)
	ad_card.inner.add_child(UiKit.label("JETON KAZAN", 20, Skins.col("acc")))
	ad_card.inner.add_child(UiKit.body(
		"Kısa bir reklam izle, %d jeton al. Oynayarak da kazanıyorsun — her %d puan 1 jeton."
		% [Cfg.AD_REWARD, Cfg.COIN_PER_SCORE], 15))
	var ad_btn := UiKit.accent_button("REKLAM İZLE  ·  +%d JETON" % Cfg.AD_REWARD, 18)
	ad_btn.pressed.connect(_watch_ad)
	ad_card.inner.add_child(ad_btn)

	# tema listesi
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)

	_render()


func _card() -> Dictionary:
	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", UiKit.box(Skins.col("deep"), 3, Skins.col("line")))
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	outer.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	return {"outer": outer, "inner": v}


func on_enter() -> void:
	if _coins:
		_coins.text = "%d JETON" % SaveData.coins
	_render()


func _render() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()

	for k in Skins.ORDER:
		var def: Dictionary = Skins.DEFS[k]
		var has: bool = SaveData.owned.has(k)
		var active: bool = (k == Skins.key)

		var outer := PanelContainer.new()
		outer.add_theme_stylebox_override("panel",
			UiKit.box(Skins.col("deep"), 3, Skins.col("acc2") if active else Skins.col("line")))
		_list.add_child(outer)

		var m := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + side, 16)
		outer.add_child(m)

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		m.add_child(v)

		var title: String = def["name"] + ("  ·  SEÇİLİ" if active else "")
		v.add_child(UiKit.label(title, 20, Skins.col("acc2") if active else Skins.col("acc")))
		v.add_child(UiKit.body(def["desc"], 15))

		# renk seridi — temayi satin almadan once nasil gorunecegini gosteriyor
		var strip := HBoxContainer.new()
		strip.add_theme_constant_override("separation", 4)
		strip.custom_minimum_size = Vector2(0, 40)
		v.add_child(strip)
		var pal: Array = def["palette"]
		for i in 8:
			var sw := Panel.new()
			sw.add_theme_stylebox_override("panel", UiKit.box(Color(pal[i]), 2, Skins.col("edge")))
			sw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			strip.add_child(sw)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		v.add_child(row)

		var price_txt := "sahipsin" if has else "%d JETON" % int(def["price"])
		var price := UiKit.body(price_txt, 16)
		if not has:
			price.add_theme_color_override("font_color", Skins.col("acc"))
		price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(price)

		var btn: Button
		if active:
			btn = UiKit.button("KULLANILIYOR", 14)
			btn.disabled = true
		elif has:
			btn = UiKit.button("SEÇ", 16)
			btn.pressed.connect(func(): Skins.apply(k))
		elif SaveData.coins >= int(def["price"]):
			btn = UiKit.accent_button("SATIN AL", 16)
			btn.pressed.connect(func(): _buy(k, int(def["price"])))
		else:
			btn = UiKit.button("JETON YETMİYOR", 13)
			btn.disabled = true
		btn.custom_minimum_size = Vector2(230, 66)
		row.add_child(btn)


func _buy(k: String, price: int) -> void:
	if not SaveData.spend(price):
		return
	SaveData.unlock(k)
	Sfx.arp([440.0, 554.0, 659.0], 0.07)
	Skins.apply(k)   # tema degisimi ekranlari yeniden kuruyor


func _watch_ad() -> void:
	main.play_ad(func():
		SaveData.add_coins(Cfg.AD_REWARD)
		Sfx.arp([523.0, 659.0, 784.0], 0.07)
		on_enter())
