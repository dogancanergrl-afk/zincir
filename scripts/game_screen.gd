class_name GameScreen
extends Control

const GAP := 8.0

var main

# ---- dugumler ----
var _board: Control
var _shake_root: Control
var _tiles_root: Control
var _line: Line2D
var _floats: Control
var _score_lbl: Label
var _best_lbl: Label
var _press_lbl: Label
var _press_tag: Label
var _press_box: VBoxContainer
var _combo_row: HBoxContainer
var _combo_lbl: Label
var _meter_fill: Panel
var _meter_bg: PanelContainer
var _over: Control
var _over_title: Label
var _over_stats: Label
var _over_coins: Label
var _over_seed: Label
var _double_btn: Button
var _tel: Array[Label] = []

# ---- durum ----
var cell := 100.0
var grid := []
var chain: Array[Vector2i] = []
var dragging := false
var locked := true

var score := 0
var best := 2
var combo := 0
var combo_left := 0.0
var combo_window := 2.6

var time_left := 0.0
var moves_left := 0

var rng := RandomNumberGenerator.new()
var current_seed := 0

var m_merges := 0
var m_chain_sum := 0
var m_best_combo := 1
var m_breaks := 0
var m_start := 0.0

var pending_coins := 0
var doubled := false

var shake_time := 0.0
var shake_amp := 0.0
var _board_home := Vector2.ZERO


# ============================================================ kurulum

func build() -> void:
	for c in get_children():
		c.queue_free()
	_tiles_root = null

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	# ---------------- ust serit ----------------
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	v.add_child(hud)

	var back := UiKit.button("‹ MENÜ", 16)
	back.custom_minimum_size = Vector2(150, 62)
	back.pressed.connect(func(): main.go("title"))
	hud.add_child(back)

	hud.add_child(_grow_spacer())

	var sbox := _stat_box("SCORE", Skins.col("acc"))
	_score_lbl = sbox.get_child(0)
	hud.add_child(sbox)

	var bbox := _stat_box("BEST", Skins.col("cream"))
	_best_lbl = bbox.get_child(0)
	hud.add_child(bbox)

	_press_box = _stat_box("TIME", Skins.col("acc2"))
	_press_lbl = _press_box.get_child(0)
	_press_tag = _press_box.get_child(1)
	hud.add_child(_press_box)

	# Uzun telefonlarda alta buyuk bir bosluk kaliyordu. Esnek bosluklar
	# tahtayi kalan alanin ortasina yerlestiriyor.
	v.add_child(_grow_v_spacer())

	# ---------------- kombo ----------------
	_combo_row = HBoxContainer.new()
	_combo_row.add_theme_constant_override("separation", 12)
	_combo_row.modulate.a = 0.0
	v.add_child(_combo_row)

	_combo_lbl = UiKit.label("COMBO x2", 20, Skins.col("acc2"))
	_combo_lbl.custom_minimum_size = Vector2(190, 32)
	_combo_row.add_child(_combo_lbl)

	_meter_bg = PanelContainer.new()
	_meter_bg.add_theme_stylebox_override("panel", UiKit.box(Skins.col("edge"), 3, Skins.col("line")))
	_meter_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meter_bg.custom_minimum_size = Vector2(0, 26)
	_combo_row.add_child(_meter_bg)

	_meter_fill = Panel.new()
	_meter_fill.add_theme_stylebox_override("panel", UiKit.box(Skins.col("acc2")))
	_meter_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter_bg.add_child(_meter_fill)

	# ---------------- tahta ----------------
	var cols: int = Cfg.COLS
	var rows: int = Cfg.ROWS
	var avail_w := 720.0 - 68.0
	var avail_h := 950.0
	cell = floor(min((avail_w - GAP * (cols + 1)) / cols, (avail_h - GAP * (rows + 1)) / rows))

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.box(Skins.col("panel"), 4, Skins.col("line")))
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(frame)

	_board = Control.new()
	_board.custom_minimum_size = Vector2(
		GAP * (cols + 1) + cell * cols,
		GAP * (rows + 1) + cell * rows)
	_board.clip_contents = true
	_board.gui_input.connect(_on_board_input)
	frame.add_child(_board)

	for r in rows:
		for c in cols:
			var slot := Panel.new()
			slot.add_theme_stylebox_override("panel", UiKit.box(Skins.col("slot")))
			slot.position = cell_pos(r, c)
			slot.size = Vector2(cell, cell)
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_board.add_child(slot)

	# Sarsinti icin ayri bir katman. Tahtanin kendisini oynatamiyoruz cunku
	# bir kapsayicinin cocugu — kapsayici konumu her cizimde geri aliyor ve
	# sarsinti bitince tahta yukari sicrayip orada kaliyordu.
	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_shake_root)

	_tiles_root = Control.new()
	_tiles_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tiles_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_tiles_root)

	_line = Line2D.new()
	_line.width = cell * 0.16
	_line.default_color = Color.WHITE
	_line.joint_mode = Line2D.LINE_JOINT_SHARP
	_line.begin_cap_mode = Line2D.LINE_CAP_BOX
	_line.end_cap_mode = Line2D.LINE_CAP_BOX
	_line.z_index = 10
	_shake_root.add_child(_line)

	_floats = Control.new()
	_floats.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floats.z_index = 20
	_shake_root.add_child(_floats)

	_build_over()

	# ---------------- olcum ----------------
	var tel_panel := PanelContainer.new()
	tel_panel.add_theme_stylebox_override("panel", UiKit.box(Skins.col("edge"), 3, Skins.col("line")))
	v.add_child(tel_panel)

	var tel_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		tel_margin.add_theme_constant_override("margin_" + side, 10)
	tel_panel.add_child(tel_margin)

	var tel_box := VBoxContainer.new()
	tel_box.add_theme_constant_override("separation", 2)
	tel_margin.add_child(tel_box)

	_tel.clear()
	for i in 2:
		var l := UiKit.body("", 15)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tel_box.add_child(l)
		_tel.append(l)

	v.add_child(_grow_v_spacer())

	if _tiles_root != null and not grid.is_empty():
		_rebuild_tiles()


