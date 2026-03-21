extends Control

const HOME_SCENE := "res://screens/home.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var pixel_font := load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile

	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Centre VBox ───────────────────────────────────────────────────────────
	var centre := VBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 16)
	centre.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	centre.offset_left   = -260
	centre.offset_right  =  260
	centre.offset_top    = -120
	centre.offset_bottom =  120
	centre.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	# "Welcome to" — pink
	var welcome_lbl := Label.new()
	welcome_lbl.name = "WelcomeLabel"
	welcome_lbl.text = "Welcome to"
	welcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_lbl.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	welcome_lbl.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		welcome_lbl.add_theme_font_override("font", pixel_font)
	welcome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	welcome_lbl.modulate.a = 0.0
	centre.add_child(welcome_lbl)

	# "ConcerTopia" — white large
	var logo_lbl := Label.new()
	logo_lbl.name = "LogoLabel"
	logo_lbl.text = "ConcerTopia"
	logo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	logo_lbl.add_theme_font_size_override("font_size", 52)
	if pixel_font:
		logo_lbl.add_theme_font_override("font", pixel_font)
	logo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_lbl.modulate.a = 0.0
	centre.add_child(logo_lbl)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(sp)

	# "Hey, [name]!" — white
	var user: Dictionary = AuthManager.current_user
	var name_str: String = user.get("display_name", "there")
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Hey, %s!" % name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	name_lbl.add_theme_font_size_override("font_size", 28)
	if pixel_font:
		name_lbl.add_theme_font_override("font", pixel_font)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.modulate.a = 0.0
	centre.add_child(name_lbl)

	# "Ready to rock?" — pink subtitle
	var sub_lbl := Label.new()
	sub_lbl.name = "SubLabel"
	sub_lbl.text = "Ready to rock? 🎵"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	sub_lbl.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		sub_lbl.add_theme_font_override("font", pixel_font)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_lbl.modulate.a = 0.0
	centre.add_child(sub_lbl)

	# ── Tap to skip hint ──────────────────────────────────────────────────────
	var skip_lbl := Label.new()
	skip_lbl.name = "SkipLabel"
	skip_lbl.text = "Tap anywhere to continue"
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	skip_lbl.add_theme_font_size_override("font_size", 12)
	if pixel_font:
		skip_lbl.add_theme_font_override("font", pixel_font)
	skip_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	skip_lbl.offset_bottom = -28
	skip_lbl.offset_top    = -56
	skip_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	skip_lbl.modulate.a    = 0.0
	add_child(skip_lbl)

	# ── Animate in sequence ───────────────────────────────────────────────────
	_animate_in(welcome_lbl, logo_lbl, name_lbl, sub_lbl, skip_lbl)

	# ── Tap anywhere to skip to home ──────────────────────────────────────────
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_go_home()
	)

func _animate_in(
	welcome_lbl: Label,
	logo_lbl: Label,
	name_lbl: Label,
	sub_lbl: Label,
	skip_lbl: Label
) -> void:
	# Staggered fade-in: each element fades in 0.4s, 0.2s apart
	var t := create_tween()
	t.set_parallel(false)

	# "Welcome to" fades in
	t.tween_property(welcome_lbl, "modulate:a", 1.0, 0.4)
	# "ConcerTopia" fades in
	t.tween_property(logo_lbl, "modulate:a", 1.0, 0.4)
	# Brief pause
	t.tween_interval(0.1)
	# "Hey, [name]!" fades in
	t.tween_property(name_lbl, "modulate:a", 1.0, 0.4)
	# "Ready to rock?" fades in
	t.tween_property(sub_lbl, "modulate:a", 1.0, 0.35)
	# Skip hint fades in softly
	t.tween_property(skip_lbl, "modulate:a", 1.0, 0.3)
	# Hold for 1.5s then auto-navigate
	t.tween_interval(1.5)
	t.tween_callback(_go_home)

func _go_home() -> void:
	# Fade everything out then switch scene
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file.call_deferred(HOME_SCENE)
	)
