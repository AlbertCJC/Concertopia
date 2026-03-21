extends Control

const LOGIN_SCENE := "res://screens/login.tscn"

# ── Artist room data ───────────────────────────────────────────────────────────
const ROOMS : Array = [
	{
		"artist":     "BRUNO\nMARS",
		"genre":      "Pop / R&B",
		"crowd":      67,
		"door_color": Color(0.55, 0.30, 0.10),   # warm brown
		"bg_color1":  Color(0.55, 0.25, 0.05),   # dark amber
		"bg_color2":  Color(0.85, 0.45, 0.10),   # bright orange
		"char_color": Color(0.85, 0.65, 0.20),   # golden
		"accent":     Color(1.00, 0.65, 0.15),
	},
	{
		"artist":     "TAYLOR\nSWIFT",
		"genre":      "Pop",
		"crowd":      67,
		"door_color": Color(0.90, 0.35, 0.55),   # hot pink
		"bg_color1":  Color(0.55, 0.05, 0.25),   # deep magenta
		"bg_color2":  Color(0.90, 0.30, 0.60),   # bright pink
		"char_color": Color(1.00, 0.80, 0.85),
		"accent":     Color(1.00, 0.55, 0.75),
	},
	{
		"artist":     "ARIANA\nGRANDE",
		"genre":      "Pop / R&B",
		"crowd":      67,
		"door_color": Color(0.55, 0.50, 0.80),   # lavender
		"bg_color1":  Color(0.20, 0.05, 0.35),   # deep purple
		"bg_color2":  Color(0.55, 0.15, 0.75),   # violet
		"char_color": Color(0.80, 0.65, 1.00),
		"accent":     Color(0.75, 0.50, 1.00),
	},
	{
		"artist":     "CHAPPELL\nROAN",
		"genre":      "Pop",
		"crowd":      67,
		"door_color": Color(0.75, 0.38, 0.12),   # rust orange
		"bg_color1":  Color(0.50, 0.18, 0.04),   # dark rust
		"bg_color2":  Color(0.90, 0.45, 0.10),   # burnt orange
		"char_color": Color(1.00, 0.75, 0.50),
		"accent":     Color(1.00, 0.55, 0.20),
	},
	{
		"artist":     "THE\nWEEKND",
		"genre":      "R&B",
		"crowd":      67,
		"door_color": Color(0.12, 0.12, 0.18),   # near-black
		"bg_color1":  Color(0.08, 0.04, 0.20),
		"bg_color2":  Color(0.30, 0.10, 0.50),
		"char_color": Color(0.80, 0.70, 1.00),
		"accent":     Color(0.60, 0.30, 1.00),
	},
]

# ── State ──────────────────────────────────────────────────────────────────────
var _current_idx   : int  = 0
var _is_animating  : bool = false

# ── Node refs ─────────────────────────────────────────────────────────────────
var _card_row      : Control = null   # container that holds all cards side-by-side
var _card_nodes    : Array[Control] = []
var _stage         : Control = null   # clipping stage area

const CARD_W       : float = 280.0
const CARD_H       : float = 160.0
const SLIDE_DUR    : float = 0.40
const CARD_RADIUS  : int   = 16

func _ready() -> void:
	_build_ui()

