extends Control

# ── Scene constants ────────────────────────────────────────────────────────────
const LOGIN_SCENE        : String = "res://screens/login.tscn"
const CONCERT_ROOM_SCENE : String = "res://screens/concert_room.tscn"
const SETTINGS_SCENE     : String = "res://screens/settings.tscn"

# ── Room data ──────────────────────────────────────────────────────────────────
const ROOMS : Array[Dictionary] = [
	{
		"artist":     "BRUNO\nMARS",
		"genre":      "Pop / R&B",
		"crowd":      142,
		"door_color": Color(0.55, 0.30, 0.10),
		"bg_color1":  Color(0.55, 0.25, 0.05),
		"bg_color2":  Color(0.85, 0.45, 0.10),
		"char_color": Color(0.85, 0.65, 0.20),
		"accent":     Color(1.00, 0.65, 0.15),
	},
	{
		"artist":     "TAYLOR\nSWIFT",
		"genre":      "Pop",
		"crowd":      389,
		"door_color": Color(0.90, 0.35, 0.55),
		"bg_color1":  Color(0.55, 0.05, 0.25),
		"bg_color2":  Color(0.90, 0.30, 0.60),
		"char_color": Color(1.00, 0.80, 0.85),
		"accent":     Color(1.00, 0.55, 0.75),
	},
	{
		"artist":     "ARIANA\nGRANDE",
		"genre":      "Pop / R&B",
		"crowd":      274,
		"door_color": Color(0.55, 0.50, 0.80),
		"bg_color1":  Color(0.20, 0.05, 0.35),
		"bg_color2":  Color(0.55, 0.15, 0.75),
		"char_color": Color(0.80, 0.65, 1.00),
		"accent":     Color(0.75, 0.50, 1.00),
	},
	{
		"artist":     "CHAPPELL\nROAN",
		"genre":      "Pop",
		"crowd":      198,
		"door_color": Color(0.75, 0.38, 0.12),
		"bg_color1":  Color(0.50, 0.18, 0.04),
		"bg_color2":  Color(0.90, 0.45, 0.10),
		"char_color": Color(1.00, 0.75, 0.50),
		"accent":     Color(1.00, 0.55, 0.20),
	},
	{
		"artist":     "THE\nWEEKND",
		"genre":      "R&B",
		"crowd":      311,
		"door_color": Color(0.12, 0.12, 0.18),
		"bg_color1":  Color(0.08, 0.04, 0.20),
		"bg_color2":  Color(0.30, 0.10, 0.50),
		"char_color": Color(0.80, 0.70, 1.00),
		"accent":     Color(0.60, 0.30, 1.00),
	},
]

# ── Colors ─────────────────────────────────────────────────────────────────────
const C_TOPBAR  : Color = Color(0.06, 0.04, 0.14, 0.97)
const C_PINK    : Color = Color(0.96, 0.42, 0.62)
const C_PINK_HV : Color = Color(1.00, 0.60, 0.78)
const C_CREAM   : Color = Color(0.96, 0.91, 0.78)
const C_MUTED   : Color = Color(0.65, 0.65, 0.65)
const C_AVATAR  : Color = Color(0.25, 0.15, 0.35)
const C_DARK    : Color = Color(0.04, 0.03, 0.10)

# ── Carousel constants ─────────────────────────────────────────────────────────
const CARD_W      : float = 320.0
const CARD_H      : float = 200.0
const CARD_RADIUS : int   = 20
const SLIDE_DUR   : float = 0.38
const TOP_BAR_H   : float = 64.0

# ── Node paths ─────────────────────────────────────────────────────────────────
const _P_BG_TINT   : String = "BgTint"
const _P_BG_TEX    : String = "BgTexture"
const _P_STAGE     : String = "MainMargin/MainVBox/CarouselStage"
const _P_CARD_ROW  : String = "MainMargin/MainVBox/CarouselStage/CardRow"
const _P_BTN_PREV  : String = "MainMargin/MainVBox/NavRow/BtnPrev"
const _P_BTN_ENTER : String = "MainMargin/MainVBox/NavRow/BtnEnter"
const _P_BTN_NEXT  : String = "MainMargin/MainVBox/NavRow/BtnNext"
const _P_CHAR_DISP : String = "CharOverlay/CharDisplay"
const _P_TITLE     : String = "MainMargin/MainVBox/LabelTitle"

const SLOT_NAMES : Array[String] = [
	"Slot_BrunoMars",
	"Slot_TaylorSwift",
	"Slot_ArianaGrande",
	"Slot_ChappellRoan",
	"Slot_TheWeeknd",
]

