extends Node
## The link to a phone's own services through the native SlowSundayPhone plugin: notifications for the moments the farm
## wants the player while the game is put away, none until the player taps Allow, and Google Play Games achievements.
## Without the plugin, as on a computer or an iPhone, every call does nothing. docs/Phone-services.md lists what the
## plugin offers.

const PhoneNotices := preload("res://scripts/game/phone_notices.gd")
const SINGLETON := "SlowSundayPhone"

var _phone: Object = null
## Set while notices wait with the phone for the game's return, so a second pause plans them only once.
var _away := false


func _ready() -> void:
	if Engine.has_singleton(SINGLETON):
		_phone = Engine.get_singleton(SINGLETON)
		# Notices left from a game the phone closed while it was put away are out of date once it opens again.
		cancel_all()
		sign_in()


func _notification(what: int) -> void:
	# A game that has only lost the focus, under the notification shade or beside another app, is still on screen.
	if what == NOTIFICATION_APPLICATION_PAUSED:
		put_away()
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		came_back()


## Whether the native plugin is in this build.
func available() -> bool:
	return _phone != null


## Whether notifications can be sent: an Android build with the plugin, or a computer previewing a phone; an iPhone has
## no plugin for them yet.
func can_remind() -> bool:
	return _phone != null or not OS.has_feature("mobile")


## Hands the phone each moment the farm will want the player, to show while the game is away.
func put_away() -> void:
	if _phone == null or _away:
		return
	_away = true
	cancel_all()
	for n in notices():
		schedule(n["id"], n["seconds"], n["title"], n["text"])


## The notices for the farm as it stands: none before the player allows them, whatever the phone itself allows.
func notices() -> Array:
	return PhoneNotices.plan(Game) if Settings.reminders else []


func came_back() -> void:
	if _phone == null:
		return
	_away = false
	cancel_all()


## Shows a notification in so many seconds; one already waiting with the same id is replaced.
func schedule(id: String, seconds: float, title: String, text: String) -> void:
	if _phone:
		_phone.call("schedule", id, ceili(seconds), title, text)


func cancel_all() -> void:
	if _phone:
		_phone.call("cancel_all")


func notifications_allowed() -> bool:
	return _phone != null and bool(_phone.call("notifications_allowed"))


## Turns the notices on and asks the phone's own question about them, which a phone told no stops asking.
func allow() -> void:
	Settings.set_value("reminders", true)
	if _phone:
		_phone.call("request_notifications")


func open_notification_settings() -> void:
	if _phone:
		_phone.call("open_notification_settings")


## Unlocks an achievement on Google Play Games by its Play Console id.
func unlock_achievement(play_id: String) -> void:
	if _phone and play_id != "":
		_phone.call("unlock_achievement", play_id)


func sign_in() -> void:
	if _phone:
		_phone.call("sign_in")
