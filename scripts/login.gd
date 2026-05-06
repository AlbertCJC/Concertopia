extends VBoxContainer

# ── Node refs ──────────────────────────────────────────────────────────────────
@onready var email_field    : LineEdit    = $Email
@onready var password_field : LineEdit    = $Passwowrd
@onready var login_button   : Button      = $"Log In2"
@onready var signup_label   : Label       = $Label
@onready var google_icon    : TextureRect = $HBoxContainer/google
@onready var facebook_icon  : TextureRect = $HBoxContainer/facebook

var error_label  : Label = null
var forgot_label : Label = null

# ── Scenes ─────────────────────────────────────────────────────────────────────
const WELCOME1_SCENE : String = "res://screens/welcome_screen1.tscn"
const USER_DETAILS_SCENE : String = "res://screens/user_details.tscn"
const SIGNUP_SCENE   : String = "res://screens/signup.tscn"
const FORGOT_SCENE   : String = "res://screens/forgot password .tscn"

# ── Eye icon assets ────────────────────────────────────────────────────────────
const EYE_OPEN   : String = "res://icons/eye.png"
const EYE_CLOSED : String = "res://icons/eye-closed.png"

# ── Provider colours for spinner label ────────────────────────────────────────
const COLOR_GOOGLE   : Color = Color(0.26, 0.52, 0.96)
const COLOR_FACEBOOK : Color = Color(0.23, 0.35, 0.60)

# ── Test Credentials ───────────────────────────────────────────────────────────
const TEST_EMAIL    : String = "test@concertopia.com"
const TEST_PASSWORD : String = "password123"

# ══════════════════════════════════════════════════════════════════════════════
# _ready
# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	password_field.secret           = true
	password_field.placeholder_text = "Password"
	email_field.placeholder_text    = "Email"
	password_field.right_icon       = null
	
	email_field.add_theme_color_override("caret_color", Color(0.1, 0.1, 0.1, 1))
	password_field.add_theme_color_override("caret_color", Color(0.1, 0.1, 0.1, 1))

	signup_label.mouse_filter = Control.MOUSE_FILTER_STOP
	signup_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_setup_eye_toggle(password_field)
	_create_forgot_label()
	_ensure_error_label()
	_setup_oauth_icons()

	login_button.pressed.connect(_on_login_pressed)
	signup_label.gui_input.connect(_on_signup_label_input)
	email_field.text_submitted.connect(_on_email_submitted)
	password_field.text_submitted.connect(_on_password_submitted)

	AuthManager.login_success.connect(_on_login_success)
	AuthManager.signup_success.connect(_on_signup_success)
	AuthManager.login_failed.connect(_on_login_failed)
	AuthManager.session_restored.connect(_on_session_restored)

func _on_session_restored(_user: Dictionary) -> void:
	if _user.has("email"):
		email_field.text = _user["email"]
		password_field.grab_focus()
		_show_info("Welcome back! Please enter your password.")

func _input(event: InputEvent) -> void:
	# Shift + T to fill test credentials
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T and event.shift_pressed:
			email_field.text = TEST_EMAIL
			password_field.text = TEST_PASSWORD
			_show_info("Test credentials filled.")

# ══════════════════════════════════════════════════════════════════════════════
# OAuth icon setup
# ══════════════════════════════════════════════════════════════════════════════
func _setup_oauth_icons() -> void:
	_make_icon_clickable(google_icon,   _on_google_pressed)
	_make_icon_clickable(facebook_icon, _on_facebook_pressed)

func _make_icon_clickable(icon: TextureRect, callback: Callable) -> void:
	if icon == null:
		return
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icon.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				callback.call()
	)

func _on_google_pressed() -> void:
	_show_error("")
	AuthManager.login_with_google()

func _on_facebook_pressed() -> void:
	_show_error("")
	AuthManager.login_with_facebook()

# Called when AuthManager opens the browser
func _on_oauth_started(provider: String) -> void:
	var name_cap : String = provider.capitalize()
	login_button.disabled = true
	_set_icons_enabled(false)
	_show_info("Browser opened — sign in with %s…" % name_cap)

# ══════════════════════════════════════════════════════════════════════════════
# Email / Password flow
# ══════════════════════════════════════════════════════════════════════════════
func _on_login_pressed() -> void:
	_attempt_login()

func _on_email_submitted(_text: String) -> void:
	password_field.grab_focus()

func _on_password_submitted(_text: String) -> void:
	_attempt_login()

