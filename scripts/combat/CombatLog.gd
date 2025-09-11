# res://scripts/combat/CombatLog.gd
# Lightweight logger + text popup helper for battle debugging.
class_name CombatLog
extends Node

## Print a labeled, one-line JSON dump you can filter in Output/Debugger.
static func dump(tag: String, data: Dictionary) -> void:
	var s: String = JSON.stringify(data)
	print("[ROLL:", tag, "] ", s)

## Show a floating text at a screen position corresponding to a 2D world point.
## If world_pos == INF, center the text on screen.
static func popup(parent: Node, text: String, world_pos: Vector2 = Vector2.INF, duration: float = 2.2) -> void:
	if parent == null:
		return

	var tree: SceneTree = parent.get_tree()
	if tree == null:
		return

	var scene_root: Node = tree.current_scene
	if scene_root == null:
		scene_root = parent

	# Ensure a topmost CanvasLayer exists for popups.
	var layer: CanvasLayer = scene_root.get_node_or_null("PopupLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "PopupLayer"
		layer.layer = 100
		scene_root.add_child(layer)

	# Create the label in UI space.
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.modulate.a = 1.0
	layer.add_child(lbl)

	# Position it: convert world -> screen, otherwise center it.
	var pos: Vector2 = Vector2.ZERO
	if world_pos != Vector2.INF:
		var vp: Viewport = scene_root.get_viewport()
		if vp != null:
			var xform: Transform2D = vp.get_canvas_transform()
			pos = xform * world_pos
	else:
		var rect: Rect2 = layer.get_viewport_rect()
		pos = rect.size * 0.5
	lbl.position = pos

	# Tween: float up and fade over 'duration'.
	var tw: Tween = lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 48.0, duration)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, duration)
	tw.tween_callback(Callable(lbl, "queue_free"))