func _grow_v_spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func _grow_spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _stat_box(tag: String, color: Color) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", 2)
	var val := UiKit.label("0", 30, color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(val)
	var t := UiKit.body(tag, 13)
	# Satir kaydirma acik kalinca "SCORE" etiketi "SCOR / E" diye
	# ikiye bolunuyordu.
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(t)
	b.custom_minimum_size = Vector2(120, 0)
	return b


func _build_over() -> void:
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.visible = false
	_over.z_index = 30
	_board.add_child(_over)

	var bg := ColorRect.new()
	bg.color = Color(Skins.col("void"), 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.add_child(bg)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 20)
	_over.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	_over_title = UiKit.label("GAME OVER", 30, Skins.col("acc2"))
	_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_over_title)

	_over_stats = UiKit.body("", 16)
	_over_stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_over_stats)

	_over_coins = UiKit.label("+0 JETON", 20, Skins.col("acc"))
	_over_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_over_coins)

	_over_seed = UiKit.body("tahta kodu —", 15)
	_over_seed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_over_seed)

	_double_btn = UiKit.button("REKLAMLA 2 KATI", 16)
	_double_btn.pressed.connect(_on_double)
	v.add_child(_double_btn)

	var share := UiKit.button("MEYDAN OKU", 16)
	share.pressed.connect(_on_share)
	v.add_child(share)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)

	var same := UiKit.button("AYNI TAHTA", 14)
	same.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	same.pressed.connect(func(): start_seeded(current_seed))
	row.add_child(same)

	var again := UiKit.button("YENİ TAHTA", 14)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(start_new)
	row.add_child(again)

	var menu := UiKit.button("MENÜ", 14)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func(): main.go("title"))
	row.add_child(menu)


# ============================================================ tohum

static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


