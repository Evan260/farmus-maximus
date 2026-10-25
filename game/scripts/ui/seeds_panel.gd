extends "res://scripts/ui/window_panel.gd"
## Choosing what a click on an empty plot plants, from the crops the estate has cuttings for.


func _init() -> void:
	super("Choose a seed")


func signature() -> String:
	return JSON.stringify(Game.crops_unlocked) + Game.selected_seed


func build() -> void:
	for crop in Balance.get_value("seeds", []):
		if not Game.crop_unlocked(crop):
			continue
		var info := Game.crop_info(crop)
		var zone := String(Game.zone_info(String(info.get("zone", "home"))).get("name", ""))
		var b := UiKit.button(body, "%s  -  %d  (%s)" % [tr(String(info.get("name", crop))), int(info.get("plant_cost", 0)), tr(zone).to_lower()], func(): Game.selected_seed = crop; close())
		b.toggle_mode = true
		b.button_pressed = Game.selected_seed == crop
	UiKit.para(body, tr("More cuttings are sold at the market."), 200).add_theme_color_override("font_color", UiKit.FADED)
