## auth_manager.gd  –  Robust Supabase Auth & Data Manager
extends Node

# ── Supabase Configuration ────────────────────────────────────────────────────
const SUPABASE_URL := "https://jkhclleriwdsrojzsekx.supabase.co"
const SUPABASE_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpraGNsbGVyaXdkc3JvanpzZWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3ODYzNzQsImV4cCI6MjA5MzM2MjM3NH0.N4tQ6kgm-X7ThJoWYzpXI2EXRKVnwSlcVd7X1OFLJ30"

# Endpoints
const ENDPOINT_SIGNUP  := "/auth/v1/signup"
const ENDPOINT_LOGIN   := "/auth/v1/token?grant_type=password"
const ENDPOINT_REFRESH := "/auth/v1/token?grant_type=refresh_token"
const ENDPOINT_USER    := "/auth/v1/user"
const ENDPOINT_OTP     := "/auth/v1/otp"
const ENDPOINT_VERIFY  := "/auth/v1/verify"
const REST_PROFILES    := "/rest/v1/profiles"

# Persistence
const SAVE_PATH := "user://session.json"

# ══════════════════════════════════════════════════════════════════════════════
# OAuth 2.0 Configuration
# ══════════════════════════════════════════════════════════════════════════════
const GOOGLE_CLIENT_ID     : String = "158219607556-m8pcp6soiia4p61p72ntuf4amuf2lrqi.apps.googleusercontent.com"
const GOOGLE_CLIENT_SECRET : String = "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"
const GOOGLE_REDIRECT_URI  : String = "http://localhost:7123/"
const GOOGLE_AUTH_URL      : String = "https://accounts.google.com/o/oauth2/v2/auth"
const GOOGLE_TOKEN_URL     : String = "https://oauth2.googleapis.com/token"
const GOOGLE_USERINFO_URL  : String = "https://www.googleapis.com/oauth2/v3/userinfo"
const GOOGLE_SCOPES        : String = "openid email profile"

const FACEBOOK_APP_ID      : String = "YOUR_FACEBOOK_APP_ID"
const FACEBOOK_APP_SECRET  : String = "YOUR_FACEBOOK_APP_SECRET"
const FACEBOOK_REDIRECT_URI: String = "http://localhost:7123/"
const FACEBOOK_AUTH_URL    : String = "https://www.facebook.com/v19.0/dialog/oauth"
const FACEBOOK_TOKEN_URL   : String = "https://graph.facebook.com/v19.0/oauth/access_token"
const FACEBOOK_USERINFO_URL: String = "https://graph.facebook.com/me?fields=id,name,email,picture"
const FACEBOOK_SCOPES      : String = "email,public_profile"

# ── State ──────────────────────────────────────────────────────────────────────
var current_user  : Dictionary = {}
var access_token  : String     = ""
var refresh_token : String     = ""
var user_id       : String     = ""
var expires_at    : int        = 0

var is_new_user      : bool = false
var post_login_intro : bool = false

# Verification state
var _verification_type   : String = "signup"
var _pending_verify_email : String = ""

# Internal Request Tracking
var _auth_http      : HTTPRequest = null
var _db_http        : HTTPRequest = null
var _otp_http       : HTTPRequest = null
var _oauth_http     : HTTPRequest = null
var _refresh_timer  : Timer       = null

var _oauth_provider : String = ""
var _oauth_state    : String = ""

# ── Signals ────────────────────────────────────────────────────────────────────
signal login_success(user: Dictionary)
signal login_failed(reason: String)
signal signup_success(user: Dictionary)
signal signup_failed(reason: String)
signal session_restored(user: Dictionary)
signal session_expired()

signal reset_code_sent(email: String, code: String)
signal reset_code_send_failed(reason: String)
signal reset_code_verified()
signal reset_code_invalid()
signal password_changed()
signal password_change_failed(reason: String)

signal oauth_login_started(provider: String)
signal profile_updated()