# ── State ──────────────────────────────────────────────────────────────────────
var _current_idx  : int   = 0
var _is_animating : bool  = false
var _live_pulse_t : float = 0.0
var _bg_music     : AudioStreamPlayer = null

# ── Node refs ──────────────────────────────────────────────────────────────────
var _bg_texture      : TextureRect = null
var _bg_tint         : ColorRect   = null
var _card_row        : Control     = null
var _stage           : Control     = null
var _btn_prev        : Button      = null
var _btn_next        : Button      = null
var _btn_enter       : Button      = null
var _char_display    : TextureRect = null
var _topbar_avatar   : TextureRect = null
var _topbar_name_lbl : Label       = null

# Per-card refs
var _slot_labels   : Array[Label]     = []
var _slot_crowds   : Array[Label]     = []
var _slot_genres   : Array[Label]     = []
var _slot_bgs      : Array[ColorRect] = []
var _slot_doors    : Array[Control]   = []
var _slot_accents  : Array[Color]     = []
var _slot_cards    : Array[PanelContainer] = []
var _live_dots     : Array[ColorRect] = []

# Dot indicators
var _dot_indicators : Array[ColorRect] = []
var _dot_row        : HBoxContainer    = null

# Enter button glow ref
var _enter_glow_style : StyleBoxFlat = null

var _pixel_font : FontFile = null
var _body_font  : FontFile = null

# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	_pixel_font = load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	_body_font  = load("res://font/Montserrat/static/Montserrat-SemiBold.ttf") as FontFile
	
	# Hide the legacy TopBar node that exists in the .tscn but is unused —
	# home.gd builds its own top bar programmatically below.
	var legacy_topbar : Node = get_node_or_null("TopBar")
	if legacy_topbar:
		legacy_topbar.visible = false
	_cache_nodes()
	_connect_signals()
	_bind_slot_refs()
	_apply_fonts()
	_populate_cards()
	_show_character()
	_size_slots()
	_snap_row()
	_build_top_bar()
	_build_sidebar()
	_build_dot_indicators()
	_animate_enter_in()
	_setup_music()

# ── Sidebar UI ───────────────────────────────────────────────────────────────
func _build_sidebar() -> void:
	# Use a CanvasLayer to ensure the sidebar is always on top and receives input
	var layer := CanvasLayer.new()
	layer.name = "SidebarLayer"
	add_child(layer)
	
	var sidebar_container := Control.new()
	sidebar_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sidebar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sidebar_container)
	
	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 18)
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.5
	sidebar.anchor_bottom = 0.5
	sidebar.offset_left = -230 # Increased width slightly
	sidebar.offset_right = -20
	sidebar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sidebar.grow_vertical = Control.GROW_DIRECTION_BOTH
	sidebar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar_container.add_child(sidebar)
	
	# Semi-transparent background panel for the sidebar
	var panel := PanelContainer.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.08, 0.2, 0.6) # More opaque
	p_style.set_corner_radius_all(0)
	p_style.border_width_left = 4; p_style.border_color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.4)
	p_style.content_margin_left = 15; p_style.content_margin_right = 15
	p_style.content_margin_top = 20; p_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", p_style)
	sidebar.add_child(panel)
	
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 15)
	panel.add_child(btn_vbox)
	
	# Action buttons for the sidebar
	_add_sidebar_btn(btn_vbox, "✦ MINT NFT", func(): get_tree().change_scene_to_file("res://screens/nft_generation.tscn"), Color(0.98, 0.8, 0.1))
	_add_sidebar_btn(btn_vbox, "✦ VAULT", func(): get_tree().change_scene_to_file("res://screens/vault.tscn"), Color(0.96, 0.42, 0.62))
	
	var reward_btn = _add_sidebar_btn(btn_vbox, "✦ DAILY REWARD", _on_daily_login_pressed, Color(0.4, 0.9, 0.6))
	
	# Notification dot for daily reward
	if AuthManager.is_daily_reward_available():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = Color.RED
		dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -16; dot.offset_top = 2
		reward_btn.add_child(dot)
		
		# Pulse the dot
		var tw = create_tween().set_loops()
		tw.tween_property(dot, "modulate:a", 0.2, 0.6)
		tw.tween_property(dot, "modulate:a", 1.0, 0.6)

