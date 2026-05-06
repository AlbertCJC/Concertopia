extends Control

const NEXT_SCENE : String = "res://screens/welcome_screen1.tscn"

# ── Colors ─────────────────────────────────────────────────────────────────────
const C_BG      : Color = Color(0.04, 0.03, 0.10)
const C_PANEL   : Color = Color(0.12, 0.08, 0.24)
const C_PINK    : Color = Color(0.96, 0.42, 0.62)
const C_CREAM   : Color = Color(0.96, 0.91, 0.78)
const C_MUTED   : Color = Color(0.55, 0.55, 0.65)
const C_PINK_TR : Color = Color(0.96, 0.42, 0.62, 0.15)

var pixel_font : FontFile
var body_font  : FontFile

var prompt_edit : LineEdit
var generate_btn : Button
var continue_btn : Button
var avatar_rect : TextureRect
var http_request : HTTPRequest
var status_label : Label
var credits_label : Label
var buy_container : VBoxContainer

const AVATAR_COST : int = 1

func _ready() -> void:
	pixel_font = load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	body_font  = load("res://font/Montserrat/static/Montserrat-SemiBold.ttf") as FontFile

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	_build_ui()
	_update_credits_display()
	_animate_in()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Pixel Grid Background
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

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 60)
	margin.add_child(hbox)

	# ── Left Area: Avatar Preview ───────────────────────────────────────────
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)

	var preview_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = C_PANEL.darkened(0.2)
	frame_style.border_width_left = 8; frame_style.border_width_right = 8
	frame_style.border_width_top = 8; frame_style.border_width_bottom = 8
	frame_style.border_color = C_PINK
	frame_style.set_corner_radius_all(0)
	frame_style.shadow_color = Color(0, 0, 0, 0.8)
	frame_style.shadow_size = 0; frame_style.shadow_offset = Vector2(16, 16)
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	left_vbox.add_child(preview_frame)

	avatar_rect = TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(400, 400)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var default_tex = load("res://icons/user.png") as Texture2D
	if default_tex: avatar_rect.texture = default_tex
	preview_frame.add_child(avatar_rect)

	# ── Right Area: Controls ────────────────────────────────────────────────
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 25)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	var title := Label.new()
	title.text = "PIXEL AVATAR LAB"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", C_PINK)
	if pixel_font: title.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Generate your unique 16-bit identity for the Concertopia universe."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", C_MUTED)
	if body_font: subtitle.add_theme_font_override("font", body_font)
	right_vbox.add_child(subtitle)

	var prompt_label := Label.new()
	prompt_label.text = "CHARACTER CONCEPT"
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", C_PINK)
	if pixel_font: prompt_label.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(prompt_label)

	prompt_edit = LineEdit.new()
	prompt_edit.placeholder_text = "e.g. A cyberpunk rocker with neon goggles"
	prompt_edit.custom_minimum_size = Vector2(0, 55)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(1, 1, 1, 1)
	p_style.set_corner_radius_all(0)
	p_style.border_width_left = 6; p_style.border_color = C_PINK
	p_style.content_margin_left = 20
	prompt_edit.add_theme_stylebox_override("normal", p_style)
	prompt_edit.add_theme_color_override("font_color", Color.BLACK)
	if body_font: prompt_edit.add_theme_font_override("font", body_font)
	right_vbox.add_child(prompt_edit)

	var cost_info := Label.new()
	cost_info.text = "GENERATION FEE: %d CREDIT" % AVATAR_COST
	cost_info.add_theme_font_size_override("font_size", 12)
	cost_info.add_theme_color_override("font_color", C_PINK_TR.lightened(0.5))
	if pixel_font: cost_info.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(cost_info)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	right_vbox.add_child(btn_hbox)

	generate_btn = _styled_button("GENERATE", C_PINK, Color.WHITE)
	generate_btn.pressed.connect(_on_generate_pressed)
	btn_hbox.add_child(generate_btn)

	continue_btn = _styled_button("SKIP", C_MUTED, Color.WHITE)
	continue_btn.pressed.connect(_on_continue_pressed)
	btn_hbox.add_child(continue_btn)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", C_CREAM)
	status_label.visible = false
	if body_font: status_label.add_theme_font_override("font", body_font)
	right_vbox.add_child(status_label)

	credits_label = Label.new()
	credits_label.add_theme_color_override("font_color", Color(0.92, 0.75, 0.48))
	if body_font: credits_label.add_theme_font_override("font", body_font)
	right_vbox.add_child(credits_label)

	buy_container = VBoxContainer.new()
	buy_container.visible = false
	right_vbox.add_child(buy_container)

	var buy_title = Label.new()
	buy_title.text = "OUT OF CREDITS"
	buy_title.add_theme_color_override("font_color", C_PINK)
	if pixel_font: buy_title.add_theme_font_override("font", pixel_font)
	buy_container.add_child(buy_title)

	var buy_btn = _styled_button("BUY CREDITS", Color(0.1, 0.6, 0.3), Color.WHITE)
	buy_btn.pressed.connect(_on_buy_credits_pressed)
	buy_container.add_child(buy_btn)

	# Profile Overlay
	var profile_btn := TextureButton.new()
	var user_icon := load("res://icons/user.png") as Texture2D
	if user_icon: profile_btn.texture_normal = user_icon
	profile_btn.custom_minimum_size = Vector2(50, 50)
	profile_btn.ignore_texture_size = true
	profile_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	profile_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	profile_btn.offset_left = 30; profile_btn.offset_top = 30
	profile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	profile_btn.pressed.connect(func(): 
		AudioManager.play("click")
		get_tree().change_scene_to_file("res://screens/user_profile.tscn")
	)
	profile_btn.mouse_entered.connect(func(): AudioManager.play("hover"))
	add_child(profile_btn)

