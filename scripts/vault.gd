extends Control

const HOME_SCENE = "res://screens/home.tscn"

# Colors
const C_BG      : Color = Color(0.04, 0.03, 0.10)
const C_PANEL   : Color = Color(0.12, 0.08, 0.24)
const C_PINK    : Color = Color(0.96, 0.42, 0.62)
const C_GOLD    : Color = Color(0.98, 0.8, 0.1)
const C_CREAM   : Color = Color(0.96, 0.91, 0.78)
const C_MUTED   : Color = Color(0.55, 0.55, 0.65)

var pixel_font : FontFile
var body_font  : FontFile

var grid_container : GridContainer
var av_tab_btn : Button
var nft_tab_btn : Button

func _ready() -> void:
	pixel_font = load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	body_font  = load("res://font/Montserrat/static/Montserrat-SemiBold.ttf") as FontFile
	
	if AuthManager.current_user.is_empty():
		print("[Vault] Warning: No current user data found.")
		
	_build_ui()
	_load_avatars()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
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
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "THE VAULT"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", C_PINK)
	if pixel_font: title.add_theme_font_override("font", pixel_font)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var back_btn := _styled_button("BACK TO HOME", C_CREAM, Color.BLACK)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file(HOME_SCENE))
	header.add_child(back_btn)

	# Tab Selection
	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 25)
	vbox.add_child(tab_hbox)

	av_tab_btn = _styled_button("MY AVATARS", C_PINK, Color.WHITE)
	av_tab_btn.pressed.connect(_load_avatars)
	tab_hbox.add_child(av_tab_btn)

	nft_tab_btn = _styled_button("MY NFTS", C_GOLD, Color.BLACK)
	nft_tab_btn.pressed.connect(_load_nfts)
	tab_hbox.add_child(nft_tab_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0, 0, 0, 0.2)
	s_style.border_width_left = 4; s_style.border_color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.1)
	scroll.add_theme_stylebox_override("panel", s_style)
	vbox.add_child(scroll)

	grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.add_theme_constant_override("h_separation", 35)
	grid_container.add_theme_constant_override("v_separation", 35)
	scroll.add_child(grid_container)

func _update_tabs(active_type: String) -> void:
	if active_type == "avatar":
		av_tab_btn.modulate = Color.WHITE
		av_tab_btn.scale = Vector2(1.1, 1.1)
		nft_tab_btn.modulate = Color(0.4, 0.4, 0.5)
		nft_tab_btn.scale = Vector2(1.0, 1.0)
	else:
		av_tab_btn.modulate = Color(0.4, 0.4, 0.5)
		av_tab_btn.scale = Vector2(1.0, 1.0)
		nft_tab_btn.modulate = Color.WHITE
		nft_tab_btn.scale = Vector2(1.1, 1.1)

func _load_avatars() -> void:
	_clear_grid()
	_update_tabs("avatar")
	var history = AuthManager.current_user.get("avatar_history", [])
	if history.is_empty():
		_show_empty("No avatars generated yet.")
		return
		
	for url in history:
		_add_item_to_grid(url, "avatar")

func _load_nfts() -> void:
	_clear_grid()
	_update_tabs("nft")
	var history = AuthManager.current_user.get("nft_history", [])
	if history.is_empty():
		_show_empty("No NFTs minted yet.")
		return
		
	for data in history:
		if data is Dictionary:
			_add_item_to_grid(data.get("url", ""), "nft")
		elif data is String:
			_add_item_to_grid(data, "nft")

func _add_item_to_grid(url: String, type: String) -> void:
	if url.is_empty(): return

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 240)
	card.pivot_offset = Vector2(120, 120)
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_width_left = 6; style.border_width_right = 6
	style.border_width_top = 6; style.border_width_bottom = 6
	style.border_color = C_PINK if type == "avatar" else C_GOLD
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 0; style.shadow_offset = Vector2(12, 12)
	card.add_theme_stylebox_override("panel", style)
	grid_container.add_child(card)

	var tex_rect := TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(tex_rect)

	UIUtils.add_shimmer(tex_rect)
	
	var http = HTTPRequest.new()
	card.add_child(http)
	http.request_completed.connect(func(res, code, hdrs, body):
		if not is_instance_valid(tex_rect): return
		UIUtils.remove_shimmer(tex_rect)
		if code == 200:
			var img = Image.new()
			if img.load_jpg_from_buffer(body) == OK or img.load_png_from_buffer(body) == OK or img.load_webp_from_buffer(body) == OK:
				tex_rect.texture = ImageTexture.create_from_image(img)
	)
	http.request(url)
	
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.mouse_entered.connect(func():
		var tw = create_tween().set_parallel()
		tw.tween_property(card, "scale", Vector2(1.05, 1.05), 0.1)
		style.shadow_offset = Vector2(16, 16)
		AudioManager.play("hover")
	)
	card.mouse_exited.connect(func():
		var tw = create_tween().set_parallel()
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		style.shadow_offset = Vector2(12, 12)
	)
	
	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play("click")
			if type == "avatar":
				_set_active_avatar(url)
				var tw = create_tween()
				tw.tween_property(style, "border_color", Color.WHITE, 0.1)
				tw.tween_property(style, "border_color", C_PINK, 0.1)
	)

func _set_active_avatar(url: String) -> void:
	AuthManager.current_user["avatar_url"] = url
	AuthManager.update_user_details({"avatar_url": url})
	UIUtils.show_toast("Profile Avatar Updated!", C_PINK)
	AudioManager.play("success")

func _show_empty(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", C_MUTED)
	if body_font: lbl.add_theme_font_override("font", body_font)
	grid_container.add_child(lbl)

func _clear_grid() -> void:
	for c in grid_container.get_children():
		c.queue_free()

func _styled_button(txt: String, col: Color, txt_col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(180, 50)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = col.darkened(0.2)
	style.set_corner_radius_all(0)
	style.border_width_left = 4; style.border_width_right = 4
	style.border_width_top = 4; style.border_width_bottom = 4
	style.border_color = col
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_offset = Vector2(8, 8)
	
	var hov = style.duplicate(); hov.bg_color = col
	var pre = style.duplicate(); pre.shadow_offset = Vector2(0, 0)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", pre)
	btn.add_theme_color_override("font_color", txt_col)
	if pixel_font: btn.add_theme_font_override("font", pixel_font)
	
	btn.pressed.connect(func(): AudioManager.play("click"))
	btn.mouse_entered.connect(func(): AudioManager.play("hover"))
	return btn