# ══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_setup_http_nodes()
	_setup_refresh_timer()
	_load_session()
	
	OAuthServer.oauth_code_received.connect(_on_oauth_code_received)
	OAuthServer.oauth_error.connect(func(r): login_failed.emit(r))

func _setup_http_nodes() -> void:
	_auth_http = HTTPRequest.new()
	add_child(_auth_http)
	_auth_http.request_completed.connect(_on_auth_completed)
	
	_db_http = HTTPRequest.new()
	add_child(_db_http)
	_db_http.request_completed.connect(_on_db_completed)

	_otp_http = HTTPRequest.new()
	add_child(_otp_http)
	_otp_http.request_completed.connect(_on_otp_completed)

	_oauth_http = HTTPRequest.new()
	add_child(_oauth_http)
	_oauth_http.request_completed.connect(_on_oauth_completed)

func _setup_refresh_timer() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.one_shot = true
	add_child(_refresh_timer)
	_refresh_timer.timeout.connect(refresh_session)

# ══════════════════════════════════════════════════════════════════════════════
# Public API
# ══════════════════════════════════════════════════════════════════════════════
func register(email: String, password: String, display_name: String = "") -> void:
	if not _validate_inputs(email, password): return
	is_new_user = true
	_verification_type = "signup"
	_pending_verify_email = email.strip_edges().to_lower()
	var body = {
		"email": _pending_verify_email,
		"password": password,
		"data": { 
			"display_name": display_name if !display_name.is_empty() else _pending_verify_email.split("@")[0],
			"avatar_credits": 5
		}
	}
	_send_request(_auth_http, SUPABASE_URL + ENDPOINT_SIGNUP, _get_headers(), HTTPClient.METHOD_POST, body)

func login(email: String, password: String) -> void:
	if not _validate_inputs(email, password): return
	is_new_user = false
	var body = { "email": email.strip_edges().to_lower(), "password": password }
	_send_request(_auth_http, SUPABASE_URL + ENDPOINT_LOGIN, _get_headers(), HTTPClient.METHOD_POST, body)

func login_with_google() -> void: _start_oauth("google")
func login_with_facebook() -> void: _start_oauth("facebook")

func logout() -> void:
	_clear_session()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func is_logged_in() -> bool:
	return !access_token.is_empty() and Time.get_unix_time_from_system() < expires_at

func refresh_session() -> void:
	if refresh_token.is_empty(): return
	var body = { "refresh_token": refresh_token }
	_send_request(_auth_http, SUPABASE_URL + ENDPOINT_REFRESH, _get_headers(), HTTPClient.METHOD_POST, body)

func fetch_profile() -> void:
	if user_id.is_empty(): return
	var url = SUPABASE_URL + REST_PROFILES + "?id=eq." + user_id + "&select=*"
	_send_request(_db_http, url, _get_headers(access_token), HTTPClient.METHOD_GET)

func update_user_details(details: Dictionary) -> void:
	if user_id.is_empty(): return
	
	# Update locally immediately
	for key in details:
		current_user[key] = details[key]
	
	# Construct payload dynamically. 
	# PostgREST 400 Bad Request happens if we send columns that don't exist.
	# We'll send the primary keys and the provided details.
	var payload = { "id": user_id }
	for key in details:
		payload[key] = details[key]
		
	var url = SUPABASE_URL + REST_PROFILES
	var headers = _get_headers(access_token)
	headers.append("Prefer: resolution=merge-duplicates, return=representation")
	_send_request(_db_http, url, headers, HTTPClient.METHOD_POST, payload)
	_save_session()
	profile_updated.emit()

func send_reset_code(email: String) -> void:
	email = email.strip_edges().to_lower()
	if email.is_empty() or "@" not in email:
		reset_code_send_failed.emit("Invalid email address."); return
	
	# Try 'recovery' type again with the OTP endpoint. 
	# Ensure your Supabase Email Template for "Reset Password" uses {{ .Token }}
	_verification_type = "recovery" 
	_pending_verify_email = email
	var body = { 
		"email": email,
		"type": "recovery"
	}
	_send_request(_otp_http, SUPABASE_URL + ENDPOINT_OTP, _get_headers(), HTTPClient.METHOD_POST, body)