func _styled_button(txt: String, col: Color, txt_col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(140, 48)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn := StyleBoxFlat.new()
	sn.bg_color = col
	sn.set_corner_radius_all(0)
	sn.shadow_color = Color(0, 0, 0, 0.5)
	sn.shadow_size = 0; sn.shadow_offset = Vector2(4, 4)
	var sh := sn.duplicate(); sh.bg_color = col.lightened(0.15)
	var sp := sn.duplicate(); sp.shadow_offset = Vector2(0, 0)
	btn.add_theme_stylebox_override("normal", sn)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_color_override("font_color", txt_col)
	if pixel_font: btn.add_theme_font_override("font", pixel_font)
	
	btn.mouse_entered.connect(func(): AudioManager.play("hover"))
	btn.pressed.connect(func(): AudioManager.play("click"))
	
	return btn

func _animate_in() -> void:
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_profile_pressed() -> void:
	get_tree().change_scene_to_file("res://screens/user_profile.tscn")

func _update_credits_display() -> void:
	var credits = AuthManager.current_user.get("avatar_credits", 0)
	credits_label.text = "BALANCE: %d CREDITS" % credits
	if credits < AVATAR_COST:
		generate_btn.disabled = true
		buy_container.visible = true
	else:
		generate_btn.disabled = false
		buy_container.visible = false

func _on_buy_credits_pressed() -> void:
	var credits = AuthManager.current_user.get("avatar_credits", 0)
	AuthManager.current_user["avatar_credits"] = credits + 5
	AuthManager.update_user_details({"avatar_credits": AuthManager.current_user["avatar_credits"]})
	_update_credits_display()
	UIUtils.show_toast("Credits Added!", Color.GREEN)
	AudioManager.play("reward")

func _on_generate_pressed() -> void:
	var prompt = prompt_edit.text.strip_edges()
	if prompt.is_empty():
		_on_error("Please enter a character description.")
		return
	
	status_label.text = "PROCESSING PIXEL DATA..."
	status_label.add_theme_color_override("font_color", C_PINK)
	status_label.visible = true
	generate_btn.disabled = true
	continue_btn.disabled = true
	
	AudioManager.play("generate")
	UIUtils.add_shimmer(avatar_rect)
	
	var base_prompt = "A close-up headshot avatar featuring only the face of a character in strict, ultra-blocky 16-bit pixel art. The image must show highly aliased construction, built from large, visible, distinct square pixel blocks, with absolutely no smoothing or anti-aliasing. Character description: "
	var style_prompt = ". Use hard cell-shading and a severely constrained retro color palette with sharp light and shadow blocks. Solid background."
	var full_prompt = base_prompt + prompt + style_prompt
	var url = "https://image.pollinations.ai/prompt/" + full_prompt.uri_encode() + "?width=512&height=512&nologo=true&model=flux&seed=" + str(randi())
	
	AuthManager.current_user["avatar_url"] = url
	http_request.request(url)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	generate_btn.disabled = false
	continue_btn.disabled = false
	UIUtils.remove_shimmer(avatar_rect)
	
	if response_code >= 200 and response_code < 300:
		var image = Image.new()
		if image.load_jpg_from_buffer(body) == OK or image.load_png_from_buffer(body) == OK or image.load_webp_from_buffer(body) == OK:
			avatar_rect.texture = ImageTexture.create_from_image(image)
			status_label.text = "IDENTITY CREATED."
			status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			continue_btn.text = "CONTINUE"
			
			AudioManager.play("success")
			
			image.save_png("user://avatar.png")
			AuthManager.current_user["avatar_path"] = "user://avatar.png"
			AuthManager.add_to_avatar_history(AuthManager.current_user["avatar_url"])
			
			var current_credits = AuthManager.current_user.get("avatar_credits", 0)
			AuthManager.current_user["avatar_credits"] = current_credits - AVATAR_COST
			AuthManager.update_user_details({"avatar_credits": AuthManager.current_user["avatar_credits"], "avatar_url": AuthManager.current_user["avatar_url"]})
			
			_update_credits_display()
		else:
			_on_error("Decode failure.")
	else:
		_on_error("Request failed (Error " + str(response_code) + ")")

func _on_error(msg: String) -> void:
	generate_btn.disabled = false
	continue_btn.disabled = false
	status_label.text = msg
	status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