# ── UI construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var vp_w  : float = get_viewport().get_visible_rect().size.x
	var vp_h  : float = get_viewport().get_visible_rect().size.y
	var pixel_font := load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Top bar — logout
	var top_bar := Control.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 56)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var logout_btn := Button.new()
	logout_btn.text = "← Back"
	logout_btn.flat = true
	logout_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	logout_btn.add_theme_font_size_override("font_size", 15)
	if pixel_font:
		logout_btn.add_theme_font_override("font", pixel_font)
	logout_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	logout_btn.offset_left  = 16
	logout_btn.offset_right = 110
	logout_btn.offset_top   = -20
	logout_btn.offset_bottom = 20
	logout_btn.pressed.connect(_on_logout)
	top_bar.add_child(logout_btn)

	# Title
	var title := Label.new()
	title.text = "Choose Artist's Concert Room"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top    = 68
	title.offset_bottom = 110
	title.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Stage — clipping area that shows one card at a time
	var stage_y  : float = 120.0
	var stage_h  : float = CARD_H + 40.0
	_stage = Control.new()
	_stage.clip_contents = true
	_stage.position      = Vector2(0, stage_y)
	_stage.size          = Vector2(vp_w, stage_h)
	_stage.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# Card row — slides inside the stage
	_card_row = Control.new()
	_card_row.position    = Vector2(0, 0)
	_card_row.size        = Vector2(float(ROOMS.size()) * vp_w, stage_h)
	_card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_card_row)

	# Build one card per room
	for i in ROOMS.size():
		var card : Control = _make_room_card(ROOMS[i], vp_w, stage_h)
		card.position = Vector2(float(i) * vp_w, 0)
		_card_row.add_child(card)
		_card_nodes.append(card)

	# Arrow buttons
	_make_arrow_btn("<", vp_w, stage_y, stage_h, -1, pixel_font)
	_make_arrow_btn(">", vp_w, stage_y, stage_h,  1, pixel_font)

	# ENTER button
	var enter_y : float = stage_y + stage_h + 28.0
	var enter_btn := Button.new()
	enter_btn.text = "ENTER"
	enter_btn.custom_minimum_size = Vector2(180, 46)
	if pixel_font:
		enter_btn.add_theme_font_override("font", pixel_font)
	enter_btn.add_theme_font_size_override("font_size", 17)
	enter_btn.add_theme_color_override("font_color", Color(1, 1, 1))

	var enter_normal := StyleBoxFlat.new()
	enter_normal.bg_color = Color(0.96, 0.57, 0.72)
	enter_normal.set_corner_radius_all(23)
	enter_normal.content_margin_left   = 24
	enter_normal.content_margin_right  = 24
	enter_normal.content_margin_top    = 10
	enter_normal.content_margin_bottom = 10
	var enter_hover := StyleBoxFlat.new()
	enter_hover.bg_color = Color(1.0, 0.70, 0.82)
	enter_hover.set_corner_radius_all(23)
	enter_hover.content_margin_left   = 24
	enter_hover.content_margin_right  = 24
	enter_hover.content_margin_top    = 10
	enter_hover.content_margin_bottom = 10
	enter_btn.add_theme_stylebox_override("normal",  enter_normal)
	enter_btn.add_theme_stylebox_override("hover",   enter_hover)
	enter_btn.add_theme_stylebox_override("pressed", enter_normal)

	# Centre the button
	enter_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	enter_btn.offset_top    = enter_y
	enter_btn.offset_bottom = enter_y + 46
	enter_btn.offset_left   = vp_w / 2.0 - 90
	enter_btn.offset_right  = -(vp_w / 2.0 - 90)
	enter_btn.pressed.connect(_on_enter_pressed)
	add_child(enter_btn)

	# Snap to first card
	_snap_row()

# ── Build a single room card ───────────────────────────────────────────────────

