extends VBoxContainer

@onready var email_field: LineEdit    = $Email
@onready var password_field: LineEdit = $Passwowrd
@onready var confirm_field: LineEdit  = $ConfirmPassword
@onready var signup_button: Button    = $"Log In2"
@onready var login_label: Label       = $Label
var error_label: Label = null

const HOME_SCENE     : String = "res://screens/home.tscn"
const LOGIN_SCENE    : String = "res://screens/login.tscn"
const CHAR_SEL_SCENE : String = "res://screens/character_select.tscn"

const EYE_OPEN   : String = "res://icons/eye.png"
const EYE_CLOSED : String = "res://icons/eye-closed.png"

func _ready() -> void:
	password_field.secret = true
	password_field.placeholder_text = "Password"
	confirm_field.secret = true
	confirm_field.placeholder_text = "Confirm Password"
	email_field.placeholder_text   = "Email"
	password_field.right_icon = null
	confirm_field.right_icon  = null

	login_label.mouse_filter = Control.MOUSE_FILTER_STOP
	login_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_setup_eye_toggle(password_field)
	_setup_eye_toggle(confirm_field)

	signup_button.pressed.connect(_on_signup_pressed)
	login_label.gui_input.connect(_on_login_label_input)
	email_field.text_submitted.connect(func(_t: String) -> void: password_field.grab_focus())
	password_field.text_submitted.connect(func(_t: String) -> void: confirm_field.grab_focus())
	confirm_field.text_submitted.connect(_on_confirm_submitted)

	AuthManager.signup_success.connect(_on_signup_success)
	AuthManager.signup_failed.connect(_on_signup_failed)

	_ensure_error_label()

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
	move_child(error_label, signup_button.get_index())

func _on_confirm_submitted(_text: String) -> void:
	_attempt_signup()

func _on_signup_pressed() -> void:
	_attempt_signup()

func _attempt_signup() -> void:
	var email    : String = email_field.text.strip_edges()
	var password : String = password_field.text
	var confirm  : String = confirm_field.text
	if email.is_empty() or password.is_empty() or confirm.is_empty():
		_show_error("Please fill in all fields.")
		return
	if password != confirm:
		_show_error("Passwords do not match.")
		return
	if password.length() < 6:
		_show_error("Password must be at least 6 characters.")
		return
	_show_error("")
	signup_button.disabled = true
	signup_button.text = "Creating account..."
	AuthManager.register(email, password)

func _on_signup_success(_user: Dictionary) -> void:
	signup_button.disabled = false
	signup_button.text = "Sign Up"
	get_tree().change_scene_to_file.call_deferred(CHAR_SEL_SCENE)

func _on_signup_failed(reason: String) -> void:
	signup_button.disabled = false
	signup_button.text = "Sign Up"
	_show_error(reason)

func _on_login_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(LOGIN_SCENE)

func _show_error(message: String) -> void:
	if error_label == null:
		return
	error_label.text    = message
	error_label.visible = not message.is_empty()
