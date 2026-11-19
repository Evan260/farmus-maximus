class_name Touch
## Decisions about a phone's touch screen, kept apart from the interface so the tests can check them.

## How long a finger rests on something before the game shows what it is rather than acting on it.
const HOLD_SECONDS := 0.4


## Whether a finger that has rested this long and wandered this far, in screen pixels, is holding rather than tapping.
static func is_hold(seconds: float, moved: float, slop: float) -> bool:
	return seconds >= HOLD_SECONDS and moved <= slop


## Whether a lifted finger acts on what it touched, which a finger that slid away or was held to read it does not.
static func is_tap(moved: float, slop: float, held: bool) -> bool:
	return moved <= slop and not held


## What the back gesture does: "close" what is open, "leave" the town or house, go to the "title", or "background".
static func back_step(something_open: bool, away_from_farm: bool, on_title: bool) -> String:
	if something_open:
		return "close"
	if away_from_farm:
		return "leave"
	return "background" if on_title else "title"
