extends Control

const LOGIN_SCENE        : String = "res://screens/login.tscn"
const PREV_SCENE         : String = "res://screens/welcome_screen2.tscn"
const WELCOME_BACK_SCENE : String = "res://screens/welcome_back.tscn"
const CHAR_SEL_SCENE     : String = "res://screens/character_select.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var pixel_font := load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var centre := VBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 14)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.offset_left   = 40
	centre.offset_right  = -40
	centre.offset_top    = 20
	centre.offset_bottom = -64
	centre.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	var logo := Label.new()
	logo.text = "ConcerTopia"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_color", Color(1, 1, 1))
	logo.add_theme_font_size_override("font_size", 46)
	if pixel_font:
		logo.add_theme_font_override("font", pixel_font)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(logo)

	var heading := Label.new()
	heading.text = "Let's Get You on\nStage!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	heading.add_theme_font_size_override("font_size", 26)
	if pixel_font:
		heading.add_theme_font_override("font", pixel_font)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(heading)

	var body := Label.new()
	body.text = "\"Step into a new world of music! Choose your\nfavorite artist, enjoy random tracks, and connect\nwith fans worldwide - all in vibrant pixel art.\""
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color(1, 1, 1))
	body.add_theme_font_size_override("font_size", 14)
	if pixel_font:
		body.add_theme_font_override("font", pixel_font)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(body)

	_build_bottom_bar(pixel_font, 2)

func _build_bottom_bar(pixel_font: FontFile, active_dot: int) -> void:
	var dot_row := HBoxContainer.new()
	dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dot_row.add_theme_constant_override("separation", 8)
	dot_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dot_row.offset_bottom = -28
	dot_row.offset_top    = -52
	dot_row.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(dot_row)

	for i in 3:
		var dot := PanelContainer.new()
		var w : float = 28.0 if i == active_dot else 10.0
		dot.custom_minimum_size = Vector2(w, 10)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := StyleBoxFlat.new()
		s.bg_color = Color(1, 1, 1, 1.0) if i == active_dot else Color(1, 1, 1, 0.4)
		s.set_corner_radius_all(6)
		dot.add_theme_stylebox_override("panel", s)
		dot_row.add_child(dot)

	var prev := Label.new()
	prev.text = "Prev"
	prev.add_theme_color_override("font_color", Color(1, 1, 1))
	prev.add_theme_font_size_override("font_size", 18)
	if pixel_font:
		prev.add_theme_font_override("font", pixel_font)
	prev.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	prev.offset_left   = 28
	prev.offset_right  = 120
	prev.offset_bottom = -24
	prev.offset_top    = -58
	prev.mouse_filter  = Control.MOUSE_FILTER_STOP
	prev.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			ScreenTransition.go(PREV_SCENE, "right")
	)
	add_child(prev)

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
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_advance()
	)
	add_child(next)

func _advance() -> void:
	if AuthManager.post_login_intro:
		AuthManager.post_login_intro = false
		if AuthManager.needs_character_select:
			ScreenTransition.go(CHAR_SEL_SCENE, "left")
		else:
			ScreenTransition.go(WELCOME_BACK_SCENE, "left")
	else:
		FirstLaunch.mark_onboarding_complete()
		ScreenTransition.go(LOGIN_SCENE, "left")

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
					_advance()
				else:
					ScreenTransition.go(PREV_SCENE, "right")

	elif event is InputEventMouseMotion:
		var e : InputEventMouseMotion = event
		if _swipe_started:
			var dx : float = e.position.x - _swipe_start_x
			if absf(dx) > SWIPE_SLOP:
				_swipe_started = false
				if dx < 0.0:
					_advance()
				else:
					ScreenTransition.go(PREV_SCENE, "right")
