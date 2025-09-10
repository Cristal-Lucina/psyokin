# scripts/rpg/Formation.gd
# ------------------------------------------------------------------------------
# Clean formation helper:
#  - Distinct columns for FRONT and BACK rows
#  - Even vertical spacing, centered on origin
#  - No overlapping positions, up to 6 enemies
# ------------------------------------------------------------------------------

extends RefCounted
class_name Formation

# You can tweak these to move groups around the battlefield
var ally_origin: Vector2  = Vector2(260, 340)
var enemy_origin: Vector2 = Vector2(760, 340)

# Horizontal spacing between front/back columns; vertical spacing between units
const COL_DX: float = 96.0
const ROW_DY: float = 64.0

# --- Allies (simple 3-slot arc) ----------------------------------------------
func get_ally_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	# 3 allies arranged in a small triangle/arc
	out.append(ally_origin + Vector2(-COL_DX * 0.5, -ROW_DY * 0.5))
	out.append(ally_origin + Vector2(-COL_DX * 0.8,  ROW_DY * 0.4))
	out.append(ally_origin + Vector2( 0.0,           ROW_DY * 0.9))
	return out

# --- Enemies (driven by rows array) ------------------------------------------
# rows: Array[int] of RPGRules.Row.FRONT / RPGRules.Row.BACK for each enemy
func get_enemy_positions_for_rows(rows: Array[int]) -> Array[Vector2]:
	var n: int = rows.size()
	if n <= 0:
		return []

	# Count how many go in each column
	var n_front := 0
	var n_back := 0
	for r in rows:
		if int(r) == int(RPGRules.Row.FRONT):
			n_front += 1
		else:
			n_back += 1

	# Build evenly spaced y-positions for each column, centered on enemy_origin.y
	var front_y := _make_centered_y_list(n_front)
	var back_y  := _make_centered_y_list(n_back)

	var front_x := enemy_origin.x
	var back_x  := enemy_origin.x + COL_DX

	var idx_f := 0
	var idx_b := 0

	var out: Array[Vector2] = []
	out.resize(n)

	for i in n:
		var row := int(rows[i])
		if row == int(RPGRules.Row.FRONT):
			out[i] = Vector2(front_x, enemy_origin.y + front_y[idx_f])
			idx_f += 1
		else:
			out[i] = Vector2(back_x, enemy_origin.y + back_y[idx_b])
			idx_b += 1
	return out

# Build symmetric vertical offsets like [-64, 0, 64] or [-96, -32, 32, 96]
func _make_centered_y_list(count: int) -> Array[float]:
	var out: Array[float] = []
	if count <= 0:
		return out
	# Even spacing around 0: (i - (count-1)/2) * ROW_DY
	for i in count:
		var offset := (float(i) - (float(count) - 1.0) * 0.5) * ROW_DY
		out.append(offset)
	return out
