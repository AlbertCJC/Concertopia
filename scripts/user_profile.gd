extends Control

const HOME_SCENE = "res://screens/home.tscn"
const AVATAR_SCENE = "res://screens/avatar_generation.tscn"

# Colors
const C_BG      : Color = Color(0.04, 0.03, 0.10)
const C_PANEL   : Color = Color(0.12, 0.08, 0.24)
const C_PINK    : Color = Color(0.96, 0.42, 0.62)
const C_CREAM   : Color = Color(0.96, 0.91, 0.78)
const C_MUTED   : Color = Color(0.55, 0.55, 0.65)
const C_AVATAR  : Color = Color(0.25, 0.15, 0.35)

var pixel_font : FontFile
var body_font  : FontFile
var avatar_rect : TextureRect

func _ready() -> void:
	pixel_font = load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	body_font  = load("res://font/Montserrat/static/Montserrat-SemiBold.ttf") as FontFile
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Top bar
	var topbar := PanelContainer.new()
	topbar.anchor_left   = 0.0
	topbar.anchor_top    = 0.0
	topbar.anchor_right  = 1.0
	topbar.anchor_bottom = 0.0
	topbar.offset_bottom = 56.0
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = C_PANEL
	bar_style.border_width_bottom = 1
	bar_style.border_color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.25)
	topbar.add_theme_stylebox_override("panel", bar_style)
	add_child(topbar)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	topbar.add_child(margin)
	
	var hbox := HBoxContainer.new()
	margin.add_child(hbox)
	
	var back_btn := Button.new()
	back_btn.text = "← BACK"
	back_btn.custom_minimum_size = Vector2(90, 36)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.15)
	btn_style.set_corner_radius_all(10)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.3)
	back_btn.add_theme_stylebox_override("normal", btn_style)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_stylebox_override("pressed", btn_style)
	back_btn.add_theme_color_override("font_color", C_PINK)
	if pixel_font: back_btn.add_theme_font_override("font", pixel_font)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file.call_deferred(HOME_SCENE))
	hbox.add_child(back_btn)
	
	var sp1 = Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp1)
	
	var top_title = Label.new()
	top_title.text = "USER PROFILE"
	top_title.add_theme_color_override("font_color", C_CREAM)
	if pixel_font: top_title.add_theme_font_override("font", pixel_font)
	top_title.add_theme_font_size_override("font_size", 18)
	hbox.add_child(top_title)
	
	var sp2 = Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp2)
	
	var spacer_right = Control.new()
	spacer_right.custom_minimum_size = Vector2(90, 36)
	hbox.add_child(spacer_right)

	# Main Content Area
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 56 # Below top bar
	add_child(center)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = C_PANEL
	card_style.set_corner_radius_all(20)
	card_style.content_margin_left = 60
	card_style.content_margin_right = 60
	card_style.content_margin_top = 40
	card_style.content_margin_bottom = 40
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(main_vbox)

	# Avatar Panel
	var av_panel := PanelContainer.new()
	av_panel.custom_minimum_size = Vector2(120, 120)
	av_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av_panel.clip_contents = true
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = C_AVATAR
	av_style.set_corner_radius_all(20)
	av_style.border_width_left = 4
	av_style.border_width_right = 4
	av_style.border_width_top = 4
	av_style.border_width_bottom = 4
	av_style.border_color = C_PINK
	av_panel.add_theme_stylebox_override("panel", av_style)
	main_vbox.add_child(av_panel)

	avatar_rect = TextureRect.new()
	avatar_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var default_tex = load("res://icons/user.png") as Texture2D
	if default_tex: avatar_rect.texture = default_tex
	av_panel.add_child(avatar_rect)
	_load_avatar()

	# Name
	var name_lbl = Label.new()
	var d_name = AuthManager.current_user.get("display_name")
	name_lbl.text = str(d_name) if d_name != null and str(d_name).strip_edges() != "" else "Concertopia Fan"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", C_CREAM)
	if pixel_font: name_lbl.add_theme_font_override("font", pixel_font)
	main_vbox.add_child(name_lbl)

	# Email
	var email_lbl = Label.new()
	var u_email = AuthManager.current_user.get("email")
	email_lbl.text = str(u_email) if u_email != null and str(u_email).strip_edges() != "" else "No Email Attached"
	email_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	email_lbl.add_theme_font_size_override("font_size", 14)
	email_lbl.add_theme_color_override("font_color", C_MUTED)
	if body_font: email_lbl.add_theme_font_override("font", body_font)
	main_vbox.add_child(email_lbl)

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.3)
	main_vbox.add_child(sep)

	# Credits
	var credits = AuthManager.current_user.get("avatar_credits", 0)
	var credits_lbl = Label.new()
	credits_lbl.text = "Credits Balance: %d" % credits
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_lbl.add_theme_font_size_override("font_size", 16)
	credits_lbl.add_theme_color_override("font_color", Color(0.92, 0.75, 0.48)) # Gold
	if body_font: credits_lbl.add_theme_font_override("font", body_font)
	main_vbox.add_child(credits_lbl)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 15)
	btn_vbox.custom_minimum_size = Vector2(250, 0)
	main_vbox.add_child(btn_vbox)

	# Edit Avatar Button
	var edit_av_btn = Button.new()
	edit_av_btn.text = "GENERATE NEW AVATAR"
	edit_av_btn.custom_minimum_size = Vector2(0, 45)
	edit_av_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var avb_style = StyleBoxFlat.new()
	avb_style.bg_color = C_PINK
	avb_style.set_corner_radius_all(10)
	var avb_hover = avb_style.duplicate()
	avb_hover.bg_color = Color(C_PINK.r * 1.2, C_PINK.g * 1.2, C_PINK.b * 1.2)
	edit_av_btn.add_theme_stylebox_override("normal", avb_style)
	edit_av_btn.add_theme_stylebox_override("hover", avb_hover)
	edit_av_btn.add_theme_stylebox_override("pressed", avb_style)
	if pixel_font: edit_av_btn.add_theme_font_override("font", pixel_font)
	edit_av_btn.pressed.connect(func(): get_tree().change_scene_to_file.call_deferred(AVATAR_SCENE))
	btn_vbox.add_child(edit_av_btn)

func _load_avatar() -> void:
	if FileAccess.file_exists("user://avatar.png"):
		var image = Image.new()
		if image.load("user://avatar.png") == OK:
			avatar_rect.texture = ImageTexture.create_from_image(image)
			return
			
	var avatar_url = AuthManager.current_user.get("avatar_url", "")
	if not avatar_url.is_empty():
		UIUtils.add_shimmer(avatar_rect)
		var http = HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(func(res, code, hdrs, body):
			UIUtils.remove_shimmer(avatar_rect)
			if code >= 200 and code < 300:
				var image = Image.new()
				if image.load_jpg_from_buffer(body) == OK or image.load_png_from_buffer(body) == OK or image.load_webp_from_buffer(body) == OK:
					avatar_rect.texture = ImageTexture.create_from_image(image)
					image.save_png("user://avatar.png")
			http.queue_free()
		)
		http.request(avatar_url)
