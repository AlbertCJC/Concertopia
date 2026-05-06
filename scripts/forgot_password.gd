extends VBoxContainer

@onready var email_field: LineEdit = $Email
@onready var submit_button: Button = $"Log In2"
@onready var cancel_button: Button = $"Log In3"
@onready var continue_label: Label = $"Log In2/continue"
var error_label: Label = null
var info_label: Label = null

const LOGIN_SCENE      := "res://screens/login.tscn"
const INPUT_CODE_SCENE := "res://screens/inputcode.tscn"

func _ready() -> void:
	email_field.placeholder_text = "Enter your email address"
	email_field.add_theme_color_override("caret_color", Color(0.1, 0.1, 0.1, 1))
	submit_button.pressed.connect(_on_submit_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	email_field.text_submitted.connect(_on_email_submitted)
	if not AuthManager.reset_code_sent.is_connected(_on_code_sent):
		AuthManager.reset_code_sent.connect(_on_code_sent)
	if not AuthManager.reset_code_send_failed.is_connected(_on_code_send_failed):
		AuthManager.reset_code_send_failed.connect(_on_code_send_failed)
	_ensure_labels()

func _ensure_labels() -> void:
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.custom_minimum_size = Vector2(300, 0)
	error_label.visible = false
	add_child(error_label)
	move_child(error_label, submit_button.get_index())

	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(300, 0)
	info_label.visible = false
	add_child(info_label)
	move_child(info_label, submit_button.get_index())

func _on_email_submitted(_text: String) -> void:
	_attempt_send()

func _on_submit_pressed() -> void:
	_attempt_send()

func _attempt_send() -> void:
	var email := email_field.text.strip_edges()
	if email.is_empty():
		_show_error("Please enter your email address.")
		return
	if "@" not in email or "." not in email.split("@")[-1]:
		_show_error("Please enter a valid email address.")
		return
	_show_error("")
	submit_button.disabled = true
	submit_button.text = "Sending..."
	AuthManager.send_reset_code(email)

func _on_code_sent(email: String, _code: String) -> void:
	submit_button.disabled = false
	submit_button.text = "Submit"
	info_label.text = "OTP sent to %s" % email
	info_label.visible = true
	continue_label.visible = false
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file.call_deferred(INPUT_CODE_SCENE)

func _on_code_send_failed(reason: String) -> void:
	submit_button.disabled = false
	submit_button.text = "Submit"
	info_label.visible = false
	_show_error(reason)

func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(LOGIN_SCENE)

func _show_error(message: String) -> void:
	if error_label == null:
		return
	error_label.text    = message
	error_label.visible = not message.is_empty()
	continue_label.visible = message.is_empty() and not info_label.visible

func _exit_tree() -> void:
	if AuthManager.reset_code_sent.is_connected(_on_code_sent):
		AuthManager.reset_code_sent.disconnect(_on_code_sent)
	if AuthManager.reset_code_send_failed.is_connected(_on_code_send_failed):
		AuthManager.reset_code_send_failed.disconnect(_on_code_send_failed)
