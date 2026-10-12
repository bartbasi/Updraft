class_name Vario
extends RefCounted
## "You're in lift", like a glider pilot's variometer: soft beeps while the plane climbs in
## rising air, coming faster, higher and a little louder the faster it climbs. Silent when
## sinking, diving, stalled or in sinking air. All its numbers are in Tuning ("Variometer").
## Outdoors it also sighs when the plane flies out of the side of a column ("Lift feel").

var tuning: Tuning
## True while beeping. It starts at `vario_climb_min` and stops only below `vario_climb_stop`,
## so a climb hovering at the threshold doesn't stutter.
var on := false
## How strong the climb is (0..1) as of the last tick: sets the beeps' rate, pitch and loudness.
var strength := 0.0
## True on the one tick the lift is lost: the beeps just stopped because the plane left the
## side of rising air outdoors (not its top, not a stall, not a dive). See Tuning "Lift feel".
var sigh := false
## The zone that gave the most lift while beeping, for the sigh's rules and pitch.
var zone: Thermal
var _wait := 0.0  ## Seconds until the next beep.
var _on_for := 0.0  ## Seconds the beeps have run without a break.
## The strongest rising air felt while beeping (all zones together, so where columns overlap
## it can be the stronger one's).
var _peak_air := 0.0
var _since_sigh := INF


func _init(p_tuning: Tuning) -> void:
	tuning = p_tuning


## Advances one tick of `delta` seconds with the air's upward speed and the plane's climb rate
## (units/s). `lift_zone` is the zone giving the most lift and `height` the plane's height, for
## the sigh. Returns true when a beep should sound now.
func tick(delta: float, air_up: float, climb: float, stalled: bool, lift_zone: Thermal = null, height := 0.0) -> bool:
	var threshold := tuning.vario_climb_stop if on else tuning.vario_climb_min
	var was_on := on
	on = air_up >= tuning.vario_air_min and climb >= threshold and not stalled
	_since_sigh += delta
	sigh = false
	if not on:
		if was_on and _lost_lift(air_up, stalled, height):
			sigh = true
			_since_sigh = 0.0
		_wait = 0.0  # the first beep comes as soon as the climb starts
		_on_for = 0.0
		_peak_air = 0.0
		return false
	_on_for += delta
	_peak_air = maxf(_peak_air, air_up)
	if lift_zone != null:
		zone = lift_zone
	strength = clampf((climb - tuning.vario_climb_min) / maxf(tuning.vario_climb_full - tuning.vario_climb_min, 0.01), 0.0, 1.0)
	_wait -= delta
	if _wait > 0.0:
		return false
	_wait = lerpf(tuning.vario_interval_slow, tuning.vario_interval_fast, strength)
	return true


## Whether the beeps that just stopped mean the plane flew out of the side of the lift.
func _lost_lift(air_up: float, stalled: bool, height: float) -> bool:
	return (not stalled and is_instance_valid(zone) and zone.outdoors
		and _on_for >= tuning.lift_lost_min_on
		and height < zone.top() - tuning.lift_lost_top_margin
		and air_up <= _peak_air * tuning.lift_lost_air_drop
		and _since_sigh >= tuning.lift_lost_cooldown)


func pitch() -> float:
	return lerpf(tuning.vario_pitch_low, tuning.vario_pitch_high, strength)


func volume_db() -> float:
	return lerpf(tuning.vario_db_quiet, tuning.vario_db_loud, strength)
