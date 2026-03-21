extends VBoxContainer

@onready var new_password_field: LineEdit = $NewPassword
@onready var confirm_field: LineEdit      = $Passwowrd2
@onready var submit_button: Button        = $Submit
var error_label   : Label = null
var success_label : Label = null

const LOGIN_SCENE : String = "res://screens/login.tscn"

const EYE_OPEN   : String = "res://icons/eye.png"
const EYE_CLOSED : String = "res://icons/eye-closed.png"

func _ready() -> void:
	new_password_field.secret = true
	new_password_field.placeholder_text = "New Password"
	confirm_field.secret = true
	confirm_field.placeholder_text = "Confirm New Password"
	new_password_field.right_icon = null
	confirm_field.right_icon      = null

	_setup_eye_toggle(new_password_field)
	_setup_eye_toggle(confirm_field)

	submit_button.pressed.connect(_on_submit_pressed)
	confirm_field.text_submitted.connect(_on_confirm_submitted)

	AuthManager.password_changed.connect(_on_password_changed)
	AuthManager.password_change_failed.connect(_on_password_change_failed)

	_ensure_labels()

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

func _ensure_labels() -> void:
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.visible = false
	add_child(error_label)
	move_child(error_label, submit_button.get_index())

	success_label = Label.new()
	success_label.name = "SuccessLabel"
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	success_label.text = "Password changed! Redirecting to login..."
	success_label.visible = false
	add_child(success_label)
	move_child(success_label, submit_button.get_index())

func _on_confirm_submitted(_text: String) -> void:
	_attempt_change()

func _on_submit_pressed() -> void:
	_attempt_change()

func _attempt_change() -> void:
	var new_pass : String = new_password_field.text
	var confirm  : String = confirm_field.text
	if new_pass.is_empty() or confirm.is_empty():
		_show_error("Please fill in both fields.")
		return
	if new_pass.length() < 6:
		_show_error("Password must be at least 6 characters.")
		return
	if new_pass != confirm:
		_show_error("Passwords do not match.")
		return
	_show_error("")
	submit_button.disabled = true
	submit_button.text = "Saving..."
	AuthManager.change_password(new_pass, confirm)

func _on_password_changed() -> void:
	submit_button.disabled = false
	submit_button.text = "Submit"
	success_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file.call_deferred(LOGIN_SCENE)

func _on_password_change_failed(reason: String) -> void:
	submit_button.disabled = false
	submit_button.text = "Submit"
	_show_error(reason)

func _show_error(message: String) -> void:
	if error_label == null:
		return
	error_label.text    = message
	error_label.visible = not message.is_empty()
