extends Node
## The link to a phone's own services through the native SlowSundayPhone plugin: notifications for the moments the farm
## wants the player while the game is put away, and Google Play Games achievements. Without the plugin, as on a
## computer, every call does nothing. docs/Phone-services.md lists what the plugin offers.

const PhoneNotices := preload("res://scripts/game/phone_notices.gd")
const SINGLETON := "SlowSundayPhone"

var _phone: Object = null
## Set while notices wait with the phone for the game's return, so losing the focus and then pausing plans them once.
var _away := false


func _ready() -> void:
	if Engine.has_singleton(SINGLETON):
		_phone = Engine.get_singleton(SINGLETON)
		# Notices left from a game the phone closed while it was put away are out of date once it opens again.
		cancel_all()
		sign_in()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		put_away()
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		came_back()


## Whether the native plugin is in this build.
func available() -> bool:
	return _phone != null


## Hands the phone each moment the farm will want the player, to show while the game is away.
func put_away() -> void:
	if _phone == null or _away:
		return
	_away = true
	cancel_all()
	for n in PhoneNotices.plan(Game):
		schedule(n["id"], n["seconds"], n["title"], n["text"])


func came_back() -> void:
	if _phone == null:
		return
	_away = false
	cancel_all()


## Shows a notification in so many seconds; one already waiting with the same id is replaced.
func schedule(id: String, seconds: float, title: String, text: String) -> void:
	if _phone:
		_phone.call("scheduleNotification", id, ceili(seconds), title, text)


func cancel_all() -> void:
	if _phone:
		_phone.call("cancelAllNotifications")


func notifications_allowed() -> bool:
	return _phone != null and bool(_phone.call("areNotificationsAllowed"))


## Asks the phone's own question about notifications; a phone told no stops asking, so the game remembers it asked.
func request_notifications() -> void:
	if _phone:
		_phone.call("requestNotificationPermission")
		Settings.store("phone", {"asked": true})


func asked() -> bool:
	return bool(Settings.cfg.get_value("phone", "asked", false))


func open_notification_settings() -> void:
	if _phone:
		_phone.call("openNotificationSettings")


## Unlocks an achievement on Google Play Games by its Play Console id.
func unlock_achievement(play_id: String) -> void:
	if _phone and play_id != "":
		_phone.call("unlockAchievement", play_id)


func sign_in() -> void:
	if _phone:
		_phone.call("signIn")
