class_name ModeScreen
extends Control

var main
var _list: VBoxContainer

const INFO := {
	"endless": {
		"name": "SONSUZ",
		"desc": "Bitiş yok, sadece skor. Tahta her hamlede dolduğu için pratikte hiç kaybetmezsin — dengeyi ölçmek için var.",
	},
	"timer": {
		"name": "SÜRE",
		"desc": "Geri sayım. Her birleştirme zincir uzunluğuna göre süre ekler, yani uzun zincir hem puan hem nefes demek.",
	},
	"moves": {
		"name": "HAMLE",
		"desc": "Sınırlı hak. Belirlediğin uzunluğun üstündeki zincirler harcanan hamleyi geri verir.",
	},
}


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
	var h := UiKit.label("MOD", 30, Skins.col("acc"))
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

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)

	_render()


func on_enter() -> void:
	_render()


func _render() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()

	for k in ["endless", "timer", "moves"]:
		var active: bool = (Cfg.mode == k)
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

		v.add_child(UiKit.label(INFO[k]["name"], 22, Skins.col("acc2") if active else Skins.col("acc")))
		v.add_child(UiKit.body(INFO[k]["desc"], 15))

		var rec := int(SaveData.best_scores.get(k, 0))
		if rec > 0:
			var r := UiKit.body("rekorun: %d" % rec, 14)
			r.add_theme_color_override("font_color", Skins.col("acc"))
			v.add_child(r)

		if k == "timer":
			_slider_row(v, "başlangıç süresi", Cfg.timer_start, 20, 120, 5,
				func(x): Cfg.timer_start = x, "%.0f sn")
			_slider_row(v, "zincir başına kazanç", Cfg.timer_gain, 0.2, 2.5, 0.1,
				func(x): Cfg.timer_gain = x, "%.1f sn")
		elif k == "moves":
			_slider_row(v, "hamle hakkı", float(Cfg.moves_start), 10, 80, 5,
				func(x): Cfg.moves_start = int(x), "%.0f")
			_slider_row(v, "iade için zincir boyu", float(Cfg.moves_refund), 2, 7, 1,
				func(x): Cfg.moves_refund = int(x), "%.0f")

		var pick := UiKit.button("KULLANILIYOR" if active else "BU MODU SEÇ", 16)
		pick.disabled = active
		if not active:
			pick.pressed.connect(func(): Cfg.mode = k; _render())
		v.add_child(pick)


func _slider_row(parent: VBoxContainer, title: String, value: float,
		lo: float, hi: float, step: float, setter: Callable, fmt: String) -> void:
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