func _make_room_card(data: Dictionary, vp_w: float, stage_h: float) -> Control:
	var pixel_font := load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile

	# Outer centring container
	var outer := Control.new()
	outer.size          = Vector2(vp_w, stage_h)
	outer.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	# Card panel
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = data["bg_color1"]
	card_style.set_corner_radius_all(CARD_RADIUS)
	card_style.content_margin_left   = 0
	card_style.content_margin_right  = 0
	card_style.content_margin_top    = 0
	card_style.content_margin_bottom = 0
	card.add_theme_stylebox_override("panel", card_style)
	# Centre the card
	card.size     = Vector2(CARD_W, CARD_H)
	card.position = Vector2((vp_w - CARD_W) / 2.0, (stage_h - CARD_H) / 2.0)
	outer.add_child(card)

	# Inner layout: door | content area
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)

	# ── Door panel (left) ─────────────────────────────────────────────────────
	var door_panel := _make_door(data["door_color"], pixel_font)
	door_panel.custom_minimum_size = Vector2(70, CARD_H)
	hbox.add_child(door_panel)

	# ── Right content ─────────────────────────────────────────────────────────
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right)

	# Bokeh/crowd background gradient
	var bokeh := _make_bokeh_bg(data["bg_color1"], data["bg_color2"], data["accent"])
	bokeh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bokeh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(bokeh)

	# Crowd badge top-left
	var badge := _make_crowd_badge(data["crowd"], pixel_font)
	badge.position = Vector2(8, 8)
	right.add_child(badge)

	# Artist name — left-aligned, vertically centred
	var artist_lbl := Label.new()
	artist_lbl.text = data["artist"]
	artist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	artist_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	artist_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	artist_lbl.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		artist_lbl.add_theme_font_override("font", pixel_font)
	artist_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artist_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artist_lbl.offset_left   = 12
	artist_lbl.offset_right  = -72
	artist_lbl.offset_top    = 0
	artist_lbl.offset_bottom = 0
	right.add_child(artist_lbl)

	# Pixel character (right side of card)
	var char_ctrl := _make_pixel_char(data["char_color"])
	char_ctrl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	char_ctrl.offset_right  = -6
	char_ctrl.offset_left   = -66
	char_ctrl.offset_top    = -50
	char_ctrl.offset_bottom =  50
	right.add_child(char_ctrl)

	return outer

# ── Door graphic ───────────────────────────────────────────────────────────────

func _make_door(door_color: Color, pixel_font: FontFile) -> Control:
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Door background
	var door_bg := ColorRect.new()
	door_bg.color = door_color.darkened(0.3)
	door_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	door_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(door_bg)

	# Door frame (drawn as a NinePatchRect substitute using nested ColorRects)
	# Frame border
	var frame := ColorRect.new()
	frame.color = door_color.lightened(0.15)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left   = 8
	frame.offset_right  = -8
	frame.offset_top    = 12
	frame.offset_bottom = -8
	frame.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(frame)

	# Door fill
	var door_fill := ColorRect.new()
	door_fill.color = door_color
	door_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	door_fill.offset_left   = 12
	door_fill.offset_right  = -12
	door_fill.offset_top    = 16
	door_fill.offset_bottom = -12
	door_fill.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(door_fill)

	# Panel lines on door (horizontal stripes)
	for i in 3:
		var stripe := ColorRect.new()
		stripe.color = door_color.darkened(0.25)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var y_off : float = 22.0 + float(i) * 28.0
		stripe.offset_left   = 14
		stripe.offset_right  = -14
		stripe.offset_top    = y_off
		stripe.offset_bottom = y_off + 18
		ctrl.add_child(stripe)

	# Doorknob
	var knob := ColorRect.new()
	knob.color = Color(1.0, 0.85, 0.3)
	knob.custom_minimum_size = Vector2(6, 6)
	knob.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	knob.offset_right  = -17
	knob.offset_left   = -23
	knob.offset_top    = 4
	knob.offset_bottom = 10
	knob.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(knob)

	return ctrl

# ── Bokeh background ───────────────────────────────────────────────────────────

func _make_bokeh_bg(c1: Color, c2: Color, accent: Color) -> Control:
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Base gradient colour
	var base := ColorRect.new()
	base.color = c1
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(base)

	# Bokeh circles — random-ish dots to simulate crowd bokeh lights
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c2.r * 1000) + int(c2.g * 100)
	for i in 28:
		var dot := ColorRect.new()
		var sz   : float = rng.randf_range(4, 14)
		dot.custom_minimum_size = Vector2(sz, sz)
		dot.color = Color(accent.r, accent.g, accent.b,
			rng.randf_range(0.08, 0.35))
		dot.position = Vector2(
			rng.randf_range(0, 210),
			rng.randf_range(0, CARD_H))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctrl.add_child(dot)

	# Bright spot (stage glow) bottom-centre
	var glow := ColorRect.new()
	glow.color = Color(c2.r, c2.g, c2.b, 0.25)
	glow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	glow.offset_top    = -40
	glow.offset_bottom = 0
	glow.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	ctrl.add_child(glow)

	return ctrl

