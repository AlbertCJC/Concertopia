extends Node

const SAVE_PATH := "user://users.json"

var _users        : Dictionary = {}
var current_user  : Dictionary = {}

var is_new_user            : bool = false
var needs_character_select : bool = false
var post_login_intro       : bool = false

var _pending_reset_email : String = ""
var _pending_reset_code  : String = ""

signal login_success(user: Dictionary)
signal login_failed(reason: String)
signal signup_success(user: Dictionary)
signal signup_failed(reason: String)
signal reset_code_sent(email: String, code: String)
signal reset_code_verified()
signal reset_code_invalid()
signal password_changed()
signal password_change_failed(reason: String)

const TEST_ACCOUNTS := {
	"test@test.com":           { "password": "123456",   "display_name": "Tester"    },
	"admin@concertopia.com":   { "password": "admin123", "display_name": "Admin"     },
	"demo@demo.com":           { "password": "demo123",  "display_name": "Demo User" },
}

func _ready() -> void:
	for email in TEST_ACCOUNTS:
		_users[email] = TEST_ACCOUNTS[email].duplicate()
	_load_users()

func register(email: String, password: String, display_name: String = "") -> bool:
	email = email.strip_edges().to_lower()
	if email.is_empty() or password.is_empty():
		signup_failed.emit("Email and password are required.")
		return false
	if not _is_valid_email(email):
		signup_failed.emit("Please enter a valid email address.")
		return false
	if password.length() < 6:
		signup_failed.emit("Password must be at least 6 characters.")
		return false
	if _users.has(email):
		signup_failed.emit("An account with that email already exists.")
		return false
	_users[email] = {
		"password":     password,
		"display_name": display_name if display_name != "" else email.split("@")[0],
		"login_count":  0,
	}
	_save_users()
	current_user           = { "email": email, "display_name": _users[email]["display_name"] }
	is_new_user            = true
	needs_character_select = true
	post_login_intro       = true
	signup_success.emit(current_user)
	return true

func login(email: String, password: String) -> bool:
	email = email.strip_edges().to_lower()
	if email.is_empty() or password.is_empty():
		login_failed.emit("Please enter your email and password.")
		return false
	if not _users.has(email):
		login_failed.emit("No account found with that email.")
		return false
	if _users[email]["password"] != password:
		login_failed.emit("Incorrect password. Please try again.")
		return false
	var count : int = int(_users[email].get("login_count", 0))
	_users[email]["login_count"] = count + 1
	_save_users()
	current_user           = { "email": email, "display_name": _users[email]["display_name"] }
	is_new_user            = (count == 0)
	needs_character_select = not _users[email].get("character_selected", false)
	post_login_intro       = true
	login_success.emit(current_user)
	return true

func logout() -> void:
	current_user           = {}
	is_new_user            = false
	needs_character_select = false
	post_login_intro       = false

func is_logged_in() -> bool:
	return current_user.size() > 0

func mark_character_selected(character: String) -> void:
	var email : String = current_user.get("email", "")
	if email.is_empty() or not _users.has(email):
		return
	_users[email]["character_selected"] = true
	_users[email]["character_base"]     = character
	current_user["character_base"]      = character
	needs_character_select              = false
	_save_users()

func mark_skin_selected(skin_path: String) -> void:
	var email : String = current_user.get("email", "")
	if not email.is_empty() and _users.has(email):
		_users[email]["character_skin"] = skin_path
		_save_users()
	current_user["character_skin"] = skin_path

func get_selected_base() -> String:
	return current_user.get("character_base", "female")

func send_reset_code(email: String) -> bool:
	email = email.strip_edges().to_lower()
	_pending_reset_email = email
	_pending_reset_code  = _generate_code()
	reset_code_sent.emit(email, _pending_reset_code)
	return true

func verify_reset_code(code: String) -> bool:
	if code.strip_edges() == _pending_reset_code:
		reset_code_verified.emit()
		return true
	reset_code_invalid.emit()
	return false

func change_password(new_password: String, confirm_password: String) -> bool:
	if new_password.length() < 6:
		password_change_failed.emit("Password must be at least 6 characters.")
		return false
	if new_password != confirm_password:
		password_change_failed.emit("Passwords do not match.")
		return false
	if _pending_reset_email.is_empty():
		password_change_failed.emit("Session expired. Please restart the reset process.")
		return false
	if not _users.has(_pending_reset_email):
		_users[_pending_reset_email] = {
			"password":     new_password,
			"display_name": _pending_reset_email.split("@")[0],
			"login_count":  0,
		}
	else:
		_users[_pending_reset_email]["password"] = new_password
	_save_users()
	_pending_reset_email = ""
	_pending_reset_code  = ""
	password_changed.emit()
	return true

func _save_users() -> void:
	var to_save : Dictionary = {}
	for email in _users:
		if not TEST_ACCOUNTS.has(email):
			to_save[email] = _users[email]
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_save))
		file.close()

func _load_users() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text   : String = file.get_as_text()
		file.close()
		var result = JSON.parse_string(text)
		if result is Dictionary:
			for email in result:
				_users[email] = result[email]

func _is_valid_email(email: String) -> bool:
	return "@" in email and "." in email.split("@")[-1]

func _generate_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%04d" % rng.randi_range(1000, 9999)
