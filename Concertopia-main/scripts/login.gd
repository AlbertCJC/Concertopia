extends VBoxContainer

@onready var email_field: LineEdit    = $Email
@onready var password_field: LineEdit = $Passwowrd
@onready var login_button: Button     = $"Log In2"
@onready var signup_label: Label      = $Label
var error_label: Label  = null
var forgot_label: Label = null

const WELCOME1_SCENE     : String = "res://screens/welcome_screen1.tscn"
const WELCOME_BACK_SCENE : String = "res://screens/welcome_back.tscn"
const SIGNUP_SCENE       : String = "res://screens/signup.tscn"
const FORGOT_SCENE       : String = "res://screens/forgot password .tscn"
const CHAR_SEL_SCENE     : String = "res://screens/character_select.tscn"

const EYE_OPEN   : String = "res://icons/eye.png"
const EYE_CLOSED : String = "res://icons/eye-closed.png"

func _ready() -> void:
	password_field.secret = true
	password_field.placeholder_text = "Password"
	email_field.placeholder_text    = "Email"
	password_field.right_icon = null

	signup_label.mouse_filter = Control.MOUSE_FILTER_STOP
	signup_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_setup_eye_toggle(password_field)
	_create_forgot_label()
	_ensure_error_label()

	login_button.pressed.connect(_on_login_pressed)
	signup_label.gui_input.connect(_on_signup_label_input)
	email_field.text_submitted.connect(_on_email_submitted)
	password_field.text_submitted.connect(_on_password_submitted)

	AuthManager.login_success.connect(_on_login_success)
	AuthManager.login_failed.connect(_on_login_failed)

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
	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("hover",    style)
	btn.add_theme_stylebox_override("pressed",  style)
	btn.add_theme_stylebox_override("focus",    style)
	btn.add_theme_stylebox_override("disabled", style)
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
	error_label.visible = false
	add_child(error_label)
	move_child(error_label, login_button.get_index())

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
	login_button.text = "Logging in..."
	AuthManager.login(email, password)

func _on_login_success(_user: Dictionary) -> void:
	login_button.disabled = false
	login_button.text = "Log In"

	if AuthManager.is_new_user:
		# First login ever — show all 3 welcome screens first.
		# welcome_screen3._advance() will then route to char select or welcome back.
		AuthManager.post_login_intro = true
		get_tree().change_scene_to_file.call_deferred(WELCOME1_SCENE)

	else:
		# Returning user — go straight to welcome back
		get_tree().change_scene_to_file.call_deferred(WELCOME_BACK_SCENE)

func _on_login_failed(reason: String) -> void:
	login_button.disabled = false
	login_button.text = "Log In"
	_show_error(reason)

func _on_signup_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(SIGNUP_SCENE)

func _on_forgot_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(FORGOT_SCENE)

func _show_error(message: String) -> void:
	if error_label == null:
		return
	error_label.text    = message
	error_label.visible = not message.is_empty()
