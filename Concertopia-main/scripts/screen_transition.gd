extends CanvasLayer
# Swipe transition — flash-free, zero offset.
# Usage: ScreenTransition.go("res://screens/foo.tscn", "left" or "right")

var _active      : bool   = false
var _committing  : bool   = false
var _dragging    : bool   = false
var _auto_commit : bool   = false

# Ignore the press that triggered go() to prevent snap-back jitter
var _ignore_until_release : bool = false

var _direction   : String = "left"
var _target_path : String = ""

var _vp_w         : float = 0.0
var _vp_h         : float = 0.0
var _drag_start_x : float = 0.0
var _current_x    : float = 0.0

var _clip       : Control = null
var _cur_wrap   : Control = null   # wrapper that holds the current scene
var _nxt_wrap   : Control = null   # wrapper that holds the next scene
var _snap_tween : Tween   = null

const SNAP_DUR  : float = 0.28
const THRESHOLD : float = 0.5

func _ready() -> void:
	layer        = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Ensure CanvasLayer has no offset of its own
	offset = Vector2(0, 0)

# ── Public ────────────────────────────────────────────────────────────────────

func go(target_path: String, direction: String) -> void:
	if _active or _committing:
		return

	_direction   = direction
	_target_path = target_path
	var vp_rect  : Rect2 = get_viewport().get_visible_rect()
	_vp_w        = vp_rect.size.x
	_vp_h        = vp_rect.size.y

	# Reset CanvasLayer offset each call to be safe
	offset = Vector2(0, 0)

	# Hide the real scene so it can't bleed through the overlay
	var real_scene : Node = get_tree().current_scene
	if real_scene is CanvasItem:
		(real_scene as CanvasItem).visible = false

	# ── Clip container: explicit pixel size, no anchors ───────────────────────
	_clip = Control.new()
	_clip.position      = Vector2(0.0, 0.0)
	_clip.size          = Vector2(_vp_w, _vp_h)
	_clip.clip_contents = true
	_clip.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)

	# ── Current scene — wrapped in a full-rect Control ────────────────────────
	var cur_path  : String      = real_scene.scene_file_path
	var cur_res   : PackedScene = load(cur_path) as PackedScene
	var cur_inner : Control     = cur_res.instantiate() as Control

	_cur_wrap          = Control.new()
	_cur_wrap.position = Vector2(0.0, 0.0)
	_cur_wrap.size     = Vector2(_vp_w, _vp_h)
	_cur_wrap.clip_contents = false
	_cur_wrap.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_cur_wrap)

	# Force the inner scene to fill the wrapper exactly
	cur_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cur_inner.position = Vector2(0.0, 0.0)
	cur_inner.size     = Vector2(_vp_w, _vp_h)
	_cur_wrap.add_child(cur_inner)

	# ── Next scene — same wrapper pattern ─────────────────────────────────────
	var nxt_res   : PackedScene = load(target_path) as PackedScene
	var nxt_inner : Control     = nxt_res.instantiate() as Control

	_nxt_wrap          = Control.new()
	_nxt_wrap.position = Vector2(_nxt_start_x(), 0.0)
	_nxt_wrap.size     = Vector2(_vp_w, _vp_h)
	_nxt_wrap.clip_contents = false
	_nxt_wrap.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(_nxt_wrap)

	nxt_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nxt_inner.position = Vector2(0.0, 0.0)
	nxt_inner.size     = Vector2(_vp_w, _vp_h)
	_nxt_wrap.add_child(nxt_inner)

	_active               = true
	_dragging             = false
	_current_x            = 0.0
	_auto_commit          = true
	_ignore_until_release = true

func _nxt_start_x() -> float:
	return _vp_w if _direction == "left" else -_vp_w

# ── Process — auto-commit on next frame for tap triggers ──────────────────────

func _process(_dt: float) -> void:
	if _active and _auto_commit and not _dragging and not _committing:
		_auto_commit = false
		_commit()

# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _active or _committing:
		return

	# Discard all input until the triggering press is released
	if _ignore_until_release:
		var released : bool = false
		if event is InputEventScreenTouch:
			released = not (event as InputEventScreenTouch).pressed
		elif event is InputEventMouseButton:
			released = not (event as InputEventMouseButton).pressed
		if released:
			_ignore_until_release = false
		return

	if event is InputEventScreenTouch:
		var e : InputEventScreenTouch = event
		if e.pressed:
			_auto_commit = false
			_drag_start(e.position.x)
		else:
			_drag_end()

	elif event is InputEventScreenDrag:
		var e : InputEventScreenDrag = event
		_auto_commit = false
		_drag_move(e.position.x)

	elif event is InputEventMouseButton:
		var e : InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_auto_commit = false
				_drag_start(e.position.x)
			else:
				_drag_end()

	elif event is InputEventMouseMotion:
		var e : InputEventMouseMotion = event
		if _dragging:
			_auto_commit = false
			_drag_move(e.position.x)

# ── Drag ──────────────────────────────────────────────────────────────────────

func _drag_start(x: float) -> void:
	if _snap_tween != null and _snap_tween.is_running():
		_snap_tween.kill()
	_dragging     = true
	_drag_start_x = x

func _drag_move(x: float) -> void:
	if not _dragging:
		return
	var raw     : float = x - _drag_start_x
	var lo      : float = -_vp_w if _direction == "left" else 0.0
	var hi      : float = 0.0    if _direction == "left" else _vp_w
	var clamped : float = clampf(raw, lo, hi)
	_current_x = clamped
	_slide_panels(clamped)

func _drag_end() -> void:
	if not _dragging:
		return
	_dragging = false
	var progress : float = absf(_current_x) / _vp_w
	if progress >= THRESHOLD:
		_commit()
	else:
		_snap_back()

# ── Move both wrappers horizontally ──────────────────────────────────────────

func _slide_panels(slide_x: float) -> void:
	if _cur_wrap == null or _nxt_wrap == null:
		return
	_cur_wrap.position.x = slide_x
	_nxt_wrap.position.x = _nxt_start_x() + slide_x

# ── Snap back ─────────────────────────────────────────────────────────────────

func _snap_back() -> void:
	_snap_tween = create_tween()
	_snap_tween.set_ease(Tween.EASE_OUT)
	_snap_tween.set_trans(Tween.TRANS_CUBIC)
	_snap_tween.set_parallel(true)
	_snap_tween.tween_property(_cur_wrap, "position:x", 0.0,            SNAP_DUR)
	_snap_tween.tween_property(_nxt_wrap, "position:x", _nxt_start_x(), SNAP_DUR)
	_snap_tween.set_parallel(false)
	await _snap_tween.finished
	_restore_real_scene()
	_teardown()

# ── Commit ────────────────────────────────────────────────────────────────────

func _commit() -> void:
	_committing  = true
	_auto_commit = false
	var done_x : float = -_vp_w if _direction == "left" else _vp_w

	_snap_tween = create_tween()
	_snap_tween.set_ease(Tween.EASE_OUT)
	_snap_tween.set_trans(Tween.TRANS_CUBIC)
	_snap_tween.set_parallel(true)
	_snap_tween.tween_property(_cur_wrap, "position:x", done_x, SNAP_DUR)
	_snap_tween.tween_property(_nxt_wrap, "position:x", 0.0,    SNAP_DUR)
	_snap_tween.set_parallel(false)
	await _snap_tween.finished

	_teardown()
	get_tree().change_scene_to_file.call_deferred(_target_path)

# ── Restore real scene ────────────────────────────────────────────────────────

func _restore_real_scene() -> void:
	var real_scene : Node = get_tree().current_scene
	if real_scene is CanvasItem:
		(real_scene as CanvasItem).visible = true

# ── Cleanup ───────────────────────────────────────────────────────────────────

func _teardown() -> void:
	_cur_wrap = null
	_nxt_wrap = null
	if _clip != null:
		_clip.queue_free()
		_clip = null
	_active               = false
	_committing           = false
	_dragging             = false
	_auto_commit          = false
	_ignore_until_release = false