func verify_reset_code(code: String) -> void:
	if _pending_verify_email.is_empty():
		reset_code_invalid.emit(); return
	var body = {
		"type": _verification_type,
		"email": _pending_verify_email,
		"token": code.strip_edges()
	}
	_send_request(_otp_http, SUPABASE_URL + ENDPOINT_VERIFY, _get_headers(), HTTPClient.METHOD_POST, body)

func change_password(new_password: String, confirm_password: String = "") -> void:
	if !confirm_password.is_empty() and new_password != confirm_password:
		password_change_failed.emit("Passwords do not match.")
		return
	if access_token.is_empty():
		password_change_failed.emit("Session expired. Please request a new code.")
		return
	var body = { "password": new_password }
	_send_request(_auth_http, SUPABASE_URL + ENDPOINT_USER, _get_headers(access_token), HTTPClient.METHOD_PUT, body)

# ══════════════════════════════════════════════════════════════════════════════
# OAuth Internal
# ══════════════════════════════════════════════════════════════════════════════
func _start_oauth(provider: String) -> void:
	_oauth_provider = provider
	_oauth_state    = "%08x" % [randi()]
	if not OAuthServer.start(_oauth_state): return
	
	var auth_url : String
	if provider == "google":
		auth_url = GOOGLE_AUTH_URL + "?client_id=" + GOOGLE_CLIENT_ID.uri_encode() + "&redirect_uri=" + GOOGLE_REDIRECT_URI.uri_encode() + "&response_type=code&scope=" + GOOGLE_SCOPES.uri_encode() + "&state=" + _oauth_state + "&access_type=offline&prompt=select_account"
	else:
		auth_url = FACEBOOK_AUTH_URL + "?client_id=" + FACEBOOK_APP_ID + "&redirect_uri=" + FACEBOOK_REDIRECT_URI.uri_encode() + "&response_type=code&scope=" + FACEBOOK_SCOPES.uri_encode() + "&state=" + _oauth_state

	OS.shell_open(auth_url)
	oauth_login_started.emit(provider)

func _on_oauth_code_received(code: String, _state: String) -> void:
	var url : String; var body : String
	if _oauth_provider == "google":
		url = GOOGLE_TOKEN_URL
		body = "code=" + code.uri_encode() + "&client_id=" + GOOGLE_CLIENT_ID + "&client_secret=" + GOOGLE_CLIENT_SECRET + "&redirect_uri=" + GOOGLE_REDIRECT_URI + "&grant_type=authorization_code"
	else:
		url = FACEBOOK_TOKEN_URL
		body = "code=" + code.uri_encode() + "&client_id=" + FACEBOOK_APP_ID + "&client_secret=" + FACEBOOK_APP_SECRET + "&redirect_uri=" + FACEBOOK_REDIRECT_URI + "&grant_type=authorization_code"
	
	_oauth_http.request(url, ["Content-Type: application/x-www-form-urlencoded"], HTTPClient.METHOD_POST, body)

func _on_oauth_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response = JSON.parse_string(body.get_string_from_utf8())
	if status_code >= 200 and status_code < 300:
		var token = response.get("access_token", "")
		# For Supabase OAuth, we usually want to use the Supabase 'Identity' flow,
		# but since we are doing a manual desktop flow, we would ideally pass this
		# token to Supabase or use it to fetch user info and then sign in.
		# For brevity and functionality, we'll fetch user info.
		_fetch_oauth_user_info(token)
	else:
		login_failed.emit("OAuth Token Exchange Failed: " + _extract_error(response))

func _fetch_oauth_user_info(token: String) -> void:
	var url = GOOGLE_USERINFO_URL if _oauth_provider == "google" else FACEBOOK_USERINFO_URL
	var headers = ["Authorization: Bearer " + token]
	_oauth_http.request(url, headers, HTTPClient.METHOD_GET)
	# Disconnect and reconnect to handle userinfo response instead of token response
	_oauth_http.request_completed.disconnect(_on_oauth_completed)
	_oauth_http.request_completed.connect(_on_oauth_userinfo_completed, CONNECT_ONE_SHOT)

