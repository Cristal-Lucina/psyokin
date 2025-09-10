# scripts/tests/WorldDebugGrid.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Simple static world grid so movement is visually obvious during testing.
# WHY:
#   Without a background, camera-follow can make movement hard to notice.
# USE:
#   Attach to a Node2D in your Main scene. Place it under the Player in the tree.
# NOTES:
#   - Fully typed, ASCII-only, Godot 4.x.
#   - Draws a filled background, minor grid lines, and thicker major lines.
# ------------------------------------------------------------------------------

extends Node2D
class_name WorldDebugGrid

#region Designer tunables
@export_range(8, 256, 1) var cell_size: int = 64        # size of one grid cell in pixels
@export_range(4, 512, 1) var cols: int = 50             # number of columns (world width)
@export_range(4, 512, 1) var rows: int = 30             # number of rows (world height)
@export_range(2, 32, 1) var major_every: int = 8        # draw a thicker line every N cells

# Colors
@export var bg_color: Color        = Color(0.10, 0.10, 0.12, 1.0)  # dark slate background
@export var minor_color: Color     = Color(0.30, 0.30, 0.36, 0.6)
@export var major_color: Color     = Color(0.65, 0.65, 0.75, 0.9)
@export var origin_color: Color    = Color(0.95, 0.25, 0.25, 0.9)  # cross at world origin
#endregion

# Auto-place behind gameplay
func _ready() -> void:
	z_index = -100   # ensures grid draws behind Player, overlay, etc.

func _draw() -> void:
	# Compute top-left so grid is centered around (0,0)
	var world_w: float = float(cols) * cell_size
	var world_h: float = float(rows) * cell_size
	var half_w: float = world_w * 0.5
	var half_h: float = world_h * 0.5
	var top_left := Vector2(-half_w, -half_h)
	var _bottom_right := Vector2(half_w, half_h)

	# 1) Background fill
	draw_rect(Rect2(top_left, Vector2(world_w, world_h)), bg_color)

	# 2) Grid lines
	# Vertical lines
	for c in cols + 1:
		var x: float = -half_w + float(c) * cell_size
		var col: Color = major_color if (c % major_every == 0) else minor_color
		var thickness: float = 2.0 if (c % major_every == 0) else 1.0
		draw_line(Vector2(x, -half_h), Vector2(x, half_h), col, thickness)

	# Horizontal lines
	for r in rows + 1:
		var y: float = -half_h + float(r) * cell_size
		var col2: Color = major_color if (r % major_every == 0) else minor_color
		var thickness2: float = 2.0 if (r % major_every == 0) else 1.0
		draw_line(Vector2(-half_w, y), Vector2(half_w, y), col2, thickness2)

	# 3) Origin crosshair
	var cross: float = min(half_w, half_h) * 0.02 + 8.0
	draw_line(Vector2(-cross, 0), Vector2(cross, 0), origin_color, 2.0)
	draw_line(Vector2(0, -cross), Vector2(0, cross), origin_color, 2.0)
