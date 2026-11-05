extends RefCounted
## Days, seasons, weather and festivals. Game advances it, so it keeps going during the offline catch-up too.

var day := 0
## The current weather: "sun", "cloudy", "rain" or "mist", and how long it lasts.
var weather := "sun"
var weather_left := 0.0
## Soil stays damp for a while after rain stops, which counts as watered.
var wet_left := 0.0
var _game: Node
## The season's id and the day it was worked out for, since growth asks for it for every plant on every step.
var _season := ""
var _season_day := -1


func _init(game: Node) -> void:
	_game = game
	weather_left = _weather_seconds()


func season_index() -> int:
	return int(day / _days_per_season()) % 4


func season_id() -> String:
	if day != _season_day:
		_season_day = day
		_season = String(_seasons()[season_index()]["id"])
	return _season


func season_name() -> String:
	return String(_seasons()[season_index()]["name"])


func day_of_season() -> int:
	return day % _days_per_season()


## Today's festival, or an empty dictionary on an ordinary day.
func festival() -> Dictionary:
	for f in Balance.get_value("calendar.festivals", []):
		if int(f["season"]) == season_index() and int(f["day"]) == day_of_season():
			return f
	return {}


func raining() -> bool:
	return weather == "rain"


func wet() -> bool:
	return raining() or wet_left > 0.0


func advance(dt: float) -> void:
	if not raining():
		wet_left = maxf(0.0, wet_left - dt)
	weather_left -= dt
	if weather_left <= 0.0:
		_change_weather()


## Called by Game when the clock passes midnight.
func next_day() -> void:
	var old_season := season_index()
	day += 1
	if season_index() != old_season and not _game.quiet:
		_game.season_changed.emit(season_id())
	var f := festival()
	if not f.is_empty():
		_game.discover("festival:" + String(f["id"]))
		if not _game.quiet:
			_game.festival_started.emit(String(f["id"]))


func _change_weather() -> void:
	var before := weather
	var odds: Dictionary = Balance.get_value("calendar.weather." + season_id(), {})
	var r: float = _game.rng.randf()
	var hour: float = _game.day_time
	if hour >= 4.0 and hour < 8.0 and r < float(Balance.get_value("calendar.mist_chance", 0.5)):
		weather = "mist"
	elif r < float(odds.get("rain", 0.2)):
		weather = "rain"
	elif r < float(odds.get("rain", 0.2)) + float(odds.get("cloudy", 0.3)):
		weather = "cloudy"
	else:
		weather = "sun"
	weather_left = _weather_seconds()
	if weather == "rain":
		wet_left = float(Balance.get_value("calendar.wet_seconds", 240))
	if weather != before and not _game.quiet:
		_game.weather_changed.emit(weather, before)


func _weather_seconds() -> float:
	var range_s: Array = Balance.get_value("calendar.weather_seconds", [180, 420])
	return _game.rng.randf_range(float(range_s[0]), float(range_s[1])) if _game.rng else float(range_s[0])


func _days_per_season() -> int:
	return int(Balance.get_value("calendar.days_per_season", 4))


func _seasons() -> Array:
	return Balance.get_value("calendar.seasons", [{"id": "spring", "name": "Spring"}])


func to_dict() -> Dictionary:
	return {"day": day, "weather": weather, "weather_left": weather_left, "wet_left": wet_left}


func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 0))
	weather = String(d.get("weather", "sun"))
	weather_left = float(d.get("weather_left", weather_left))
	wet_left = float(d.get("wet_left", 0.0))
