class_name TitleScreen
extends Control

var main
var _coins: Label
var _code_input: LineEdit


func build() -> void:
	for c in get_children():
		c.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	# ---- logo ----
	var hero := VBoxContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 14)
	v.add_child(hero)

	var logo := UiKit.label("ZİNCİR", 120, Skins.col("acc"))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Koyu kontur sart: altindaki renkli golge olmadan harflerin ic
	# bosluklarini dolduruyor ve Z'yi B, C'yi Q gibi okutuyor.
	logo.add_theme_color_override("font_outline_color", Skins.col("edge"))
	logo.add_theme_constant_override("outline_size", 10)
	logo.add_theme_color_override("font_shadow_color", Skins.col("acc2"))
	logo.add_theme_constant_override("shadow_offset_x", 9)
	logo.add_theme_constant_override("shadow_offset_y", 9)
	logo.add_theme_constant_override("shadow_outline_size", 10)
	hero.add_child(logo)

	var sub := UiKit.label("P U Z Z L E", 28, Skins.col("acc2"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Skins.col("edge"))
	sub.add_theme_constant_override("outline_size", 6)
	sub.add_theme_constant_override("shadow_offset_x", 0)
	sub.add_theme_constant_override("shadow_offset_y", 0)
	hero.add_child(sub)

	var tag := UiKit.body("sınırsız eğlence", 20)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.add_child(tag)

	# ---- jeton ----
	_coins = UiKit.label("0", 30, Skins.col("acc"))
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_coins)

	# ---- menu ----
	var play := UiKit.accent_button("OYNA", 30)
	play.pressed.connect(func(): main.screens["game"].start_new(); main.go("game"))
	v.add_child(play)

	var shop := UiKit.button("MAĞAZA", 22)
	shop.pressed.connect(func(): main.go("shop"))
	v.add_child(shop)

	var board := UiKit.button("SIRALAMA", 22)
	board.pressed.connect(func(): main.go("board"))
	v.add_child(board)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)

	var mode := UiKit.button("MOD", 20)
	mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode.pressed.connect(func(): main.go("mode"))
	row.add_child(mode)

	var tune := UiKit.button("AYAR", 20)
	tune.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tune.pressed.connect(func(): main.go("tune"))
	row.add_child(tune)

	# ---- meydan okuma ----
	v.add_child(UiKit.spacer(6))

	var daily := UiKit.button("GÜNÜN TAHTASI", 18)
	daily.pressed.connect(func():
		main.screens["game"].start_seeded(GameScreen.daily_seed())
		main.go("game"))
	v.add_child(daily)

	var crow := VBoxContainer.new()
	crow.add_theme_constant_override("separation", 8)
	v.add_child(crow)

	_code_input = LineEdit.new()
	_code_input.placeholder_text = "KOD GİR"
	_code_input.max_length = 9
	_code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_input.custom_minimum_size = Vector2(0, 76)
	_code_input.add_theme_font_override("font", Skins.ui_font())
	_code_input.add_theme_font_size_override("font_size", 22)
	_code_input.add_theme_color_override("font_color", Skins.col("acc"))
	_code_input.add_theme_color_override("font_placeholder_color", Skins.col("muted"))
	_code_input.add_theme_stylebox_override("normal", UiKit.box(Skins.col("edge"), 3, Skins.col("line")))
	_code_input.add_theme_stylebox_override("focus", UiKit.box(Skins.col("edge"), 3, Skins.col("acc")))
	crow.add_child(_code_input)

	var go_btn := UiKit.button("KODLA OYNA", 18)
	go_btn.pressed.connect(_on_code)
	crow.add_child(go_btn)

	# ---- ses anahtarlari ----
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 10)
	v.add_child(trow)

	var mus := UiKit.button("MÜZİK: " + ("ON" if Sfx.music_on else "OFF"), 16)
	mus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mus.pressed.connect(func():
		Sfx.set_music(not Sfx.music_on)
		mus.text = "MÜZİK: " + ("ON" if Sfx.music_on else "OFF"))
	trow.add_child(mus)

	var sfx := UiKit.button("SES: " + ("ON" if Sfx.sfx_on else "OFF"), 16)
	sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx.pressed.connect(func():
		Sfx.set_sfx(not Sfx.sfx_on)
		sfx.text = "SES: " + ("ON" if Sfx.sfx_on else "OFF"))
	trow.add_child(sfx)


func on_enter() -> void:
	if _coins:
		_coins.text = str(SaveData.coins) + "  JETON"


func _on_code() -> void:
	var seed := GameScreen.code_to_seed(_code_input.text)
	if seed <= 0:
		Sfx.blip(160.0, -10.0)
		return
	main.screens["game"].start_seeded(seed)
	main.go("game")
