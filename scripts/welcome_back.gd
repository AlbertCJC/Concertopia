extends Control

const HOME_SCENE      : String = "res://screens/home.tscn"

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var pixel_font := load(
		"res://Pixelify_Sans/static/PixelifySans-Bold.ttf"
	) as FontFile

	var bg := ColorRect.new()
	bg.color        = Color(0.04, 0.03, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	var grid := TextureRect.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.stretch_mode = TextureRect.STRETCH_TILE
	grid.modulate.a = 0.05
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE); img.set_pixel(1, 1, Color.WHITE)
	grid.texture = ImageTexture.create_from_image(img)
	add_child(grid)

	var centre := VBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 16)
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.offset_left   = -260
	centre.offset_right  =  260
	centre.offset_top    = -120
	centre.offset_bottom =  120
	centre.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	var welcome_lbl := Label.new()
	welcome_lbl.text = "Welcome to"
	welcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_lbl.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	welcome_lbl.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		welcome_lbl.add_theme_font_override("font", pixel_font)
	welcome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	welcome_lbl.modulate.a   = 0.0
	centre.add_child(welcome_lbl)

	var logo_lbl := Label.new()
	logo_lbl.text = "ConcerTopia"
	logo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	logo_lbl.add_theme_font_size_override("font_size", 52)
	if pixel_font:
		logo_lbl.add_theme_font_override("font", pixel_font)
	logo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_lbl.modulate.a   = 0.0
	centre.add_child(logo_lbl)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	sp.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	centre.add_child(sp)

	var user : Dictionary = AuthManager.current_user
	var name_str : String = user.get("display_name", "there")
	var name_lbl := Label.new()
	name_lbl.text = "Hey, %s!" % name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	name_lbl.add_theme_font_size_override("font_size", 28)
	if pixel_font:
		name_lbl.add_theme_font_override("font", pixel_font)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.modulate.a   = 0.0
	centre.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Ready to rock? 🎵"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(0.96, 0.42, 0.62))
	sub_lbl.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		sub_lbl.add_theme_font_override("font", pixel_font)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_lbl.modulate.a   = 0.0
	centre.add_child(sub_lbl)

	var skip_lbl := Label.new()
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

	_animate_in(welcome_lbl, logo_lbl, name_lbl, sub_lbl, skip_lbl)

	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_proceed()
	)

func _animate_in(
	welcome_lbl : Label,
	logo_lbl    : Label,
	name_lbl    : Label,
	sub_lbl     : Label,
	skip_lbl    : Label
) -> void:
	var t := create_tween()
	t.set_parallel(false)
	t.tween_property(welcome_lbl, "modulate:a", 1.0, 0.4)
	t.tween_property(logo_lbl,    "modulate:a", 1.0, 0.4)
	t.tween_interval(0.1)
	t.tween_property(name_lbl,    "modulate:a", 1.0, 0.4)
	t.tween_property(sub_lbl,     "modulate:a", 1.0, 0.35)
	t.tween_property(skip_lbl,    "modulate:a", 1.0, 0.3)
	t.tween_interval(1.5)
	t.tween_callback(_proceed)

var _proceeding : bool = false

func _proceed() -> void:
	if _proceeding:
		return
	_proceeding = true
	get_tree().change_scene_to_file.call_deferred(HOME_SCENE)