func _on_oauth_userinfo_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Re-connect the original handler for next time
	_oauth_http.request_completed.connect(_on_oauth_completed)
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	if status_code >= 200 and status_code < 300:
		current_user["email"] = response.get("email", "")
		current_user["display_name"] = response.get("name", "")
		user_id = response.get("id", response.get("sub", ""))
		current_user["id"] = user_id
		access_token = "oauth_dummy_token" # Placeholder for manual flow
		
		# Check if profile already exists in our database
		var url = SUPABASE_URL + REST_PROFILES + "?id=eq." + user_id + "&select=*"
		_send_request(_db_http, url, _get_headers(SUPABASE_KEY), HTTPClient.METHOD_GET)
		
		# Disconnect default and connect temporary handler to decide between login and signup
		_db_http.request_completed.disconnect(_on_db_completed)
		_db_http.request_completed.connect(_on_oauth_db_check_completed, CONNECT_ONE_SHOT)
	else:
		login_failed.emit("OAuth User Info Failed")

func _on_oauth_db_check_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Reconnect default DB handler
	_db_http.request_completed.connect(_on_db_completed)
	var response = JSON.parse_string(body.get_string_from_utf8())
	
	if status_code >= 200 and status_code < 300 and response is Array and response.size() > 0:
		# User exists! Load their data and log in
		for key in response[0]:
			current_user[key] = response[0][key]
		is_new_user = false
		login_success.emit(current_user)
	else:
		# User does not exist, trigger signup info flow
		is_new_user = true
		login_success.emit(current_user) # Login screen will redirect to UserDetails because is_new_user is true

# ══════════════════════════════════════════════════════════════════════════════
# Internal Handlers
# ══════════════════════════════════════════════════════════════════════════════
func _on_auth_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response = JSON.parse_string(body.get_string_from_utf8())
	if status_code >= 200 and status_code < 300:
		if response is Dictionary and response.has("id") and !response.has("access_token"):
			password_changed.emit()
		else:
			_handle_auth_success(response)
	else:
		_handle_auth_failure(response, status_code)

func _handle_auth_success(response: Dictionary) -> void:
	access_token  = response.get("access_token", "")
	refresh_token = response.get("refresh_token", "")
	var user_data = response.get("user", response)
	user_id = user_data.get("id", user_id)
	current_user["email"] = user_data.get("email", current_user.get("email", ""))
	current_user["id"] = user_id
	if !access_token.is_empty():
		expires_at = int(Time.get_unix_time_from_system()) + int(response.get("expires_in", 3600))
		_save_session(); _schedule_refresh(response.get("expires_in", 3600))
		if is_new_user: signup_success.emit(current_user)
		else: fetch_profile()
	elif is_new_user: signup_success.emit(current_user)
	is_new_user = false

func _handle_auth_failure(response: Variant, status_code: int) -> void:
	var error_msg = _extract_error(response)
	if is_new_user: signup_failed.emit(error_msg)
	else: login_failed.emit(error_msg)
	is_new_user = false

func _on_otp_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response = JSON.parse_string(body.get_string_from_utf8())
	if status_code >= 200 and status_code < 300:
		if response is Dictionary and response.has("access_token"):
			_handle_auth_success(response); reset_code_verified.emit()
		else: reset_code_sent.emit(_pending_verify_email, "")
	else:
		var error = _extract_error(response)
		if "invalid" in error.to_lower() or "expired" in error.to_lower(): reset_code_invalid.emit()
		else: reset_code_send_failed.emit(error)