func _attempt_login() -> void:
	var email    : String = email_field.text.strip_edges()
	var password : String = password_field.text
	if email.is_empty() or password.is_empty():
		_show_error("Please fill in all fields.")
		return
	_show_error("")
	login_button.disabled = true
	login_button.text     = "Logging in…"
	AuthManager.login(email, password)

# ══════════════════════════════════════════════════════════════════════════════
# Auth result handlers
# ══════════════════════════════════════════════════════════════════════════════
func _on_login_success(_user: Dictionary) -> void:
	login_button.disabled = false
	login_button.text     = "Log In"
	_set_icons_enabled(true)
	_show_error("")
	
	if AuthManager.access_token.is_empty():
		# Email not confirmed, go to OTP screen
		get_tree().change_scene_to_file.call_deferred("res://screens/inputcode.tscn")
		return
		
	AuthManager.post_login_intro = true
	if AuthManager.is_new_user or AuthManager.needs_profile_completion():
		get_tree().change_scene_to_file.call_deferred(USER_DETAILS_SCENE)
	elif AuthManager.needs_avatar_generation():
		get_tree().change_scene_to_file.call_deferred("res://screens/avatar_generation.tscn")
	else:
		# Existing user, show welcome back
		get_tree().change_scene_to_file.call_deferred("res://screens/welcome_back.tscn")

func _on_signup_success(_user: Dictionary) -> void:
	login_button.disabled = false
	login_button.text     = "Log In"
	_set_icons_enabled(true)
	_show_error("")
	
	if AuthManager.access_token.is_empty():
		# Email confirmation required, go to OTP screen
		get_tree().change_scene_to_file.call_deferred("res://screens/inputcode.tscn")
		return
		
	AuthManager.post_login_intro = true
	ScreenTransition.go(USER_DETAILS_SCENE, "left")

func _on_login_failed(reason: String) -> void:
	login_button.disabled = false
	login_button.text     = "Log In"
	_set_icons_enabled(true)
	_show_error(reason)

# ══════════════════════════════════════════════════════════════════════════════
# Navigation labels
# ══════════════════════════════════════════════════════════════════════════════
func _on_signup_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file.call_deferred(SIGNUP_SCENE)

func _on_forgot_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file.call_deferred(FORGOT_SCENE)

# ══════════════════════════════════════════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════════════════════════════════════════
func _setup_eye_toggle(field: LineEdit) -> void:
	var eye_closed : Texture2D = load(EYE_CLOSED) as Texture2D
	var eye_open   : Texture2D = load(EYE_OPEN)   as Texture2D
	if eye_closed == null or eye_open == null:
		return
	var btn := Button.new()
	btn.flat       = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.icon        = eye_closed
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 24)
	btn.modulate = Color(1, 1, 1, 0.45)
	var style := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, style)
	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	btn.offset_right  = -4
	btn.offset_left   = btn.offset_right - 40
	btn.offset_top    = -20
	btn.offset_bottom = 20
	field.add_child(btn)
	btn.pressed.connect(func() -> void:
		field.secret = not field.secret
		btn.icon = eye_closed if field.secret else eye_open
	)

func _create_forgot_label() -> void:
	forgot_label = Label.new()
	forgot_label.name = "ForgotPassword"
	forgot_label.text = "Forgot Password?"
	forgot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	forgot_label.mouse_filter = Control.MOUSE_FILTER_STOP
	forgot_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	forgot_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(forgot_label)
	move_child(forgot_label, login_button.get_index())
	forgot_label.gui_input.connect(_on_forgot_label_input)

func _ensure_error_label() -> void:
	if has_node("ErrorLabel"):
		error_label = $ErrorLabel
		return
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.custom_minimum_size = Vector2(300, 0)
	error_label.visible = false
	add_child(error_label)
	move_child(error_label, login_button.get_index())

func _show_error(message: String) -> void:
	if error_label == null:
		return
	if message.is_empty():
		error_label.text    = ""
		error_label.visible = false
		return
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.text    = message
	error_label.visible = true

func _show_info(message: String) -> void:
	if error_label == null:
		return
	error_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	error_label.text    = message
	error_label.visible = true

func _set_icons_enabled(enabled: bool) -> void:
	var alpha : float = 1.0 if enabled else 0.45
	if google_icon   != null: google_icon.modulate.a   = alpha
	if facebook_icon != null: facebook_icon.modulate.a = alpha
	# Prevent click spam while waiting
	if google_icon   != null: google_icon.mouse_filter   = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if facebook_icon != null: facebook_icon.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
