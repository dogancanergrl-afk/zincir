class_name UiKit
# Butun arayuz parcalari buradan cikiyor. Tema degisince ekranlar yeniden
# kuruluyor ve bu fonksiyonlar yeni renklerle calisiyor — her yerde tek tek
# renk atamak yerine tek nokta.


static func box(bg: Color, border := 0, border_col := Color.BLACK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	var r := Skins.radius()
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	if border > 0:
		sb.border_width_left = border
		sb.border_width_right = border
		sb.border_width_top = border
		sb.border_width_bottom = border
		sb.border_color = border_col
	if Skins.has_hard_shadow():
		sb.shadow_size = 0
	else:
		sb.shadow_size = 10
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_offset = Vector2(0, 4)
	return sb


static func label(text: String, size: int, color: Color, body := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Skins.body_font() if body else Skins.ui_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if Skins.has_hard_shadow() and not body:
		# Golge koyu renkte: ayni renkte olsa harf govdeleriyle birlesip
		# okunurlugu bozuyor.
		l.add_theme_color_override("font_shadow_color", Skins.col("edge"))
		l.add_theme_constant_override("shadow_offset_x", max(2, int(size / 10)))
		l.add_theme_constant_override("shadow_offset_y", max(2, int(size / 10)))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


static func body(text: String, size := 15) -> Label:
	var l := label(text, size, Skins.col("muted"), true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, size := 18) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", Skins.ui_font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Skins.col("cream"))
	b.add_theme_color_override("font_hover_color", Skins.col("cream"))
	b.add_theme_color_override("font_pressed_color", Skins.col("acc"))
	b.add_theme_color_override("font_disabled_color", Skins.col("muted"))
	b.add_theme_stylebox_override("normal", box(Skins.col("deep"), 3, Skins.col("line")))
	b.add_theme_stylebox_override("hover", box(Skins.col("panel"), 3, Skins.col("line")))
	b.add_theme_stylebox_override("pressed", box(Skins.col("edge"), 3, Skins.col("line")))
	b.add_theme_stylebox_override("disabled", box(Skins.col("deep"), 3, Skins.col("edge")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(0, 76)
	b.pressed.connect(func(): Sfx.blip(520.0, -18.0))
	return b


static func accent_button(text: String, size := 22) -> Button:
	var b := button(text, size)
	b.add_theme_color_override("font_color", Skins.col("acc"))
	b.add_theme_stylebox_override("normal", box(Skins.col("deep"), 3, Skins.col("acc")))
	b.add_theme_stylebox_override("hover", box(Skins.col("panel"), 3, Skins.col("acc")))
	return b


static func panel(bg_name := "deep", border := 3) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Skins.col(bg_name), border, Skins.col("line")))
	return p


static func card() -> VBoxContainer:
	# Icinde baslik + aciklama olan kutu. Disini cagiran saricak.
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	return v


static func spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


static func slider(value: float, lo: float, hi: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s
