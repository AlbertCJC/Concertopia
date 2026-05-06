extends Control

const NEXT_SCENE : String = "res://screens/welcome_screen2.tscn"

func _ready() -> void:
	# Clean slate in case the .tscn had legacy nodes
	for child in get_children():
		child.queue_free()
	_build_ui()

func _build_ui() -> void:
	var pixel_font := load(
		"res://Pixelify_Sans/static/PixelifySans-Bold.ttf"
	) as FontFile

	var bg := ColorRect.new()
	bg.color        = Color(0.04, 0.03, 0.10) # Using C_BG from other scripts
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	# Optional: Add the same pixel grid as Vault
	var grid := TextureRect.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.stretch_mode = TextureRect.STRETCH_TILE
	grid.modulate.a = 0.05
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE); img.set_pixel(1, 1, Color.WHITE)
	grid.texture = ImageTexture.create_from_image(img)
	add_child(grid)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   40)
	margin.add_theme_constant_override("margin_right",  40)
	margin.add_theme_constant_override("margin_top",    0)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var centre := VBoxContainer.new()
	centre.alignment    = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 12)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(centre)

	var welcome := Label.new()
	welcome.text = "Welcome to"
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	welcome.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		welcome.add_theme_font_override("font", pixel_font)
	welcome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(welcome)

	var logo := Label.new()
	logo.text = "ConcerTopia"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_color", Color(1, 1, 1))
	logo.add_theme_font_size_override("font_size", 46) # Consistency
	if pixel_font:
		logo.add_theme_font_override("font", pixel_font)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(logo)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 15)
	sp.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	centre.add_child(sp)

	var tagline := Label.new()
	tagline.text = "Reimagining Concerts Through Pixel Art"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	tagline.add_theme_font_size_override("font_size", 14)
	if pixel_font:
		tagline.add_theme_font_override("font", pixel_font)
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(tagline)

	_build_bottom_bar(pixel_font, 0)

func _build_bottom_bar(pixel_font: FontFile, active_dot: int) -> void:
	# ── Dot indicator sizes ───────────────────────────────────────────────────
	# Active:   wide pill  — 40 × 5 px
	# Inactive: short pill — 16 × 5 px
	# Height reduced to 5 so they read as thin lines, not squares.
	var dot_row := HBoxContainer.new()
	dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dot_row.add_theme_constant_override("separation", 6)
	dot_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dot_row.offset_bottom = -32
	dot_row.offset_top    = -48
	dot_row.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(dot_row)

	for i in 3:
		var dot := PanelContainer.new()
		var w : float = 60.0 if i == active_dot else 24.0
		dot.custom_minimum_size = Vector2(w, 5)
		dot.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		var s := StyleBoxFlat.new()
		s.bg_color = Color(1, 1, 1, 1.0) if i == active_dot else Color(1, 1, 1, 0.35)
		s.set_corner_radius_all(8)
		dot.add_theme_stylebox_override("panel", s)
		dot_row.add_child(dot)

	# ── Next button ───────────────────────────────────────────────────────────
	var next := Label.new()
	next.text = "Next"
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	next.add_theme_font_size_override("font_size", 18)
	if pixel_font:
		next.add_theme_font_override("font", pixel_font)
	next.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	next.offset_right  = -28
	next.offset_left   = -110
	next.offset_bottom = -24
	next.offset_top    = -58
	next.mouse_filter  = Control.MOUSE_FILTER_STOP
	next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				ScreenTransition.go(NEXT_SCENE, "left")
	)
	add_child(next)

var _swipe_start_x : float = 0.0
var _swipe_started : bool  = false
const SWIPE_SLOP   : float = 12.0

func _input(event: InputEvent) -> void:
	if ScreenTransition._active:
		return
	if event is InputEventScreenTouch:
		var e : InputEventScreenTouch = event
		if e.pressed:
			_swipe_start_x = e.position.x
			_swipe_started = true
		else:
			_swipe_started = false
	elif event is InputEventMouseButton:
		var e : InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_swipe_start_x = e.position.x
				_swipe_started = true
			else:
				_swipe_started = false
	elif event is InputEventScreenDrag:
		var e : InputEventScreenDrag = event
		if _swipe_started:
			var dx : float = e.position.x - _swipe_start_x
			if absf(dx) > SWIPE_SLOP:
				_swipe_started = false
				if dx < 0.0:
					ScreenTransition.go(NEXT_SCENE, "left")
	elif event is InputEventMouseMotion:
		var e : InputEventMouseMotion = event
		if _swipe_started:
			var dx : float = e.position.x - _swipe_start_x
			if absf(dx) > SWIPE_SLOP:
				_swipe_started = false
				if dx < 0.0:
					ScreenTransition.go(NEXT_SCENE, "left")
