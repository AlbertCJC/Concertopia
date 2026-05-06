extends Control

const HOME_SCENE : String = "res://screens/home.tscn"

# ── Crossmint NFT Configuration ──
const CROSSMINT_BASE_URL     : String = "https://staging.crossmint.com"
const CROSSMINT_PROJECT_ID   : String = "ck_staging_9yiAym64NJTiNgUmtGmDDsfc8b3pExdhyhFUtPqytLZN9ER83c5kPtpGbR7FJdT1TNCxRN5SVrFK6NNKKmKJcH4sDMy7tFpdHzN55yTfnz6vuW2w9gMsKYY7zZWgo31iueLFjBhQWPVVjJ4gdXknzntdJA5GqTkTyibJhnnzp9dPBqwHbzTwneGAPioEA2TYzsS9eQ6XsWCynUakLQCVBCZo"
const CROSSMINT_CLIENT_SECRET: String = "sk_staging_32yTH2qGiXh38BJczqRyEnv9sCnx7LQGdQcuY8Sbe1MUSt578PT8EcZnm7g5vSgJ4Tg1uSsmPajLPQUxvPZTVvw9gsAYvZojsMZMGE9qiQLdsHZ5Pwa7wxbkcN75MSv7QwkSg578WgiXtEPSjSo6dm9QHdQpfAxpe7LS78NCMgnMhiRFwvajTJsuJqBwM6HJUJHeGHooyWBCNFQs3EwPgwz"
const CROSSMINT_COLLECTION_ID: String = "99c73553-160c-4b65-b288-e294d173336b"

# ── Colors ─────────────────────────────────────────────────────────────────────
const C_BG      : Color = Color(0.04, 0.03, 0.10)
const C_PANEL   : Color = Color(0.12, 0.08, 0.24)
const C_PINK    : Color = Color(0.96, 0.42, 0.62)
const C_CREAM   : Color = Color(0.96, 0.91, 0.78)
const C_MUTED   : Color = Color(0.55, 0.55, 0.65)
const C_GOLD    : Color = Color(0.98, 0.8, 0.1)
const C_GOLD_TR : Color = Color(0.98, 0.8, 0.1, 0.15)

var pixel_font : FontFile
var body_font  : FontFile

var prompt_edit : LineEdit
var generate_btn : Button
var back_btn : Button
var mint_btn : Button
var nft_rect : TextureRect
var http_request : HTTPRequest
var mint_http_request : HTTPRequest
var status_label : Label
var credits_label : Label
var buy_container : VBoxContainer
var nft_badge : Label

const NFT_COST : int = 3
var _last_generated_url : String = ""

func _ready() -> void:
	pixel_font = load("res://Pixelify_Sans/static/PixelifySans-Bold.ttf") as FontFile
	body_font  = load("res://font/Montserrat/static/Montserrat-SemiBold.ttf") as FontFile

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	mint_http_request = HTTPRequest.new()
	add_child(mint_http_request)
	mint_http_request.request_completed.connect(_on_mint_request_completed)
	
	_build_ui()
	_update_credits_display()
	_animate_in()

