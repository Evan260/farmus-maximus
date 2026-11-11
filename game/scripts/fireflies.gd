extends Node2D
## Fireflies over the lavender at night. They live on a layer the night tint does not reach, so they glow instead of darkening.

var _flies: Array = []
var _shown := false


func _ready() -> void:
	for i in 40:
		_flies.append({"pos": Vector2(randf_range(10, 2390), randf_range(170, 255)), "phase": randf() * TAU, "drift": Vector2(randf_range(-4, 4), randf_range(-2, 2))})


func _process(delta: float) -> void:
	for f in _flies:
		f["phase"] += delta
		f["pos"] += (f["drift"] + Vector2(sin(f["phase"] * 0.7) * 3.0, cos(f["phase"] * 0.9) * 2.0)) * delta
		if f["pos"].x < 0 or f["pos"].x > 2400 or f["pos"].y < 160 or f["pos"].y > 260:
			f["pos"] = Vector2(randf_range(10, 2390), randf_range(170, 255))
	# By day nothing is drawn, so the empty drawing is kept until night comes.
	var shown := Lighting.night_amount(Game.day_time) >= 0.3
	if shown or _shown:
		queue_redraw()
	_shown = shown


func _draw() -> void:
	var night := Lighting.night_amount(Game.day_time)
	if night < 0.3:
		return
	for f in _flies:
		var glow: float = (0.5 + 0.5 * sin(f["phase"] * 2.3)) * (night - 0.3) / 0.7
		var p: Vector2 = f["pos"].round()
		draw_rect(Rect2(p, Vector2.ONE), Color(0.95, 1.0, 0.55, glow))
		draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), Color(0.85, 1.0, 0.5, glow * 0.25))