func _add_sidebar_btn(parent: Control, txt: String, callback: Callable, color: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(180, 50)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.2)
	style.border_width_left = 4; style.border_width_right = 4
	style.border_width_top = 4; style.border_width_bottom = 4
	style.border_color = color
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 0; style.shadow_offset = Vector2(8, 8)
	
	var hov = style.duplicate(); hov.bg_color = color
	var pre = style.duplicate(); pre.shadow_offset = Vector2(0, 0)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", pre)
	btn.add_theme_color_override("font_color", Color.WHITE)
	if _pixel_font: btn.add_theme_font_override("font", _pixel_font)
	
	btn.pressed.connect(func():
		print("[Home] Sidebar Button Pressed: ", txt)
		AudioManager.play("click")
		callback.call()
	)
	btn.mouse_entered.connect(func(): AudioManager.play("hover"))
	
	parent.add_child(btn)
	return btn

# ── Daily Login Reward UI ───────────────────────────────────────────────────
func _on_daily_login_pressed() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 300)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.08, 0.24)
	card_style.border_width_left = 6; card_style.border_width_right = 6
	card_style.border_width_top = 6; card_style.border_width_bottom = 6
	card_style.border_color = Color(0.98, 0.8, 0.1) # Gold
	card_style.set_corner_radius_all(0)
	card_style.shadow_color = Color(0, 0, 0, 1)
	card_style.shadow_size = 0; card_style.shadow_offset = Vector2(16, 16)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	card.add_child(vbox)
	
	var title := Label.new()
	title.text = "DAILY TRANSMISSION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.8, 0.1))
	if _pixel_font: title.add_theme_font_override("font", _pixel_font)
	vbox.add_child(title)
	
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _body_font: msg.add_theme_font_override("font", _body_font)
	vbox.add_child(msg)
	
	var claim_btn := Button.new()
	claim_btn.custom_minimum_size = Vector2(200, 60)
	if _pixel_font: claim_btn.add_theme_font_override("font", _pixel_font)
	vbox.add_child(claim_btn)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.set_corner_radius_all(0)
	
	var available = AuthManager.is_daily_reward_available()
	if available:
		msg.text = "Signal located! Claim your daily attendance reward of 1 credit."
		claim_btn.text = "CLAIM REWARD"
		btn_style.bg_color = Color(0.98, 0.8, 0.1)
		claim_btn.add_theme_stylebox_override("normal", btn_style)
		claim_btn.add_theme_color_override("font_color", Color.BLACK)
	else:
		msg.text = "Transmission complete for today. Return tomorrow for more credits."
		claim_btn.text = "CLOSE"
		btn_style.bg_color = Color(0.4, 0.4, 0.5)
		claim_btn.add_theme_stylebox_override("normal", btn_style)
	
	claim_btn.pressed.connect(func():
		if available:
			AuthManager.claim_daily_reward()
			UIUtils.show_toast("CREDIT CLAIMED!", Color.GOLD)
			AudioManager.play("reward")
		overlay.queue_free()
		get_tree().reload_current_scene()
	)

func _setup_music() -> void:
	_bg_music = AudioStreamPlayer.new()
	add_child(_bg_music)
	_bg_music.bus = "Music" # Optional: ensure you have a "Music" bus in your audio bus layout
	
	# Attempt to load a default track
	var track_path := "res://audio/home_music.mp3"
	if FileAccess.file_exists(track_path):
		var stream = load(track_path)
		if stream:
			_bg_music.stream = stream
			_bg_music.play()
			print("[Home] Background music started.")
	else:
		print("[Home] Background music file not found at: ", track_path)

func _process(delta: float) -> void:
	# Pulse live dots
	_live_pulse_t += delta * 2.2
	var alpha : float = 0.45 + 0.55 * (0.5 + 0.5 * sin(_live_pulse_t))
	for dot : ColorRect in _live_dots:
		if is_instance_valid(dot):
			dot.color = Color(0.25, 1.0, 0.45, alpha)

# ── Cache node refs ────────────────────────────────────────────────────────────
func _cache_nodes() -> void:
	_bg_texture   = get_node(_P_BG_TEX)   as TextureRect
	_bg_tint      = get_node(_P_BG_TINT)  as ColorRect
	_card_row     = get_node(_P_CARD_ROW) as Control
	_stage        = get_node(_P_STAGE)    as Control
	_btn_prev     = get_node(_P_BTN_PREV) as Button
	_btn_next     = get_node(_P_BTN_NEXT) as Button
	_btn_enter    = get_node(_P_BTN_ENTER) as Button
	_char_display = get_node(_P_CHAR_DISP) as TextureRect

	var main_margin : MarginContainer = get_node("MainMargin") as MarginContainer
	if main_margin:
		main_margin.offset_top = TOP_BAR_H

	assert(_card_row  != null, "home.gd: CardRow not found")
	assert(_stage     != null, "home.gd: CarouselStage not found")
	assert(_btn_prev  != null, "home.gd: BtnPrev not found")
	assert(_btn_enter != null, "home.gd: BtnEnter not found")
	assert(_btn_next  != null, "home.gd: BtnNext not found")

