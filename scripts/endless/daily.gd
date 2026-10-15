# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Daily
extends RefCounted
## The daily flight: one country a day, the same for everyone on the same version (its seed comes
## from the phone's date alone, no internet), and bonus stars the first time each day a run of it
## reaches GOAL_M. The bonus grows with a streak of days, kept gently: a missed day costs one step,
## not the whole streak.

const GOAL_M := 100
const BASE_REWARD := 100
const STEP_REWARD := 20
const MAX_STEPS := 5

## Replaces the clock when set ("YYYY-MM-DD"; tests, and debug builds' Day +1).
static var today_override := ""


## Today's date on the phone, "YYYY-MM-DD".
static func today() -> String:
	return today_override if today_override != "" else Time.get_date_string_from_system()


## The day's seed: 32-bit FNV-1a over the date's bytes, written out here so an engine update can't
## change everyone's day (String.hash() may change between versions).
static func seed_for(date: String) -> int:
	var h := 2166136261
	for b in ("updraft-daily-" + date).to_utf8_buffer():
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h


## True for a real date written "YYYY-MM-DD".
static func is_date(text: Variant) -> bool:
	if typeof(text) != TYPE_STRING or not RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$").search(text):
		return false
	var year := int(text.substr(0, 4))
	var month := int(text.substr(5, 2))
	var day := int(text.substr(8, 2))
	var leap := year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
	var days := [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return year >= 1970 and month >= 1 and month <= 12 and day >= 1 and day <= days[month - 1]


## Whole days from `from` to `to` (negative if `to` is earlier).
static func days_between(from: String, to: String) -> int:
	return int(roundf((_unix(to) - _unix(from)) / 86400.0))


static func _unix(date: String) -> int:
	return Time.get_unix_time_from_datetime_string(date + "T00:00:00")


## What the first run to reach GOAL_M on `date` would pay, given the progress so far:
## {"pays": bool, "stars": int, "steps": the streak after paying}. A date on or before the last
## paid day never pays.
static func reward(progress: Dictionary, date: String) -> Dictionary:
	var paid: String = progress.get("daily_paid", "")
	var steps := int(progress.get("daily_steps", 0))
	var now := 0
	if paid != "":
		var gap := days_between(paid, date)
		if gap <= 0:
			return {"pays": false, "stars": 0, "steps": steps}
		now = steps if gap == 1 else maxi(0, steps - (gap - 1))
	return {"pays": true, "stars": BASE_REWARD + STEP_REWARD * now, "steps": mini(MAX_STEPS, now + 1)}