func _build_ui() -> void:
	# Full background with subtle gold glow
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Add a pixel-grid overlay for texture
	var grid := TextureRect.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.stretch_mode = TextureRect.STRETCH_TILE
	grid.modulate.a = 0.04
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

	# ── Left Area: Art Preview ───────────────────────────────────────────────
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)

	var preview_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = C_PANEL.darkened(0.2)
	frame_style.border_width_left = 8; frame_style.border_width_right = 8
	frame_style.border_width_top = 8; frame_style.border_width_bottom = 8
	frame_style.border_color = C_GOLD
	frame_style.set_corner_radius_all(0)
	frame_style.shadow_color = Color(0, 0, 0, 0.8)
	frame_style.shadow_size = 0; frame_style.shadow_offset = Vector2(16, 16)
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	left_vbox.add_child(preview_frame)

	nft_rect = TextureRect.new()
	nft_rect.custom_minimum_size = Vector2(450, 450)
	nft_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nft_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var default_tex = load("res://icons/icon.svg") as Texture2D
	if default_tex: nft_rect.texture = default_tex
	preview_frame.add_child(nft_rect)
	
	nft_badge = Label.new()
	nft_badge.text = "★ OFFICIAL NFT"
	nft_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nft_badge.add_theme_color_override("font_color", Color.BLACK)
	nft_badge.add_theme_font_size_override("font_size", 14)
	if pixel_font: nft_badge.add_theme_font_override("font", pixel_font)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = C_GOLD
	badge_style.set_corner_radius_all(0) # Blocky
	badge_style.content_margin_left = 16; badge_style.content_margin_right = 16
	badge_style.content_margin_top = 8; badge_style.content_margin_bottom = 8
	nft_badge.add_theme_stylebox_override("normal", badge_style)
	nft_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	nft_badge.offset_left = -160; nft_badge.offset_top = 20
	nft_badge.offset_right = -20; nft_badge.offset_bottom = 55
	nft_badge.visible = false
	nft_rect.add_child(nft_badge)

	# ── Right Area: Controls ────────────────────────────────────────────────
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 25)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	var title := Label.new()
	title.text = "NFT MINTING VAULT"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", C_GOLD)
	if pixel_font: title.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Craft high-fidelity digital assets for your permanent collection."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", C_MUTED)
	if body_font: subtitle.add_theme_font_override("font", body_font)
	right_vbox.add_child(subtitle)

	var prompt_label := Label.new()
	prompt_label.text = "ARTISTIC DIRECTION"
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", C_GOLD)
	if pixel_font: prompt_label.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(prompt_label)

	prompt_edit = LineEdit.new()
	prompt_edit.placeholder_text = "e.g. A futuristic neon concert stage with holographic crowds"
	prompt_edit.custom_minimum_size = Vector2(0, 55)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(1, 1, 1, 1)
	p_style.set_corner_radius_all(0)
	p_style.border_width_left = 6; p_style.border_color = C_GOLD
	p_style.content_margin_left = 20
	prompt_edit.add_theme_stylebox_override("normal", p_style)
	prompt_edit.add_theme_color_override("font_color", Color.BLACK)
	if body_font: prompt_edit.add_theme_font_override("font", body_font)
	right_vbox.add_child(prompt_edit)

	var cost_info := Label.new()
	cost_info.text = "MINTING FEE: %d CREDITS" % NFT_COST
	cost_info.add_theme_font_size_override("font_size", 12)
	cost_info.add_theme_color_override("font_color", C_GOLD_TR.lightened(0.5))
	if pixel_font: cost_info.add_theme_font_override("font", pixel_font)
	right_vbox.add_child(cost_info)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	right_vbox.add_child(btn_hbox)

	generate_btn = _styled_button("GENERATE", C_GOLD, Color.BLACK)
	generate_btn.pressed.connect(_on_generate_pressed)
	btn_hbox.add_child(generate_btn)

	mint_btn = _styled_button("MINT NFT", C_PINK, Color.WHITE)
	mint_btn.visible = false
	mint_btn.pressed.connect(_on_mint_pressed)
	btn_hbox.add_child(mint_btn)

	back_btn = _styled_button("BACK", C_MUTED, Color.WHITE)
	back_btn.pressed.connect(_on_back_pressed)
	btn_hbox.add_child(back_btn)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", C_CREAM)
	status_label.visible = false
	if body_font: status_label.add_theme_font_override("font", body_font)
	right_vbox.add_child(status_label)

	credits_label = Label.new()
	credits_label.add_theme_color_override("font_color", C_GOLD)
	if body_font: credits_label.add_theme_font_override("font", body_font)
	right_vbox.add_child(credits_label)

	buy_container = VBoxContainer.new()
	buy_container.visible = false
	right_vbox.add_child(buy_container)

	var buy_title = Label.new()
	buy_title.text = "INSUFFICIENT CREDITS"
	buy_title.add_theme_color_override("font_color", C_PINK)
	if pixel_font: buy_title.add_theme_font_override("font", pixel_font)
	buy_container.add_child(buy_title)

func _styled_button(txt: String, col: Color, txt_col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(180, 52)
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
	btn.add_theme_color_override("font_hover_color", txt_col)
	if pixel_font: btn.add_theme_font_override("font", pixel_font)
	
	btn.mouse_entered.connect(func(): AudioManager.play("hover"))
	btn.pressed.connect(func(): AudioManager.play("click"))
	return btn

func _animate_in() -> void:
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)

func _update_credits_display() -> void:
	var credits = AuthManager.current_user.get("avatar_credits", 0)
	credits_label.text = "BALANCE: %d CREDITS" % credits
	if credits < NFT_COST:
		generate_btn.disabled = true
		buy_container.visible = true
	else:
		generate_btn.disabled = false
		buy_container.visible = false

