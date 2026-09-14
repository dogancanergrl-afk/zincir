extends Control
# Ekran yoneticisi. Tum ekranlar kodla kuruluyor, sahne agacinda tek bir
# dugum var. Tema degisince ekranlar yeniden insa ediliyor.

const W := 720.0
const H := 1280.0

var screens := {}
var current := ""

var backdrop: Control
var scanlines: Control
var ad_layer: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Skins.key = SaveData.theme

	backdrop = Backdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_add_screen("title", TitleScreen.new())
	_add_screen("game", GameScreen.new())
	_add_screen("shop", ShopScreen.new())
	_add_screen("mode", ModeScreen.new())
	_add_screen("tune", TuneScreen.new())
	_add_screen("board", LeaderScreen.new())

	scanlines = Scanlines.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scanlines)

	ad_layer = AdOverlay.new()
	ad_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ad_layer.visible = false
	add_child(ad_layer)

	Skins.changed.connect(_on_theme_changed)

	for s in screens.values():
		s.build()
	go("title")


func _add_screen(name: String, node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.visible = false
	node.main = self
	screens[name] = node
	add_child(node)


func go(name: String) -> void:
	if not screens.has(name):
		return
	for k in screens:
		screens[k].visible = (k == name)
	current = name
	if screens[name].has_method("on_enter"):
		screens[name].on_enter()


func _on_theme_changed() -> void:
	backdrop.queue_redraw()
	scanlines.queue_redraw()
	for s in screens.values():
		s.build()
	go(current)


func play_ad(on_reward: Callable) -> void:
	ad_layer.start(on_reward)


# ============================================================ arka plan

class Backdrop extends Control:
	func _draw() -> void:
		var s := size
		draw_rect(Rect2(Vector2.ZERO, s), Skins.col("void"))

		# ust taraftaki gokyuzu parlamasi — bantli, kasitli olarak dithered
		var sky := Skins.col("sky")
		var bands := 26
		for i in bands:
			var t := float(i) / float(bands)
			var a: float = (1.0 - t) * 0.7
			var h: float = s.y * 0.42 / float(bands)
			draw_rect(Rect2(0.0, h * i, s.x, h + 1.0), Color(sky.r, sky.g, sky.b, a))

		# alttaki vurgu parlamasi
		var glow := Skins.col("glow")
		if glow.a > 0.01:
			for i in bands:
				var t := float(i) / float(bands)
				var h: float = s.y * 0.34 / float(bands)
				var y: float = s.y - h * (bands - i)
				draw_rect(Rect2(0.0, y, s.x, h + 1.0), Color(glow.r, glow.g, glow.b, glow.a * t))


class Scanlines extends Control:
	func _draw() -> void:
		var a := Skins.scan()
		if a <= 0.001:
			return
		var y := 0.0
		while y < size.y:
			draw_rect(Rect2(0.0, y, size.x, 1.0), Color(0, 0, 0, a))
			y += 3.0


# ============================================================ sahte reklam

class AdOverlay extends Control:
	var _label: Label
	var _close: Button
	var _left := 5
	var _cb: Callable
	var _timer: Timer

	func _ready() -> void:
		var bg := ColorRect.new()
		bg.color = Color(0, 0, 0, 1)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 22)
		add_child(v)

		var note := UiKit.body("PROTOTİP — burada gerçek AdMob ödüllü reklamı oynayacak", 15)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_color_override("font_color", Color("777777"))
		v.add_child(note)

		var box := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("161616")
		sb.border_width_left = 2; sb.border_width_right = 2
		sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = Color("333333")
		box.add_theme_stylebox_override("panel", sb)
		box.custom_minimum_size = Vector2(0, 340)
		var inner := UiKit.body("REKLAM ALANI", 16)
		inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inner.add_theme_color_override("font_color", Color("555555"))
		box.add_child(inner)
		v.add_child(box)

		_label = UiKit.body("5", 30)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_color_override("font_color", Color("cccccc"))
		v.add_child(_label)

		_close = UiKit.button("KAPAT", 18)
		_close.disabled = true
		_close.pressed.connect(_finish)
		v.add_child(_close)

		_timer = Timer.new()
		_timer.wait_time = 1.0
		_timer.timeout.connect(_tick)
		add_child(_timer)

	func start(cb: Callable) -> void:
		_cb = cb
		_left = 5
		_label.text = "5"
		_close.text = "KAPAT"
		_close.disabled = true
		visible = true
		Sfx.duck(false)
		_timer.start()

	func _tick() -> void:
		_left -= 1
		_label.text = str(_left) if _left > 0 else ""
		if _left <= 0:
			_timer.stop()
			_close.disabled = false
			_close.text = "ÖDÜLÜ AL"

	func _finish() -> void:
		visible = false
		Sfx.duck(true)
		if _cb.is_valid():
			_cb.call()