static func seed_to_code(s: int) -> String:
	const DIGITS := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var n := s
	var out := ""
	while n > 0:
		out = DIGITS[n % 36] + out
		n /= 36
	while out.length() < 6:
		out = "0" + out
	return out


static func code_to_seed(code: String) -> int:
	const DIGITS := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var c := code.strip_edges().to_upper()
	if c.is_empty():
		return 0
	var n := 0
	for ch in c:
		var i := DIGITS.find(ch)
		if i < 0:
			return 0
		n = n * 36 + i
	return n


# ============================================================ baslatma

func start_new() -> void:
	start_seeded(randi_range(1, 2176782335))


func start_seeded(s: int) -> void:
	current_seed = s
	rng.seed = s
	rng.state = s

	for c in _tiles_root.get_children():
		c.queue_free()
	for c in _floats.get_children():
		c.queue_free()

	grid = []
	for r in Cfg.ROWS:
		var row := []
		for c in Cfg.COLS:
			row.append(null)
		grid.append(row)

	chain.clear()
	dragging = false
	locked = false
	score = 0
	best = 2
	combo = 0
	combo_left = 0.0
	m_merges = 0
	m_chain_sum = 0
	m_best_combo = 1
	m_breaks = 0
	m_start = Time.get_ticks_msec() / 1000.0

	_score_lbl.text = "0"
	_best_lbl.text = "2"
	_combo_row.modulate.a = 0.0
	_over.visible = false
	_line.clear_points()

	for c in Cfg.COLS:
		var drop := -1.0
		for r in range(Cfg.ROWS - 1, -1, -1):
			grid[r][c] = _make_tile(_spawn_value(), r, c, drop)
			drop -= 1.0

	if not _any_move():
		start_new()
		return

	_start_pressure()
	_update_tel()


func on_enter() -> void:
	pass


# ============================================================ kareler

func cell_pos(r: int, c: int) -> Vector2:
	return Vector2(GAP + c * (cell + GAP), GAP + r * (cell + GAP))


func cell_center(r: int, c: int) -> Vector2:
	return cell_pos(r, c) + Vector2(cell, cell) * 0.5


