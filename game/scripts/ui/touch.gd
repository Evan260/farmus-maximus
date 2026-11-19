class_name Touch
## Decisions about a phone's touch screen, kept apart from the interface so the tests can check them.

## How long a finger rests on something before the game shows what it is rather than acting on it.
const HOLD_SECONDS := 0.4


## Whether a finger that has rested this long and wandered this far, in screen pixels, is holding rather than tapping.
static func is_hold(seconds: float, moved: float, slop: float) -> bool:
	return seconds >= HOLD_SECONDS and moved <= slop


## Whether a lifted finger acts on what it touched: a tap does, while a finger that slid away or rested long enough to
## show what was there does not.
static func is_tap(moved: float, slop: float, held: bool) -> bool:
	return moved <= slop and not held


## What the phone's back gesture does, in order: "close" what is open over the screen, "leave" the market or the
## farmhouse, "title" to go from the farm back to the title, and on the title "background" to put the game away.
static func back_step(something_open: bool, away_from_farm: bool, on_title: bool) -> String:
	if something_open:
		return "close"
	if away_from_farm:
		return "leave"
	return "background" if on_title else "title"
