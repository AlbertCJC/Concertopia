extends Control
# Character skin/variant selection screen.
# Sprite sheet: 711×351 — 3 columns, each 237×351.
# Frame 0 (x=0) = UI_CHARACTER_SELECT portrait.
# Selected character slides to centre — same technique as character_select.gd

const WELCOME_BACK_SCENE : String = "res://screens/welcome_back.tscn"
const BASE_PATH          : String = "res://characterpreset/characterselect/"

const SCALE_NORMAL   := Vector2(1.0, 1.0)
const SCALE_SELECTED := Vector2(1.2, 1.2)

const FRAME_X : int = 0
const FRAME_Y : int = 0
const FRAME_W : int = 237
const FRAME_H : int = 351

const SLOT_W   : float = 130.0
const SLOT_H   : float = 193.0
const SLOT_SEP : float = 36.0   # slightly more breathing room between slots

# Animation durations — longer for smoother feel
const DUR_SLIDE  : float = 0.45   # row slide to centre
const DUR_SCALE  : float = 0.35   # zoom in/out
const DUR_SHADOW : float = 0.30   # shadow fade
const DUR_LABEL  : float = 0.25   # label brightness

var _slots    : Array[Control] = []
var _selected : int = 0
var _row      : HBoxContainer = null   # positioned manually for sliding

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var pixel_font := load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	var base       : String = AuthManager.get_selected_base()
	var prefix     : String = "boy_" if base == "male" else "girl_"

	# ── Background ────────────────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "Pick Your Style"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_font_size_override("font_size", 30)
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top    = 52
	title.offset_bottom = 100
	title.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# ── Row — positioned manually so we can tween it ──────────────────────────
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", int(SLOT_SEP))
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)

	# ── 5 variant slots ───────────────────────────────────────────────────────
	for i in 5:
		var tex_path : String = BASE_PATH + prefix + str(i + 1) + ".png"
		var label    : String = base.capitalize() + " " + str(i + 1)
		var slot     : Control = _make_slot(tex_path, i, label, pixel_font)
		_row.add_child(slot)
		_slots.append(slot)

	# ── CONFIRM button ────────────────────────────────────────────────────────
	var confirm_button := Button.new()
	confirm_button.text = "CONFIRM"
	confirm_button.custom_minimum_size = Vector2(200, 50)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.96, 0.57, 0.72)
	btn_normal.set_corner_radius_all(25)
	btn_normal.content_margin_left   = 20
	btn_normal.content_margin_right  = 20
	btn_normal.content_margin_top    = 12
	btn_normal.content_margin_bottom = 12

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(1.0, 0.67, 0.80)
	btn_hover.set_corner_radius_all(25)
	btn_hover.content_margin_left   = 20
	btn_hover.content_margin_right  = 20
	btn_hover.content_margin_top    = 12
	btn_hover.content_margin_bottom = 12

	confirm_button.add_theme_stylebox_override("normal",  btn_normal)
	confirm_button.add_theme_stylebox_override("hover",   btn_hover)
	confirm_button.add_theme_stylebox_override("pressed", btn_normal)
	confirm_button.add_theme_color_override("font_color", Color(1, 1, 1))
	confirm_button.add_theme_font_size_override("font_size", 17)
	if pixel_font:
		confirm_button.add_theme_font_override("font", pixel_font)

	confirm_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	confirm_button.offset_top    = -90
	confirm_button.offset_bottom = -36
	confirm_button.offset_left   = 90
	confirm_button.offset_right  = -90
	confirm_button.pressed.connect(_on_confirm_pressed)
	add_child(confirm_button)

	# Wait one frame for layout sizes to be valid, then snap
	await get_tree().process_frame
	_apply_selection(false)

# ── Build one slot ─────────────────────────────────────────────────────────────

func _make_slot(texture_path: String, idx: int, label_text: String, pixel_font: FontFile) -> Control:
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var container := Control.new()
	container.name = "Slot"
	container.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(container)

	# Oval shadow
	var shadow := PanelContainer.new()
	shadow.name = "Shadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	shadow.offset_bottom = -2
	shadow.offset_top    = -18
	shadow.offset_left   = 4
	shadow.offset_right  = -4
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.05, 0.05, 0.05, 0.0)
	shadow_style.corner_radius_top_left     = 50
	shadow_style.corner_radius_top_right    = 50
	shadow_style.corner_radius_bottom_left  = 50
	shadow_style.corner_radius_bottom_right = 50
	shadow.add_theme_stylebox_override("panel", shadow_style)
	container.add_child(shadow)

	# Sprite wrapper — pivot at bottom-centre for zoom
	var sprite_wrap := Control.new()
	sprite_wrap.name = "SpriteWrap"
	sprite_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite_wrap.offset_bottom = -16
	sprite_wrap.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	sprite_wrap.pivot_offset  = Vector2(SLOT_W / 2.0, SLOT_H * 0.9)
	container.add_child(sprite_wrap)

	# AtlasTexture — first frame (UI_CHARACTER_SELECT region)
	var base_tex : Texture2D = load(texture_path) as Texture2D
	var atlas    := AtlasTexture.new()
	atlas.atlas       = base_tex
	atlas.region      = Rect2(FRAME_X, FRAME_Y, FRAME_W, FRAME_H)
	atlas.filter_clip = true

	var tex_rect := TextureRect.new()
	tex_rect.texture      = atlas
	tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_wrap.add_child(tex_rect)

	# Label below
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = label_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 14)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	container.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _selected != idx:
				_selected = idx
				_apply_selection(true)
	)

	return vbox

