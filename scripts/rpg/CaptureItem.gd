# scripts/rpg/CaptureItem.gd
# ------------------------------------------------------------------------------
# WHAT:
#   Simple capture item Resource. Higher base_rate = stronger.
# ------------------------------------------------------------------------------

extends Resource
class_name CaptureItem

@export var name: String = "Capture Device"
@export_range(0.0, 1.0, 0.01) var base_rate: float = 0.25  # baseline chance boost
@export var tier: int = 1
@export var notes: String = ""