func _connect_signals() -> void:
	_btn_prev.pressed.connect(_go_prev)
	_btn_next.pressed.connect(_go_next)
	_btn_enter.pressed.connect(_on_enter_pressed)
	_style_nav_button(_btn_prev,  "◀")
	_style_nav_button(_btn_next,  "▶")
	_style_enter_button()

# ── Navigation button styling ──────────────────────────────────────────────────
func _style_nav_button(btn: Button, txt: String) -> void:
	btn.text = txt
	btn.custom_minimum_size = Vector2(52, 52)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn := _flat_style(Color(1, 1, 1, 0.08), 26)
	var sh := _flat_style(Color(1, 1, 1, 0.18), 26)
	var sp := _flat_style(Color(1, 1, 1, 0.06), 26)
	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_color_override("font_color", C_CREAM)
	btn.add_theme_font_size_override("font_size", 20)
	if _pixel_font:
		btn.add_theme_font_override("font", _pixel_font)

func _style_enter_button() -> void:
	if _btn_enter == null:
		return
	_btn_enter.text = "ENTER →"
	_btn_enter.custom_minimum_size = Vector2(180, 52)
	_btn_enter.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_enter_glow_style = StyleBoxFlat.new()
	_enter_glow_style.bg_color = C_PINK
	_enter_glow_style.set_corner_radius_all(0)
	_enter_glow_style.border_width_left   = 4
	_enter_glow_style.border_width_right  = 4
	_enter_glow_style.border_width_top    = 4
	_enter_glow_style.border_width_bottom = 4
	_enter_glow_style.border_color = Color(1, 1, 1, 0.8)
	_enter_glow_style.shadow_color = Color(0, 0, 0, 1.0)
	_enter_glow_style.shadow_size  = 0
	_enter_glow_style.shadow_offset = Vector2(4, 4)

	var sh := _enter_glow_style.duplicate() as StyleBoxFlat
	sh.bg_color = C_PINK_HV
	
	var sp := _enter_glow_style.duplicate() as StyleBoxFlat
	sp.bg_color = C_PINK.darkened(0.15)
	sp.shadow_offset = Vector2(0, 0)
	
	_btn_enter.add_theme_stylebox_override("normal",  _enter_glow_style)
	_btn_enter.add_theme_stylebox_override("hover",   sh)
	_btn_enter.add_theme_stylebox_override("pressed", sp)
	_btn_enter.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_btn_enter.add_theme_font_size_override("font_size", 20)
	if _pixel_font:
		_btn_enter.add_theme_font_override("font", _pixel_font)

# ── Dot indicators ─────────────────────────────────────────────────────────────
func _build_dot_indicators() -> void:
	var nav_row : Control = get_node("MainMargin/MainVBox/NavRow") as Control
	if nav_row == null:
		return
	_dot_row = HBoxContainer.new()
	_dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dot_row.add_theme_constant_override("separation", 10)
	_dot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_row.get_parent().add_child(_dot_row)
	nav_row.get_parent().move_child(_dot_row, nav_row.get_index() + 1)

	for i : int in ROOMS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dot_row.add_child(dot)
		_dot_indicators.append(dot)
	_update_dots()

# ── Update dot indicators ──────────────────────────────────────────────────────
func _update_dots() -> void:
	for i : int in _dot_indicators.size():
		var dot : ColorRect = _dot_indicators[i]
		if not is_instance_valid(dot):
			continue
		var t : Tween = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		if i == _current_idx:
			# Tween the full Vector2 — sub-property path "custom_minimum_size:x"
			# is not supported on Vector2 properties in Godot 4 and throws an error.
			t.tween_property(dot, "custom_minimum_size", Vector2(24.0, 8.0), 0.20)
			dot.color = _slot_accents[i] if i < _slot_accents.size() else C_PINK
		else:
			t.tween_property(dot, "custom_minimum_size", Vector2(8.0, 8.0), 0.20)
			dot.color = Color(1, 1, 1, 0.25)

