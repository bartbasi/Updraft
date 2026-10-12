class_name Vario
extends RefCounted
## "You're in lift", like a glider pilot's variometer: soft beeps while the plane climbs in
## rising air, coming faster, higher and a little louder the faster it climbs. Silent when
## sinking, diving, stalled or in sinking air. All its numbers are in Tuning ("Variometer").

var tuning: Tuning
## True while beeping. It starts at `vario_climb_min` and stops only below `vario_climb_stop`,
## so a climb hovering at the threshold doesn't stutter.
var on := false
## How strong the climb is (0..1) as of the last tick: sets the beeps' rate, pitch and loudness.
var strength := 0.0
var _wait := 0.0  ## Seconds until the next beep.


func _init(p_tuning: Tuning) -> void:
	tuning = p_tuning


## Advances one tick of `delta` seconds with the air's upward speed and the plane's climb rate
## (units/s). Returns true when a beep should sound now.
func tick(delta: float, air_up: float, climb: float, stalled: bool) -> bool:
	var threshold := tuning.vario_climb_stop if on else tuning.vario_climb_min
	on = air_up >= tuning.vario_air_min and climb >= threshold and not stalled
	if not on:
		_wait = 0.0  # the first beep comes as soon as the climb starts
		return false
	strength = clampf((climb - tuning.vario_climb_min) / maxf(tuning.vario_climb_full - tuning.vario_climb_min, 0.01), 0.0, 1.0)
	_wait -= delta
	if _wait > 0.0:
		return false
	_wait = lerpf(tuning.vario_interval_slow, tuning.vario_interval_fast, strength)
	return true


func pitch() -> float:
	return lerpf(tuning.vario_pitch_low, tuning.vario_pitch_high, strength)


func volume_db() -> float:
	return lerpf(tuning.vario_db_quiet, tuning.vario_db_loud, strength)