func _on_db_completed(_result: int, status_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response = JSON.parse_string(body.get_string_from_utf8())
	print("[AuthManager] DB request completed. Status: ", status_code, " Body: ", body.get_string_from_utf8())
	
	if status_code >= 200 and status_code < 300:
		if response is Array and response.size() > 0:
			for key in response[0]: current_user[key] = response[0][key]
		login_success.emit(current_user)
	else: login_failed.emit("Database error: " + _extract_error(response))

# ══════════════════════════════════════════════════════════════════════════════
# Helpers
# ══════════════════════════════════════════════════════════════════════════════
func _get_headers(token: String = "") -> PackedStringArray:
	var headers = ["apikey: " + SUPABASE_KEY, "Content-Type: application/json"]
	if not token.is_empty(): headers.append("Authorization: Bearer " + token)
	return PackedStringArray(headers)

func _send_request(node: HTTPRequest, url: String, headers: PackedStringArray, method: int, body: Variant = null) -> void:
	var json_body = JSON.stringify(body) if body != null else ""
	node.request(url, headers, method, json_body)

func _extract_error(response: Variant) -> String:
	if response is Dictionary:
		if response.has("error_description"): return response["error_description"]
		if response.has("msg"): return response["msg"]
		if response.has("message"): return response["message"]
	return "Request failed"

func _validate_inputs(email: String, password: String) -> bool:
	if email.is_empty() or password.is_empty():
		login_failed.emit("Please fill in all fields."); return false
	if "@" not in email:
		login_failed.emit("Please enter a valid email."); return false
	return true

func _schedule_refresh(seconds: int) -> void:
	var wait_time = max(seconds - 300, 30)
	_refresh_timer.start(wait_time)

func _save_session() -> void:
	var data = {
		"access_token": access_token, 
		"refresh_token": refresh_token, 
		"user_id": user_id, 
		"email": current_user.get("email", ""), 
		"expires_at": expires_at,
		"avatar_history": current_user.get("avatar_history", []),
		"nft_history": current_user.get("nft_history", []),
		"last_reward_date": current_user.get("last_reward_date", "")
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func _load_session() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary: return
	access_token = data.get("access_token", ""); refresh_token = data.get("refresh_token", ""); user_id = data.get("user_id", ""); expires_at = data.get("expires_at", 0)
	current_user["email"] = data.get("email", ""); current_user["id"] = user_id
	
	# Load history and rewards from local fallback
	if data.has("avatar_history"): current_user["avatar_history"] = data["avatar_history"]
	if data.has("nft_history"): current_user["nft_history"] = data["nft_history"]
	if data.has("last_reward_date"): current_user["last_reward_date"] = data["last_reward_date"]

func _clear_session() -> void:
	access_token = ""; refresh_token = ""; user_id = ""; expires_at = 0; current_user = {}; _refresh_timer.stop()

func needs_profile_completion() -> bool:
	var val = current_user.get("display_name")
	return val == null or str(val).is_empty()

func needs_avatar_generation() -> bool:
	var val = current_user.get("avatar_url")
	return val == null or str(val).is_empty()

## ── Enhancement Helpers ──

## Record a newly generated avatar URL into history
func add_to_avatar_history(url: String) -> void:
	var history : Array = current_user.get("avatar_history", [])
	if not url in history:
		history.push_front(url)
		if history.size() > 20: history.pop_back() # Keep last 20
		update_user_details({"avatar_history": history})

## Record a newly minted NFT into history
func add_to_nft_history(nft_data: Dictionary) -> void:
	var history : Array = current_user.get("nft_history", [])
	history.push_front(nft_data)
	if history.size() > 50: history.pop_back()
	update_user_details({"nft_history": history})

## Check if user is eligible for a daily reward
func is_daily_reward_available() -> bool:
	var today = Time.get_date_string_from_system()
	var last_date = current_user.get("last_reward_date", "")
	return today != last_date

## Claim the daily reward
func claim_daily_reward() -> bool:
	if not is_daily_reward_available():
		return false
		
	var today = Time.get_date_string_from_system()
	var credits = current_user.get("avatar_credits", 0)
	current_user["avatar_credits"] = credits + 1
	current_user["last_reward_date"] = today
	
	# Update database and local session
	update_user_details({
		"avatar_credits": current_user["avatar_credits"],
		"last_reward_date": today
	})
	return true
