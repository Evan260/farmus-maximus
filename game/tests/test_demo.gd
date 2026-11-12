extends "res://tests/test_case.gd"
## The demo's limits: what only the full game sells says so, and what is only waiting for the villa still says that.


func test_full_game_labels() -> void:
	var game: Node = root.get_node("Game")
	game.new_game()
	game.acts_as_demo = true
	game.villa_stage = 1
	var full: String = TranslationServer.translate("In the full game")
	check(game.zone_block("pasture") == "In the full game", "the demo's deed for land beyond its zones reads In the full game")
	check(game.zone_block("grove").begins_with("Restore the villa first"), "a demo deed only waiting for the villa still says so")
	check(game.decoration_block("column") == full, "a decoration for a villa stage past the demo's reads In the full game")
	game.villa_stage = 3
	check(game.decoration_block("column") == full, "and still does at the demo's last villa stage")
	var market_view: Node = load("res://scripts/ui/market_view.gd").new()
	check(market_view._deed_state("pasture") == "full", "the deed card for land beyond the demo shows Full game")
	check(market_view._deed_state("grove") == "sale", "and a demo deed the farm can buy is on sale")
	game.acts_as_demo = false
	check(market_view._deed_state("pasture") != "full", "the full game never shows a deed as Full game")
	check(game.decoration_block("column").begins_with("Restore the villa first"), "the full game says what a decoration is waiting for")
	game.villa_stage = 4
	check(game.decoration_block("column") == "", "and sells it once the villa has reached it")
	game.villa_stage = 1
	check(game.zone_block("grove").begins_with("Restore the villa first"), "a full-game deed waiting for the villa says so")
	market_view.free()
	game.new_game()