# ── Enter button entrance animation ───────────────────────────────────────────
func _animate_enter_in() -> void:
	if _btn_enter == null:
		return
	_btn_enter.modulate.a = 0.0
	_btn_enter.scale      = Vector2(0.88, 0.88)
	var t : Tween = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property(_btn_enter, "modulate:a", 1.0, 0.45).set_delay(0.25)
	t.parallel().tween_property(_btn_enter, "scale", Vector2(1.0, 1.0), 0.45).set_delay(0.25)

# ── Build top bar ──────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.anchor_left   = 0.0
	bar.anchor_top    = 0.0
	bar.anchor_right  = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_top    = 0.0
	bar.offset_bottom = TOP_BAR_H
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = C_TOPBAR
	bar_style.border_width_bottom = 1
	bar_style.border_color        = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.25)
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	bar.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# ── Left: avatar + name ───────────────────────────────────────────────────
	var profile_btn := Button.new()
	profile_btn.flat = true
	profile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_btn.custom_minimum_size = Vector2(180, 56)
	
	# Add a transparent background to make the entire rect clickable
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(1, 1, 1, 0)
	profile_btn.add_theme_stylebox_override("normal", p_style)
	profile_btn.add_theme_stylebox_override("hover", p_style)
	profile_btn.add_theme_stylebox_override("pressed", p_style)
	profile_btn.add_theme_stylebox_override("focus", p_style)
	
	# Hover effect for profile
	profile_btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(profile_btn, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	)
	profile_btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(profile_btn, "modulate", Color(1.0, 1.0, 1.0), 0.1)
	)
	
	var profile_hbox := HBoxContainer.new()
	profile_hbox.add_theme_constant_override("separation", 8)
	profile_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_btn.add_child(profile_hbox)

	var av_panel := PanelContainer.new()
	av_panel.custom_minimum_size = Vector2(56, 56)
	av_panel.clip_contents = true
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = C_AVATAR
	av_style.set_corner_radius_all(0)
	av_style.border_width_left   = 3
	av_style.border_width_right  = 3
	av_style.border_width_top    = 3
	av_style.border_width_bottom = 3
	av_style.border_color = C_PINK
	av_panel.add_theme_stylebox_override("panel", av_style)
	profile_hbox.add_child(av_panel)

	_topbar_avatar = TextureRect.new()
	_topbar_avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_topbar_avatar.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_topbar_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_topbar_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topbar_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	av_panel.add_child(_topbar_avatar)
	_load_topbar_avatar()

	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 1)
	name_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	profile_hbox.add_child(name_vbox)

	_topbar_name_lbl = Label.new()
	_topbar_name_lbl.text = AuthManager.current_user.get("display_name", "Guest")
	_topbar_name_lbl.add_theme_color_override("font_color", C_CREAM)
	_topbar_name_lbl.add_theme_font_size_override("font_size", 16)
	if _pixel_font:
		_topbar_name_lbl.add_theme_font_override("font", _pixel_font)
	_topbar_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(_topbar_name_lbl)

	var tagline := Label.new()
	tagline.text = "Concert Fan 🎵"
	tagline.add_theme_color_override("font_color", C_MUTED)
	tagline.add_theme_font_size_override("font_size", 12)
	if _body_font:
		tagline.add_theme_font_override("font", _body_font)
	tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(tagline)

	profile_btn.pressed.connect(_on_profile_pressed)
	hbox.add_child(profile_btn)

	# ── Center: title ─────────────────────────────────────────────────────────
	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sp1)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 0)
	title_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "ConcerTopia"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", C_CREAM)
	title_lbl.add_theme_font_size_override("font_size", 22)
	if _pixel_font:
		title_lbl.add_theme_font_override("font", _pixel_font)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "choose your room"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.6))
	sub_lbl.add_theme_font_size_override("font_size", 11)
	if _pixel_font:
		sub_lbl.add_theme_font_override("font", _pixel_font)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_vbox.add_child(sub_lbl)

	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sp2)

	# ── Right: buttons ────────────────────────────────────────────────────────
	var right_hbox := HBoxContainer.new()
	right_hbox.add_theme_constant_override("separation", 6)
	right_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right_hbox)
	
	_add_topbar_credits_indicator(right_hbox)

	_add_topbar_icon_btn(right_hbox, "≡ SETTINGS", _on_settings_pressed)
	_add_topbar_icon_btn(right_hbox, "→ LOGOUT", _on_logout)