func _on_generate_pressed() -> void:
	var prompt = prompt_edit.text.strip_edges()
	if prompt.is_empty():
		_on_error("Please enter a creative prompt.")
		return
	
	status_label.text = "INITIATING GENERATION SEQUENCE..."
	status_label.add_theme_color_override("font_color", C_GOLD)
	status_label.visible = true
	generate_btn.disabled = true
	back_btn.disabled = true
	
	AudioManager.play("generate")
	UIUtils.add_shimmer(nft_rect)
	
	# Shake effect on generate
	var tw = create_tween()
	tw.tween_property(nft_rect.get_parent(), "position:x", 10, 0.05).as_relative()
	tw.tween_property(nft_rect.get_parent(), "position:x", -20, 0.05).as_relative()
	tw.tween_property(nft_rect.get_parent(), "position:x", 10, 0.05).as_relative()

	var base_prompt = "A high-quality, professional digital art piece, suitable for a premium NFT collection. Style: "
	var style_prompt = ". Detailed, cinematic lighting, 8k resolution, artistic composition."
	var full_prompt = base_prompt + prompt + style_prompt
	var safe_prompt = full_prompt.uri_encode()
	var url = "https://image.pollinations.ai/prompt/" + safe_prompt + "?width=1024&height=1024&nologo=true&model=flux&seed=" + str(randi())
	
	http_request.request(url)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	generate_btn.disabled = false
	back_btn.disabled = false
	UIUtils.remove_shimmer(nft_rect)
	
	if response_code >= 200 and response_code < 300:
		var image = Image.new()
		if image.load_jpg_from_buffer(body) == OK or image.load_png_from_buffer(body) == OK or image.load_webp_from_buffer(body) == OK:
			var texture = ImageTexture.create_from_image(image)
			nft_rect.texture = texture
			status_label.text = "ASSET GENERATED SUCCESSFULLY."
			status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			mint_btn.visible = true
			
			AudioManager.play("success")
			
			_last_generated_url = "https://image.pollinations.ai/prompt/" + prompt_edit.text.uri_encode() + "?width=1024&height=1024&nologo=true&model=flux&seed=" + str(randi())

			# Deduct credits
			var current_credits = AuthManager.current_user.get("avatar_credits", 0)
			AuthManager.current_user["avatar_credits"] = current_credits - NFT_COST
			AuthManager.update_user_details({"avatar_credits": AuthManager.current_user["avatar_credits"]})
			
			_update_credits_display()
		else:
			_on_error("Failed to process asset data.")
	else:
		_on_error("Generation failed (Error " + str(response_code) + ")")

func _on_error(msg: String) -> void:
	generate_btn.disabled = false
	back_btn.disabled = false
	status_label.text = msg
	status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	AudioManager.play("error")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE)

# ── NFT Minting Logic ──────────────────────────────────────────────────────────
func _on_mint_pressed() -> void:
	var user_email = AuthManager.current_user.get("email", "")
	if user_email.is_empty() or _last_generated_url.is_empty():
		_on_error("Identity verification failed.")
		return
	
	generate_btn.disabled = true
	mint_btn.disabled = true
	back_btn.disabled = true
	
	AudioManager.play("generate")
	status_label.text = "MINTING ON POLYGON BLOCKCHAIN..."
	status_label.add_theme_color_override("font_color", C_GOLD)
	status_label.visible = true
	
	var endpoint = CROSSMINT_BASE_URL + "/api/2022-06-09/collections/" + CROSSMINT_COLLECTION_ID + "/nfts"
	var headers = ["X-PROJECT-ID: " + CROSSMINT_PROJECT_ID, "X-CLIENT-SECRET: " + CROSSMINT_CLIENT_SECRET, "Content-Type: application/json"]
	
	var body = {
		"recipient": "email:" + user_email + ":polygon",
		"metadata": {
			"name": "Concertopia Official NFT",
			"image": _last_generated_url,
			"description": "An exclusive official NFT from the Concertopia universe.",
			"attributes": [
				{ "trait_type": "Origin", "value": "Pollinations AI" },
				{ "trait_type": "Type", "value": "Official NFT" }
			]
		}
	}
	
	mint_http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_mint_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	generate_btn.disabled = false
	mint_btn.disabled = false
	back_btn.disabled = false
	
	if response_code >= 200 and response_code < 300:
		status_label.text = "NFT MINTED! CONFIRMATION SENT TO EMAIL."
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		mint_btn.visible = false
		nft_badge.visible = true
		
		AuthManager.add_to_nft_history({
			"url": _last_generated_url,
			"timestamp": Time.get_unix_time_from_system()
		})
		
		AudioManager.play("reward")
		UIUtils.show_toast("NFT Secured!", C_GOLD)
		
		# Shine effect on badge
		nft_badge.modulate.a = 0.0
		create_tween().tween_property(nft_badge, "modulate:a", 1.0, 0.5)
	else:
		_on_error("Blockchain transaction failed.")
