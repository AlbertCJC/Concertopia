extends Node

# ── UI Utilities ──
# Shared UI effects like Shimmers and Toasts.

## Create a shimmer effect on a target Control node
func add_shimmer(target: Control) -> ColorRect:
	if target == null: return null
	
	var shimmer := ColorRect.new()
	shimmer.name = "ShimmerOverlay"
	shimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create a gradient material (programmatic shader-like effect)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		uniform float speed = 2.0;
		void fragment() {
			float shimmer = sin(UV.x * 10.0 + UV.y * 10.0 + TIME * speed) * 0.1 + 0.1;
			COLOR = vec4(1.0, 1.0, 1.0, shimmer);
		}
	"""
	mat.shader = shader
	shimmer.material = mat
	
	target.add_child(shimmer)
	return shimmer

## Remove shimmer from a target
func remove_shimmer(target: Control) -> void:
	if not is_instance_valid(target): return
	var s = target.get_node_or_null("ShimmerOverlay")
	if s: s.queue_free()

## Show a floating toast message
func show_toast(text: String, color: Color = Color.WHITE) -> void:
	var scene = get_tree().current_scene
	if not scene: return
	
	var label := Label.new()
	label.text = "✦ " + text + " ✦"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_bottom = -100
	label.modulate.a = 0.0
	scene.add_child(label)
	
	var tw = label.create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.3)
	tw.tween_property(label, "offset_top", -20, 1.5).as_relative()
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tw.tween_callback(label.queue_free)