# ── Slide row so selected slot is centred on screen ───────────────────────────

func _slide_to_selected(animate: bool) -> void:
	if _row == null:
		return

	var screen_w  : float = get_viewport().get_visible_rect().size.x
	var screen_h  : float = get_viewport().get_visible_rect().size.y
	var screen_cx : float = screen_w / 2.0

	# Centre x of the selected slot within the row
	var slot_step : float = SLOT_W + SLOT_SEP
	var slot_cx   : float = float(_selected) * slot_step + SLOT_W / 2.0

	# Row x so slot_cx lands on screen_cx
	var target_x  : float = screen_cx - slot_cx

	# Vertical — centre of usable area (below title, above confirm button)
	var row_h     : float = _row.size.y
	var top_area  : float = 100.0   # title height
	var bot_area  : float = 110.0   # confirm button area
	var target_y  : float = top_area + (screen_h - top_area - bot_area - row_h) / 2.0

	if animate:
		var t := create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(_row, "position", Vector2(target_x, target_y), DUR_SLIDE)
	else:
		_row.position = Vector2(target_x, target_y)

# ── Apply all visual states ────────────────────────────────────────────────────

func _apply_selection(animate: bool) -> void:
	for i in _slots.size():
		_animate_slot(_slots[i], i == _selected, animate)
	_slide_to_selected(animate)

func _animate_slot(vbox: Control, is_selected: bool, animate: bool) -> void:
	var container   := vbox.get_node_or_null("Slot") as Control
	if container == null:
		return
	var sprite_wrap := container.get_node_or_null("SpriteWrap") as Control
	var shadow      := container.get_node_or_null("Shadow") as PanelContainer
	var name_label  := vbox.get_node_or_null("NameLabel") as Label

	# ── Scale zoom ────────────────────────────────────────────────────────────
	if sprite_wrap:
		var target_scale : Vector2 = SCALE_SELECTED if is_selected else SCALE_NORMAL
		if animate:
			var t := create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_BACK)
			t.tween_property(sprite_wrap, "scale", target_scale, DUR_SCALE)
		else:
			sprite_wrap.scale = target_scale

	# ── Shadow ────────────────────────────────────────────────────────────────
	if shadow:
		var style := shadow.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			var target_alpha : float = 0.55 if is_selected else 0.20
			var target_left  : float = -10.0 if is_selected else 4.0
			var target_right : float =  10.0 if is_selected else -4.0
			if animate:
				var from_alpha : float = style.bg_color.a
				var from_left  : float = shadow.offset_left
				var from_right : float = shadow.offset_right
				var t2 := create_tween()
				t2.set_parallel(true)
				t2.tween_method(func(a: float) -> void:
					style.bg_color = Color(0.05, 0.05, 0.05, a)
				, from_alpha, target_alpha, DUR_SHADOW)
				t2.tween_method(func(v: float) -> void:
					shadow.offset_left = v
				, from_left, target_left, DUR_SHADOW)
				t2.tween_method(func(v: float) -> void:
					shadow.offset_right = v
				, from_right, target_right, DUR_SHADOW)
			else:
				style.bg_color      = Color(0.05, 0.05, 0.05, target_alpha)
				shadow.offset_left  = target_left
				shadow.offset_right = target_right

	# ── Label brightness ──────────────────────────────────────────────────────
	if name_label:
		var target_color : Color = Color(1, 1, 1, 1.0) if is_selected else Color(1, 1, 1, 0.40)
		if animate:
			var t3 := create_tween()
			t3.set_ease(Tween.EASE_OUT)
			t3.set_trans(Tween.TRANS_SINE)
			t3.tween_property(name_label, "modulate", target_color, DUR_LABEL)
		else:
			name_label.modulate = target_color

func _on_confirm_pressed() -> void:
	var base   : String = AuthManager.get_selected_base()
	var prefix : String = "boy_" if base == "male" else "girl_"
	var skin   : String = BASE_PATH + prefix + str(_selected + 1) + ".png"
	AuthManager.mark_skin_selected(skin)
	get_tree().change_scene_to_file.call_deferred(WELCOME_BACK_SCENE)