func _add_topbar_credits_indicator(parent: Control) -> void:
	var credits = AuthManager.current_user.get("avatar_credits", 0)
	
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.20, 0.8)
	style.set_corner_radius_all(15)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.92, 0.75, 0.48, 0.5) # Gold-ish
	badge.add_theme_stylebox_override("panel", style)
	badge.custom_minimum_size = Vector2(80, 36)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	badge.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)
	
	var lbl := Label.new()
	lbl.text = "Credits: %d" % credits
	lbl.add_theme_color_override("font_color", Color(0.92, 0.75, 0.48)) # Gold
	lbl.add_theme_font_size_override("font_size", 12)
	if _body_font:
		lbl.add_theme_font_override("font", _body_font)
	hbox.add_child(lbl)
	
	parent.add_child(badge)

func _add_topbar_btn(parent: Control, text: String, col: Color, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(col.r, col.g, col.b, 0.18)
	sn.set_corner_radius_all(10)
	sn.content_margin_left  = 10
	sn.content_margin_right = 10
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(col.r, col.g, col.b, 0.35)
	sh.set_corner_radius_all(10)
	sh.content_margin_left  = 10
	sh.content_margin_right = 10
	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sn)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_font_size_override("font_size", 12)
	if _pixel_font:
		btn.add_theme_font_override("font", _pixel_font)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_topbar_icon_btn(parent: Control, icon_text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = icon_text
	btn.flat = false
	btn.custom_minimum_size = Vector2(90, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var col := C_PINK
	var sn := _flat_style(Color(col.r, col.g, col.b, 0.15), 0)
	var sh := _flat_style(Color(col.r, col.g, col.b, 0.30), 0)
	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sn)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_font_size_override("font_size", 14)
	if _pixel_font:
		btn.add_theme_font_override("font", _pixel_font)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _load_topbar_avatar() -> void:
	if _topbar_avatar == null:
		return
	
	var default_tex = load("res://icons/user.png") as Texture2D
	_topbar_avatar.texture = default_tex
	
	var avatar_url = AuthManager.current_user.get("avatar_url", "")
	
	# If we have a local file from a recent generation, use it
	if FileAccess.file_exists("user://avatar.png"):
		var image = Image.new()
		var err = image.load("user://avatar.png")
		if err == OK:
			_topbar_avatar.texture = ImageTexture.create_from_image(image)
			return
			
	# If we have a URL but no local file (e.g. fresh login), download it
	if not avatar_url.is_empty():
		var http = HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(func(res: int, code: int, hdrs: PackedStringArray, body: PackedByteArray):
			if code >= 200 and code < 300:
				var image = Image.new()
				var err = image.load_jpg_from_buffer(body)
				if err != OK: err = image.load_png_from_buffer(body)
				if err != OK: err = image.load_webp_from_buffer(body)
				
				if err == OK:
					_topbar_avatar.texture = ImageTexture.create_from_image(image)
					image.save_png("user://avatar.png")
			http.queue_free()
		)
		http.request(avatar_url)

# ── Bind slot refs ─────────────────────────────────────────────────────────────
func _bind_slot_refs() -> void:
	for slot_name : String in SLOT_NAMES:
		var base  : String = _P_CARD_ROW + "/" + slot_name
		var right : String = base + "/Card/CardHBox/RightArea"
		_slot_labels.append(get_node(right + "/LabelArtist") as Label)
		_slot_crowds.append(get_node(right + "/CrowdBadge/BadgeHBox/LabelCrowd") as Label)
		_slot_bgs.append(get_node(right + "/BokehBg") as ColorRect)
		_slot_doors.append(get_node(base + "/Card/CardHBox/DoorPanel") as Control)
		# Genre label — create if missing
		var genre_lbl := Label.new()
		genre_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		genre_lbl.add_theme_font_size_override("font_size", 10)
		if _body_font:
			genre_lbl.add_theme_font_override("font", _body_font)
		genre_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var right_node : Control = get_node(right) as Control
		if right_node:
			right_node.add_child(genre_lbl)
		_slot_genres.append(genre_lbl)
		# Live dot
		var live_dot := ColorRect.new()
		live_dot.custom_minimum_size = Vector2(8, 8)
		live_dot.color = Color(0.25, 1.0, 0.45)
		live_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if right_node:
			right_node.add_child(live_dot)
		_live_dots.append(live_dot)

func _apply_fonts() -> void:
	if _pixel_font == null:
		return
	for lbl : Label in _slot_labels:
		if lbl:
			lbl.add_theme_font_override("font", _pixel_font)
	for lbl : Label in _slot_crowds:
		if lbl:
			lbl.add_theme_font_override("font", _pixel_font)
	_btn_prev.add_theme_font_override("font",  _pixel_font)
	_btn_next.add_theme_font_override("font",  _pixel_font)
	_btn_enter.add_theme_font_override("font", _pixel_font)
	var title : Label = get_node(_P_TITLE) as Label
	if title:
		title.add_theme_font_override("font", _pixel_font)

func _populate_cards() -> void:
	_slot_accents.clear()
	for i : int in ROOMS.size():
		var data : Dictionary = ROOMS[i]
		if _slot_labels[i]:
			_slot_labels[i].text = data["artist"]
		if _slot_crowds[i]:
			_slot_crowds[i].text = str(data["crowd"])
		if _slot_bgs[i]:
			_slot_bgs[i].color = data["bg_color1"]
		if _slot_genres[i]:
			_slot_genres[i].text = data["genre"].to_upper()
		_slot_accents.append(data["accent"])
		_style_door(_slot_doors[i], data["door_color"], data["accent"])
		_style_card_panel(i, data)

func _style_card_panel(idx: int, data: Dictionary) -> void:
	var card_path : String = _P_CARD_ROW + "/" + SLOT_NAMES[idx] + "/Card"
	var card : PanelContainer = get_node(card_path) as PanelContainer
	if card == null:
		return
	_slot_cards.append(card)
	var bg     : Color = data["bg_color1"]
	var accent : Color = data["accent"]
	var style  : StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg.darkened(0.15)
	style.set_corner_radius_all(0)
	style.border_width_left   = 4
	style.border_width_right  = 4
	style.border_width_top    = 4
	style.border_width_bottom = 4
	style.border_color = accent
	style.shadow_color = Color(0, 0, 0, 1.0)
	style.shadow_size  = 0
	style.shadow_offset = Vector2(8, 8)
	card.add_theme_stylebox_override("panel", style)

	# Interactive Hover effects
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.mouse_entered.connect(func():
		AudioManager.play("hover")
		var tw = create_tween().set_parallel(true)
		tw.tween_property(card, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_SINE)
		tw.tween_property(card, "rotation_degrees", 1.0, 0.15)
		var s = card.get_theme_stylebox("panel") as StyleBoxFlat
		tw.tween_property(s, "shadow_offset", Vector2(12, 12), 0.15)
	)
	card.mouse_exited.connect(func():
		var tw = create_tween().set_parallel(true)
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
		tw.tween_property(card, "rotation_degrees", 0.0, 0.15)
		var s = card.get_theme_stylebox("panel") as StyleBoxFlat
		tw.tween_property(s, "shadow_offset", Vector2(8, 8), 0.15)
	)
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			if idx == _current_idx:
				_on_enter_pressed()
			else:
				_navigate(idx - _current_idx)
	)

