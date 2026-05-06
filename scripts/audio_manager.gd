extends Node

# ── Audio Manager ──
# Handles global SFX playback for UI consistency.

var _sfx_players : Array[AudioStreamPlayer] = []
const POOL_SIZE : int = 8

var _sounds : Dictionary = {
	"hover":    "res://audio/sfx/hover.wav",
	"click":    "res://audio/sfx/click.wav",
	"success":  "res://audio/sfx/success.wav",
	"error":    "res://audio/sfx/error.wav",
	"generate": "res://audio/sfx/generate.wav",
	"reward":   "res://audio/sfx/reward.wav"
}

var _loaded_streams : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pre-create a pool of players to avoid latency
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	
	_load_sounds()

func _load_sounds() -> void:
	for key in _sounds:
		var path = _sounds[key]
		if FileAccess.file_exists(path):
			_loaded_streams[key] = load(path)
		else:
			# Soft warning, won't crash
			print("[AudioManager] Sound file missing: ", path)

## Play a sound effect by name
func play(sfx_name: String, pitch_rnd: float = 0.0) -> void:
	if not _loaded_streams.has(sfx_name):
		return
		
	var player = _get_available_player()
	if player:
		player.stream = _loaded_streams[sfx_name]
		player.pitch_scale = 1.0 + randf_range(-pitch_rnd, pitch_rnd)
		player.play()

func _get_available_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0] # Overwrite first if all busy