# ── Crowd badge ────────────────────────────────────────────────────────────────

func _make_crowd_badge(count: int, pixel_font: FontFile) -> Control:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 6
	style.content_margin_right  = 8
	style.content_margin_top    = 3
	style.content_margin_bottom = 3
	badge.add_theme_stylebox_override("panel", style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "👥"
	icon_lbl.add_theme_font_size_override("font_size", 11)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(count)
	count_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	count_lbl.add_theme_font_size_override("font_size", 11)
	if pixel_font:
		count_lbl.add_theme_font_override("font", pixel_font)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(count_lbl)

	return badge

# ── Pixel character silhouette ─────────────────────────────────────────────────

func _make_pixel_char(tint: Color) -> Control:
	var ctrl := Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Simple blocky character made from ColorRects — head, body, legs
	var parts : Array = [
		# [x, y, w, h]  — relative to ctrl, ctrl is 60×100
		[18, 0,  24, 22],  # head
		[12, 22, 36, 32],  # body
		[12, 54, 14, 26],  # left leg
		[34, 54, 14, 26],  # right leg
		[2,  26, 10, 22],  # left arm
		[48, 26, 10, 22],  # right arm
	]
	for p in parts:
		var r := ColorRect.new()
		r.color = tint
		r.position = Vector2(p[0], p[1])
		r.size     = Vector2(p[2], p[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctrl.add_child(r)

	return ctrl

# ── Arrow button ───────────────────────────────────────────────────────────────

func _make_arrow_btn(symbol: String, vp_w: float, stage_y: float, stage_h: float,
					 dir: int, pixel_font: FontFile) -> void:
	var btn := Button.new()
	btn.text = symbol
	btn.flat = true
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	btn.add_theme_font_size_override("font_size", 32)
	if pixel_font:
		btn.add_theme_font_override("font", pixel_font)
	btn.custom_minimum_size = Vector2(44, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var cx_x : float = 28.0 if dir == -1 else vp_w - 28.0
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left   = cx_x - 22
	btn.offset_right  = cx_x + 22
	btn.offset_top    = stage_y + stage_h / 2.0 - 22
	btn.offset_bottom = stage_y + stage_h / 2.0 + 22
	btn.pressed.connect(func() -> void: _navigate(dir))
	add_child(btn)

# ── Navigation ─────────────────────────────────────────────────────────────────

func _navigate(dir: int) -> void:
	if _is_animating:
		return
	var next : int = _current_idx + dir
	if next < 0 or next >= ROOMS.size():
		# Bounce: quick shake animation
		_bounce_card(dir)
		return
	_current_idx  = next
	_is_animating = true
	_slide_row(true)

func _snap_row() -> void:
	_card_row.position.x = _row_target_x()

func _slide_row(animate: bool) -> void:
	var target_x : float = _row_target_x()
	if animate:
		var t := create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(_card_row, "position:x", target_x, SLIDE_DUR)
		t.finished.connect(func() -> void: _is_animating = false)
	else:
		_card_row.position.x = target_x
		_is_animating = false

func _row_target_x() -> float:
	# Each card is centred in a vp_w-wide slot inside _card_row
	var vp_w : float = get_viewport().get_visible_rect().size.x
	return -float(_current_idx) * vp_w

func _bounce_card(dir: int) -> void:
	# Tiny overshoot and return to indicate edge
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	var nudge : float = float(dir) * -18.0
	var base  : float = _row_target_x()
	t.tween_property(_card_row, "position:x", base + nudge, 0.12)
	t.tween_property(_card_row, "position:x", base,          0.18)

# ── Actions ────────────────────────────────────────────────────────────────────

func _on_enter_pressed() -> void:
	var room : Dictionary = ROOMS[_current_idx]
	print("Entering room: ", room["artist"])
	# TODO: navigate to concert room scene

func _on_logout() -> void:
	AuthManager.logout()
	get_tree().change_scene_to_file.call_deferred(LOGIN_SCENE)