func _style_door(door: Control, col: Color, accent: Color) -> void:
	if door == null:
		return
	for c : Node in door.get_children():
		c.queue_free()

	var door_bg := ColorRect.new()
	door_bg.color = col.darkened(0.35)
	door_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	door_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(door_bg)

	var frame := ColorRect.new()
	frame.color = col.lightened(0.12)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left   =  6.0
	frame.offset_right  = -6.0
	frame.offset_top    = 10.0
	frame.offset_bottom = -6.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(frame)

	var fill := ColorRect.new()
	fill.color = col
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.offset_left   = 10.0
	fill.offset_right  = -10.0
	fill.offset_top    = 14.0
	fill.offset_bottom = -10.0
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(fill)

	for i : int in 3:
		var stripe := ColorRect.new()
		stripe.color = col.darkened(0.22)
		stripe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var y_off : float = 18.0 + float(i) * 26.0
		stripe.offset_left   = 12.0
		stripe.offset_right  = -12.0
		stripe.offset_top    = y_off
		stripe.offset_bottom = y_off + 16.0
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		door.add_child(stripe)

	var glow_strip := ColorRect.new()
	glow_strip.color = Color(accent.r, accent.g, accent.b, 0.55)
	glow_strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow_strip.offset_left   =  6.0
	glow_strip.offset_right  = -6.0
	glow_strip.offset_top    =  6.0
	glow_strip.offset_bottom = 12.0
	glow_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(glow_strip)

	var knob := ColorRect.new()
	knob.color = Color(1.0, 0.85, 0.3)
	knob.custom_minimum_size = Vector2(7, 7)
	knob.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	knob.offset_right  = -16.0
	knob.offset_left   = -23.0
	knob.offset_top    =  3.0
	knob.offset_bottom = 10.0
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(knob)