func _make_tile(value: int, row: int, col: int, from_row: float) -> Dictionary:
	var node := Panel.new()
	node.size = Vector2(cell, cell)
	node.pivot_offset = Vector2(cell, cell) * 0.5
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = Vector2(cell_pos(row, col).x, GAP + from_row * (cell + GAP))
	_tiles_root.add_child(node)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", Skins.num_font())
	lbl.add_theme_color_override("font_color", Color("12121a"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(lbl)

	var t := {"value": value, "row": row, "col": col, "node": node, "label": lbl}
	_paint(t)
	_move_tile(t, row, col)
	return t


func _paint(t: Dictionary) -> void:
	var v: int = t["value"]
	t["node"].add_theme_stylebox_override("panel", UiKit.box(Skins.tint(v), 3, Skins.col("edge")))
	t["label"].text = str(v)
	var digits := str(v).length()
	var factor := 0.44
	if digits == 3:
		factor = 0.34
	elif digits == 4:
		factor = 0.26
	elif digits >= 5:
		factor = 0.21
	t["label"].add_theme_font_size_override("font_size", int(cell * factor))


func _move_tile(t: Dictionary, row: int, col: int, dur := 0.16) -> void:
	t["row"] = row
	t["col"] = col
	var tw := create_tween()
	tw.tween_property(t["node"], "position", cell_pos(row, col), dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _rebuild_tiles() -> void:
	# Tema degisiminden sonra kareleri veriden yeniden ciz.
	for r in Cfg.ROWS:
		for c in Cfg.COLS:
			var t = grid[r][c]
			if t == null:
				continue
			grid[r][c] = _make_tile(t["value"], r, c, float(r))


func _spawn_value() -> int:
	# Havuzun tavani en buyuk kareye gore yukseliyor, taban da onunla
	# birlikte kalkiyor. Yoksa tahta sonsuza kadar 2'lerle dolardi.
	var cap_exp := int(floor(log(max(4.0, float(best) / Cfg.cap_div)) / log(2.0)))
	var pool: Array[int] = []
	for i in range(Cfg.spawn_count - 1, -1, -1):
		var v := int(pow(2, cap_exp - i))
		if v >= 2:
			pool.append(v)
	if pool.is_empty():
		pool.append(2)

	var weights: Array[float] = []
	var total := 0.0
	for i in pool.size():
		var w: float = pow(Cfg.spawn_bias, pool.size() - 1 - i)
		weights.append(w)
		total += w

	var roll := rng.randf() * total
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[0]


func _settle() -> void:
	for c in Cfg.COLS:
		var stack := []
		for r in range(Cfg.ROWS - 1, -1, -1):
			if grid[r][c] != null:
				stack.append(grid[r][c])
		var r := Cfg.ROWS - 1
		for t in stack:
			grid[r][c] = t
			if int(t["row"]) != r:
				_move_tile(t, r, c)
			r -= 1
		var drop := -1.0
		while r >= 0:
			grid[r][c] = _make_tile(_spawn_value(), r, c, drop)
			drop -= 1.0
			r -= 1


func _any_move() -> bool:
	for r in Cfg.ROWS:
		for c in Cfg.COLS:
			if grid[r][c] == null:
				continue
			var v: int = grid[r][c]["value"]
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0:
						continue
					var nr: int = r + dr
					var nc: int = c + dc
					if nr < 0 or nr >= Cfg.ROWS or nc < 0 or nc >= Cfg.COLS:
						continue
					if grid[nr][nc] == null:
						continue
					var n: int = grid[nr][nc]["value"]
					if n == v or n == v * 2 or v == n * 2:
						return true
	return false


# ============================================================ zincir

func _cell_at(local: Vector2) -> Vector2i:
	var c := int(floor((local.x - GAP * 0.5) / (cell + GAP)))
	var r := int(floor((local.y - GAP * 0.5) / (cell + GAP)))
	if r < 0 or r >= Cfg.ROWS or c < 0 or c >= Cfg.COLS:
		return Vector2i(-1, -1)
	return Vector2i(r, c)


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1 and a != b


func _chain_result() -> int:
	if chain.size() < 2:
		return 0
	var l := chain[chain.size() - 1]
	return int(grid[l.x][l.y]["value"]) * 2


func _on_board_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var p := _cell_at(event.position)
			if p.x >= 0 and grid[p.x][p.y] != null:
				dragging = true
				chain.clear()
				_try_extend(p)
		elif dragging:
			dragging = false
			_resolve()
	elif event is InputEventMouseMotion and dragging:
		_try_extend(_cell_at(event.position))


func _try_extend(p: Vector2i) -> void:
	if p.x < 0 or grid[p.x][p.y] == null:
		return
	if chain.is_empty():
		chain.append(p)
		Sfx.blip(240.0)
		_refresh_chain()
		return
	var last := chain[chain.size() - 1]
	if p == last:
		return
	if chain.size() >= 2 and p == chain[chain.size() - 2]:
		chain.pop_back()
		Sfx.blip(200.0)
		_refresh_chain()
		return
	if chain.has(p) or not _adjacent(last, p):
		return
	var a: int = grid[last.x][last.y]["value"]
	var b: int = grid[p.x][p.y]["value"]
	if b != a and b != a * 2:
		return
	chain.append(p)
	Sfx.blip(240.0 * pow(1.11, chain.size() - 1))
	_refresh_chain()


func _refresh_chain() -> void:
	_line.clear_points()
	for p in chain:
		_line.add_point(cell_center(p.x, p.y))

	var in_chain := {}
	for p in chain:
		in_chain[grid[p.x][p.y]["node"]] = true

	for r in Cfg.ROWS:
		for c in Cfg.COLS:
			var t = grid[r][c]
			if t == null:
				continue
			if chain.is_empty():
				t["node"].modulate = Color.WHITE
			elif in_chain.has(t["node"]):
				t["node"].modulate = Color(1.25, 1.25, 1.25)
			else:
				t["node"].modulate = Color(0.5, 0.5, 0.55)

	var res := _chain_result()
	_best_lbl.text = str(res) if res > 0 else str(best)


func _resolve() -> void:
	var result := _chain_result()
	if result == 0:
		chain.clear()
		_refresh_chain()
		return

	locked = true
	var length := chain.size()
	var target := chain[length - 1]
	var target_pos := cell_pos(target.x, target.y)

	for i in length - 1:
		var p := chain[i]
		var t = grid[p.x][p.y]
		grid[p.x][p.y] = null
		var node: Panel = t["node"]
		node.modulate = Color.WHITE
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(node, "position", target_pos, 0.15)
		tw.tween_property(node, "scale", Vector2(0.2, 0.2), 0.15)
		tw.tween_property(node, "modulate:a", 0.0, 0.15)
		tw.chain().tween_callback(node.queue_free)

	var head = grid[target.x][target.y]
	head["value"] = result
	_paint(head)
	head["node"].modulate = Color.WHITE
	var pop := create_tween()
	pop.tween_property(head["node"], "scale", Vector2(1.22, 1.22), 0.08)
	pop.tween_property(head["node"], "scale", Vector2.ONE, 0.12)

	_bump_combo(length)
	var gain := result * maxi(1, _mult())
	score += gain
	if result > best:
		best = result
	_score_lbl.text = str(score)
	_float_text(("+%d x%d" % [gain, _mult()]) if _mult() > 1 else "+%d" % gain, target.x, target.y)

	m_merges += 1
	m_chain_sum += length

	if Cfg.mode == "timer":
		time_left += Cfg.timer_gain * length
	elif Cfg.mode == "moves":
		moves_left -= 1
		if length >= Cfg.moves_refund:
			moves_left += 1
		_press_lbl.text = str(moves_left)

	var root := 300.0 + (log(float(result)) / log(2.0)) * 22.0
	Sfx.arp([root, root * 1.26, root * (2.0 if _mult() > 2 else 1.5)])

	chain.clear()
	_refresh_chain()

	await get_tree().create_timer(0.17).timeout
	if not is_instance_valid(self) or _over == null:
		return
	_settle()
	_best_lbl.text = str(best)

	if Cfg.mode == "moves" and moves_left <= 0:
		_game_over("HAMLE BİTTİ")
	elif not _any_move():
		_game_over("HAMLE KALMADI")
	else:
		locked = false
	_update_tel()


func _float_text(txt: String, r: int, c: int) -> void:
	var l := UiKit.label(txt, int(cell * 0.28), Skins.col("acc"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(cell * 3.0, cell * 0.5)
	l.position = cell_center(r, c) - Vector2(cell * 1.5, cell * 0.8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floats.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 90.0, 0.75)
	tw.tween_property(l, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(l.queue_free)


# ============================================================ kombo

func _mult() -> int:
	return mini(combo, Cfg.combo_max)


func _bump_combo(length: int) -> void:
	if length >= Cfg.combo_min:
		combo += 1
	combo_window = Cfg.combo_window + (length - 2) * Cfg.combo_per_tile
	combo_left = combo_window
	if combo > m_best_combo:
		m_best_combo = combo
	if combo >= 2:
		_combo_row.modulate.a = 1.0
		_combo_lbl.text = "COMBO x%d" % _mult()
	if combo >= 3 and Cfg.shake_enabled:
		shake_time = 0.22
		shake_amp = min(5.0 + combo * 1.5, 16.0)


func _process(delta: float) -> void:
	if not visible:
		return

	if combo_left > 0.0:
		combo_left -= delta
		var f: float = clamp(combo_left / combo_window, 0.0, 1.0)
		if _meter_fill and _meter_bg:
			_meter_fill.position = Vector2(4, 4)
			_meter_fill.size = Vector2(max(0.0, (_meter_bg.size.x - 8.0) * f), max(0.0, _meter_bg.size.y - 8.0))
		if combo_left <= 0.0:
			if combo >= 2:
				m_breaks += 1
			combo = 0 if Cfg.combo_decay == "reset" else maxi(0, combo - 1)
			if combo >= 2:
				combo_left = combo_window
				_combo_lbl.text = "COMBO x%d" % _mult()
			else:
				combo = 0
				_combo_row.modulate.a = 0.0

	if Cfg.mode == "timer" and not locked:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_press_lbl.text = "0"
			_game_over("SÜRE BİTTİ")
		else:
			_press_lbl.text = "%.1f" % time_left

	if shake_time > 0.0 and _shake_root:
		shake_time -= delta
		if shake_time <= 0.0:
			_shake_root.position = Vector2.ZERO
		else:
			_shake_root.position = Vector2(
				randf_range(-shake_amp, shake_amp),
				randf_range(-shake_amp, shake_amp) * 0.4)


func _start_pressure() -> void:
	if Cfg.mode == "endless":
		_press_box.visible = false
		return
	_press_box.visible = true
	if Cfg.mode == "timer":
		_press_tag.text = "TIME"
		time_left = Cfg.timer_start
		_press_lbl.text = "%.1f" % time_left
	else:
		_press_tag.text = "MOVES"
		moves_left = Cfg.moves_start
		_press_lbl.text = str(moves_left)


# ============================================================ oyun sonu

func _game_over(reason: String) -> void:
	if _over.visible:
		return
	locked = true
	dragging = false
	var secs: float = max(0.001, Time.get_ticks_msec() / 1000.0 - m_start)

	pending_coins = int(score / float(Cfg.COIN_PER_SCORE))
	doubled = false
	SaveData.add_coins(pending_coins)
	var is_record := SaveData.record(Cfg.mode, score)

	_over_title.text = reason
	_over_stats.text = "%d PUAN%s\nen büyük %d · %d birleştirme\nort zincir %.1f · en iyi kombo x%d\n%d sn · %d puan/dk" % [
		score, ("  ★ REKOR" if is_record else ""), best, m_merges,
		float(m_chain_sum) / max(1, m_merges), mini(m_best_combo, Cfg.combo_max),
		int(secs), int(score / (secs / 60.0))
	]
	_over_coins.text = "+%d JETON" % pending_coins
	_over_seed.text = "tahta kodu  " + seed_to_code(current_seed)
	_double_btn.visible = pending_coins > 0
	_double_btn.disabled = false
	_over.visible = true
	Sfx.arp([330.0, 262.0, 208.0, 165.0], 0.11)


func _on_double() -> void:
	if doubled or pending_coins <= 0:
		return
	main.play_ad(func():
		doubled = true
		SaveData.add_coins(pending_coins)
		_over_coins.text = "+%d JETON  (x2)" % (pending_coins * 2)
		_double_btn.disabled = true
		Sfx.arp([523.0, 659.0, 784.0, 1046.0], 0.07))


func _on_share() -> void:
	# Android'de yerel paylasim penceresi bir eklenti gerektiriyor.
	# Simdilik kodu panoya kopyaliyoruz; eklenti gelince buraya baglanacak.
	var code := seed_to_code(current_seed)
	var text := "Zincir'de %d puan yaptım. Aynı tahtada beni geçebilir misin? Kod: %s" % [score, code]
	DisplayServer.clipboard_set(text)
	_over_seed.text = "kopyalandı  " + code
	Sfx.blip(660.0)


func _update_tel() -> void:
	if _tel.size() < 2:
		return
	var secs: float = max(0.001, Time.get_ticks_msec() / 1000.0 - m_start)
	_tel[0].text = "%d birleştirme · ort zincir %.1f · kombo x%d" % [
		m_merges, float(m_chain_sum) / max(1, m_merges), mini(m_best_combo, Cfg.combo_max)]
	_tel[1].text = "%d kırılma · %d sn · %d puan/dk" % [
		m_breaks, int(secs), int(score / (secs / 60.0))]