func _show_character() -> void:
	if _char_display == null:
		return
	_char_display.texture = null
	_char_display.visible = false

func _size_slots() -> void:
	if _stage == null or _card_row == null:
		return
	var vp_w : float = get_viewport().get_visible_rect().size.x
	var vp_h : float = _stage.size.y
	for i : int in SLOT_NAMES.size():
		var slot_path : String = _P_CARD_ROW + "/" + SLOT_NAMES[i]
		var slot : Control = get_node(slot_path) as Control
		if slot == null:
			continue
		slot.position = Vector2(float(i) * vp_w, 0.0)
		slot.size     = Vector2(vp_w, vp_h)
		var card : PanelContainer = get_node(slot_path + "/Card") as PanelContainer
		if card == null:
			continue
		card.position = Vector2((vp_w - CARD_W) / 2.0, (vp_h - CARD_H) / 2.0)
	_card_row.size = Vector2(float(SLOT_NAMES.size()) * vp_w, vp_h)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_size_slots()
		_snap_row()

# ── Navigation ─────────────────────────────────────────────────────────────────
func _go_prev() -> void:
	_navigate(-1)

func _go_next() -> void:
	_navigate(1)

func _navigate(dir: int) -> void:
	if _is_animating:
		return
	var next : int = _current_idx + dir
	if next < 0 or next >= ROOMS.size():
		_bounce_card(dir)
		return
	_current_idx  = next
	_is_animating = true
	_slide_row()
	_update_dots()
	_update_enter_accent()

func _snap_row() -> void:
	if _card_row == null:
		return
	_card_row.position.x = _row_target_x()

func _slide_row() -> void:
	var target_x : float = _row_target_x()
	var t : Tween = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_card_row, "position:x", target_x, SLIDE_DUR)
	t.finished.connect(func() -> void: _is_animating = false)

func _row_target_x() -> float:
	var vp_w : float = get_viewport().get_visible_rect().size.x
	return -float(_current_idx) * vp_w

func _bounce_card(dir: int) -> void:
	var t : Tween = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	var nudge : float = float(dir) * -22.0
	var base  : float = _row_target_x()
	t.tween_property(_card_row, "position:x", base + nudge, 0.10)
	t.tween_property(_card_row, "position:x", base, 0.20)

# ── Update enter button accent tint when room changes ─────────────────────────
func _update_enter_accent() -> void:
	if _enter_glow_style == null:
		return
	var accent : Color = ROOMS[_current_idx]["accent"]
	var t : Tween = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_method(
		func(c: Color) -> void: _enter_glow_style.bg_color = c,
		_enter_glow_style.bg_color,
		accent,
		0.30
	)

# ── Swipe input ────────────────────────────────────────────────────────────────
var _swipe_start_x    : float = 0.0
var _swipe_active     : bool  = false
const SWIPE_THRESHOLD : float = 40.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e : InputEventScreenTouch = event as InputEventScreenTouch
		if e.pressed:
			_swipe_start_x = e.position.x
			_swipe_active  = true
		else:
			_swipe_active = false
	elif event is InputEventScreenDrag:
		if not _swipe_active:
			return
		var e : InputEventScreenDrag = event as InputEventScreenDrag
		var delta : float = e.position.x - _swipe_start_x
		if absf(delta) > SWIPE_THRESHOLD:
			_swipe_active = false
			if delta < 0.0:
				_go_next()
			else:
				_go_prev()

# ── Helpers ────────────────────────────────────────────────────────────────────
func _flat_style(col: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	if radius > 0:
		s.set_corner_radius_all(radius)
	return s

# ── Top bar actions ────────────────────────────────────────────────────────────
func _on_profile_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://screens/user_profile.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(SETTINGS_SCENE)

func _on_logout() -> void:
	AuthManager.logout()
	get_tree().change_scene_to_file.call_deferred(LOGIN_SCENE)

func _on_enter_pressed() -> void:
	# Quick punch animation before entering
	var t : Tween = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property(_btn_enter, "scale", Vector2(0.92, 0.92), 0.08)
	t.tween_property(_btn_enter, "scale", Vector2(1.0, 1.0),   0.12)
	await t.finished
	RoomRegistry.set_room_by_index(_current_idx)
	get_tree().change_scene_to_file.call_deferred(CONCERT_ROOM_SCENE)
