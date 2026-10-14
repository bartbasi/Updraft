# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Tuning
extends Resource
## =============================================================================
##  UPDRAFT TUNING: every number that changes how the game feels lives here.
## =============================================================================
##
##  Change numbers here, not code. Quick recipes:
##    "Floatier"           lower `gravity` (8 -> 6.5). Everything gets slower and gentler.
##    "Faster"             raise `gravity` (8 -> 10). Same glide angle, everything quicker.
##    "Glides farther"     lower `drag` and `induced_drag` a little.
##    "Stalls too easily"  lower `stall_speed` and `stall_recover_speed` together.
##    "More lift from heat" raise `thermal_strength`.
##    "Turns too slowly"   raise `turn_rate_deg`.
##    "Tilt too twitchy"   lower `sensitivity`.
##    "Camera too far back" lower `camera_distance`; "too jerky" lower `camera_follow_speed`.
##    "Wind too quiet in the dive" raise `wind_loud`.
##    "Style points too stingy" raise `style_full_fraction`, or a moment's radius in `style_moments`.
##  If you change `gravity` or `lift` a lot, scale `stall_speed` and
##  `stall_recover_speed` by the square root of the same factor.
##
##  Units: the world is built at 4 units = 1 real metre. Speeds are units/second.

@export_group("Air and gravity")
## Pull of gravity (units/s^2). Lower = floatier and slower; higher = faster and heavier.
@export var gravity := 8.0
## How strongly the wings hold the plane up at a given speed.
@export var lift := 0.45
## Air resistance with no lift. Lower = the plane keeps its speed longer and glides farther.
@export var drag := 0.02
## Extra drag that comes with lift, so slow nose-high flying costs speed.
@export var induced_drag := 0.01
## Lift gained per radian of angle of attack (nose angle relative to the oncoming air).
@export var lift_per_radian := 5.7
## The wings can't make more lift than this, however high the nose goes.
@export var max_lift_coefficient := 1.2
## Hard cap on speed (units/s).
@export var max_speed := 14.0

@export_group("Stall")
## Below this airspeed the wing stalls: lift collapses and the nose drops.
@export var stall_speed := 4.0
## The stall ends once airspeed is back above this.
@export var stall_recover_speed := 5.4
## Fraction of normal lift left while stalled.
@export var stall_lift_factor := 0.35
## Where the nose falls to during a stall (degrees, negative = down).
@export var stall_nose_pitch_deg := -35.0
## How fast the nose falls during a stall (degrees/second).
@export var stall_pitch_rate_deg := 110.0

@export_group("Pitch and turning")
## Nose angle with no input (degrees). About level gives a gentle glide.
@export var neutral_pitch_deg := -1.0
## Extra nose-up at full climb input (degrees).
@export var climb_pitch_deg := 28.0
## Extra nose-down at full dive input (degrees).
@export var dive_pitch_deg := 28.0
## How fast the nose follows your input (degrees/second).
@export var pitch_rate_deg := 110.0
## Bank angle at full left/right input (degrees).
@export var max_bank_deg := 35.0
## How fast the plane rolls into a bank (degrees/second).
@export var bank_rate_deg := 140.0
## Turn rate at full bank (degrees/second).
@export var turn_rate_deg := 65.0

@export_group("Thermals and downdrafts")
## Upward air speed in the middle of a thermal (units/s). Each thermal can scale this.
@export var thermal_strength := 5.0
## Downward air speed in the middle of a downdraft (units/s). Each downdraft can scale this.
@export var downdraft_strength := 3.5

@export_group("Collisions")
## A hit with at least this much speed straight into the surface can end the run...
@export var crash_impact_speed := 3.0
## ...if it is also at least this steep (0 = grazing, 90 = straight on).
@export var head_on_angle_deg := 50.0
## Touches softer than this count as resting or sliding contact, not a bounce.
@export var bounce_min_impact := 0.8
## How much of the into-the-wall speed bounces back out.
@export var bounce_restitution := 0.35
## Fraction of speed kept after a glancing bump.
@export var glance_speed_keep := 0.8
## Slow-down while sliding along the floor (units/s^2).
@export var slide_friction := 5.0
## The run ends when the plane is slower than this (units/s)...
@export var stop_speed := 0.35
## ...for this long (seconds).
@export var stop_time := 0.4

@export_group("Controls")
## Tilt sensitivity. 2.0 = half as much tilt for the same response.
@export var sensitivity := 1.0
## Phone tilt away from "level" that gives full input at sensitivity 1 (degrees).
@export var full_tilt_deg := 25.0
## Small tilts inside this angle are ignored (degrees).
@export var tilt_dead_zone_deg := 2.0
## Smoothing of tilt input. Higher = snappier, lower = smoother.
@export var tilt_smoothing := 12.0
## Flip these if a phone reports its tilt axes the other way round.
@export var invert_tilt_pitch := false
@export var invert_tilt_roll := false
## How quickly keyboard input ramps to full (per second).
@export var key_response := 4.0

@export_group("Camera")
## How far behind and above the plane the chase camera sits (units).
@export var camera_distance := 3.4
@export var camera_height := 1.0
## Whenever the plane climbs (mostly in rising air, but also pulling up from a dive or after a
## bounce), the camera also rises this many seconds' worth of the climb, so it looks down on the
## plane rather than seeing it edge-on.
@export var camera_lift_lead := 0.25
## How far ahead of the plane the camera looks (units).
@export var camera_look_ahead := 3.0
## How quickly the camera catches up with the plane and its heading (per second).
## Lower = lazier and smoother, higher = tighter.
@export var camera_follow_speed := 3.5
@export var camera_look_speed := 6.0
## How much the camera leans with the plane's bank (0 = never, 1 = fully).
@export_range(0.0, 1.0) var camera_lean := 0.25
## Field of view (degrees). Wider feels faster; narrower feels calmer.
@export_range(40.0, 110.0) var camera_fov := 70.0
## Outdoors the view widens to this field of view (degrees), easing over `camera_fov_ease`
## seconds: the world opens up after the window.
@export_range(40.0, 110.0) var camera_fov_outside := 80.0
@export var camera_fov_ease := 1.5
## Crossing the Gap's saddle, the view widens by `camera_fov_gap_kick` degrees over
## `camera_fov_kick_in` seconds and eases back over `camera_fov_kick_out`.
@export var camera_fov_gap_kick := 5.0
@export var camera_fov_kick_in := 0.4
@export var camera_fov_kick_out := 1.6
## The camera aims this far above the plane's path ahead (units).
@export var camera_look_above := 0.3
## Flying the balloon outdoors (it is bigger from behind than the plane), the camera sits higher and
## aims higher, so the balloon sits below the horizon and doesn't hide what it flies toward.
@export var camera_height_balloon := 1.6
@export var camera_look_above_balloon := 0.7
## Opening shot: seconds to ease from the kid's eye into the chase position.
@export var camera_intro_duration := 0.65
## Camera shake (units) on a bump and on a crash, dying away at `shake_fade` units per second.
@export var bump_shake := 0.04
@export var crash_shake := 0.12
@export var shake_fade := 0.8

@export_group("Sound")
## Loudness of each sound (decibels; 0 = as recorded, -6 = about half as loud). A bump's tap
## is quieter still when the bump is soft.
@export var chime_volume_db := -5.0
@export var downdraft_volume_db := -4.0
@export var tap_volume_db := -3.0
@export var crumple_volume_db := -1.0
@export var pop_volume_db := -3.0
@export var style_good_volume_db := -6.0
@export var style_perfect_volume_db := -4.0
@export var whoosh_volume_db := -6.0
## A close call: rushing past a surface at `close_call_speed` (units/s) or faster, within
## `close_call_distance` units of it, and getting clear again without touching it, gives a
## soft whoosh and a swell of wind (`close_call_db` louder, fading over `close_call_fade`
## seconds); at most one every `close_call_cooldown` seconds.
@export var close_call_distance := 1.0
@export var close_call_speed := 7.5
@export var close_call_db := 5.0
@export var close_call_fade := 0.5
@export var close_call_cooldown := 1.5
## A bump's tap: full loudness at this impact speed (units/s) and above, never quieter than
## `tap_min_loudness` (0..1); its pitch varies at random between these two.
@export var tap_full_strength := 4.0
@export_range(0.01, 1.0) var tap_min_loudness := 0.35
@export_range(0.1, 4.0) var tap_pitch_min := 0.9
@export_range(0.1, 4.0) var tap_pitch_max := 1.15
## Wind loudness (0..1) at or below `wind_quiet_speed`, rising to `wind_loud` at
## `wind_loud_speed` (airspeed, units/s).
@export_range(0.001, 1.0) var wind_quiet := 0.14
@export_range(0.001, 1.0) var wind_loud := 0.8
@export var wind_quiet_speed := 5.0
@export var wind_loud_speed := 11.0
## Wind pitch at those two speeds.
@export_range(0.1, 4.0) var wind_pitch_low := 0.85
@export_range(0.1, 4.0) var wind_pitch_high := 1.45
## How quickly the wind's loudness and pitch follow a change of airspeed (per second).
## Higher = the wind swells sooner in a dive.
@export var wind_swell_rate := 6.0
@export var wind_pitch_rate := 3.0
## Bursting out of the window: a gust of wind this much louder (decibels), fading away over
## `window_gust_fade` seconds.
@export var window_gust_db := 6.0
@export var window_gust_fade := 1.5
## Crossing the Gap's saddle the first time: a gust of wind that swells by `gap_gust_db` and
## fades over `gap_gust_fade` seconds, with a whoosh.
@export var gap_gust_db := 4.0
@export var gap_gust_fade := 1.2
## Coming down on the water.
@export var splash_db := -8.0
## Flying into the ridge's rising air: a swell of breeze this much louder, fading over
## `ridge_swell_fade` seconds.
@export var ridge_swell_db := 3.0
@export var ridge_swell_fade := 1.0
## Flying back into the same air within `chime_repeat_window` seconds (once a lap while
## circling) chimes this much quieter (decibels), so the lap's rhythm doesn't nag.
@export var chime_repeat_db := -4.0
@export var chime_repeat_window := 12.0
## The first time outdoors that the plane flies into rising air below `circle_hint_below` (y),
## a hint says to keep circling, for `circle_hint_seconds`.
@export var circle_hint_below := 18.0
@export var circle_hint_seconds := 2.5
## The wind never gets louder than this (decibels), even with a swell on top of a fast dive.
## (wind.wav peaks at -4.4 dB full scale, so at +2 the loudest wind still peaks below -2.)
@export var wind_max_db := 2.0

@export_group("Variometer")
## "You're in lift": soft beeps while the plane climbs in rising air at least `vario_air_min`
## (units/s) and is itself climbing at `vario_climb_min` or more; they stop once the climb drops
## below `vario_climb_stop`. From `vario_climb_min` up to `vario_climb_full` the beeps come
## faster (seconds between them), higher (pitch) and louder (decibels). Keep
## `vario_climb_stop` below `vario_climb_min`.
@export var vario_air_min := 0.4
@export var vario_climb_min := 0.3
@export var vario_climb_stop := 0.1
@export var vario_climb_full := 3.5
@export_range(0.1, 2.0) var vario_interval_slow := 0.45
@export_range(0.1, 2.0) var vario_interval_fast := 0.15
@export_range(0.1, 4.0) var vario_pitch_low := 1.0
@export_range(0.1, 4.0) var vario_pitch_high := 1.7
@export var vario_db_quiet := -14.0
@export var vario_db_loud := -7.0

@export_group("Lift feel")
## "Lift lost": a soft sigh when the beeps stop because the plane flew out of the side of
## rising air outdoors, so the player knows to turn back. It needs the beeps to have run for
## `lift_lost_min_on` seconds (a quick pass doesn't sigh), the plane to be more than
## `lift_lost_top_margin` below the top of that air (topping out is silent), the air at the
## plane to have dropped to `lift_lost_air_drop` of the strongest felt during the climb (pulling
## out into a dive in the middle of a thermal isn't lost lift), and `lift_lost_cooldown`
## seconds since the last sigh.
@export var lift_lost_min_on := 1.5
@export var lift_lost_top_margin := 3.0
@export_range(0.0, 1.0) var lift_lost_air_drop := 0.5
@export var lift_lost_cooldown := 4.0
@export var lift_lost_db := -15.0
## Outdoor thermals drift downwind (toward -X) at `thermal_drift_speed` (units/s), taking their
## cloud and birds along, up to `thermal_drift_max` times their radius. Each one starts the first
## time the plane comes within `thermal_drift_wake` radii of it, so it is always where its cloud
## said when you arrive; circling pilots then re-centre on the beeps.
@export var thermal_drift_speed := 0.5
@export_range(0.0, 1.0) var thermal_drift_max := 0.5
@export var thermal_drift_wake := 1.5
## Once the plane has climbed to within `cloud_thin_below_top` of a thermal's top (inside it),
## that thermal's cloud thins over `cloud_thin_seconds`: its puffs shrink to `cloud_thin_scale`,
## spread out to `cloud_thin_spread` times as far apart, and fade toward the sky. Looks only:
## the lift is unchanged, so going back to an old thermal still works.
@export var cloud_thin_below_top := 2.5
@export var cloud_thin_seconds := 8.0
@export_range(0.1, 1.0) var cloud_thin_scale := 0.55
@export_range(1.0, 3.0) var cloud_thin_spread := 1.3
## A gull joins you on each ridge (the valley's and the bluff) once a run, after `gull_wait` seconds flying along its
## lift, and soars `gull_side` to the hill side, `gull_up` up and `gull_ahead` ahead of you
## (times `gull_balloon_scale` around the balloon) for `gull_stay` seconds, catching up at rate
## `gull_follow` (per second), never lower than `gull_min_ground` over the hillside. One call
## at `gull_call_db` as it arrives. Looks only.
@export_range(0.1, 10.0) var gull_wait := 1.5
@export var gull_stay := 6.0
@export var gull_side := 3.5
@export var gull_up := 0.8
@export var gull_ahead := 1.0
@export var gull_balloon_scale := 1.2
@export var gull_follow := 3.0
@export var gull_min_ground := 2.5
@export var gull_call_db := -12.0
## Low ticks while flying in sinking air outdoors (over the lake) at `sink_tick_air` or below
## (units/s), coming faster and louder down to `sink_tick_air_full` (the lake's strongest sink).
## Never indoors: the stair downdraft is a thrill with its own whoosh.
@export var sink_tick_air := -0.3
@export var sink_tick_air_full := -0.4
@export var sink_tick_interval_slow := 0.8
@export var sink_tick_interval_fast := 0.5
@export var sink_tick_db_quiet := -21.0
@export var sink_tick_db_loud := -16.0

@export_group("Pop-ups and end card")
## Style pop-up size (1 = normal text) as it pops in and once it has grown; a perfect pass
## starts smaller and grows bigger, so it bounces more.
@export var popup_start_scale := 0.7
@export var popup_scale := 1.0
@export var popup_perfect_start_scale := 0.5
@export var popup_perfect_scale := 1.25
## Seconds the pop-up takes to grow, stays, and takes to fade.
@export var popup_grow_time := 0.25
@export var popup_hold := 0.7
@export var popup_perfect_hold := 0.9
@export var popup_fade_time := 0.35
## Seconds before the end card appears after a crash, and after the plane comes to rest.
@export var card_delay_crash := 0.45
@export var card_delay_landed := 0.4

@export_group("The plane's look")
## How big the plane (or balloon) is drawn. Looks only: it collides, lifts and flies exactly
## the same at any size.
@export_range(0.5, 2.5) var look_scale := 1.3
## The balloon (picked on the end card) is drawn mostly upright: it leans this fraction of the
## plane's bank into turns and this fraction of its pitch into climbs and dives.
@export_range(0.0, 1.0) var balloon_bank_lean := 0.4
@export_range(0.0, 1.0) var balloon_pitch_lean := 0.25
## The balloon's string: length (units, before `look_scale`) and how quickly its swing dies away
## (0 = never, 1 = at once).
@export var balloon_string_length := 1.3
@export_range(0.0, 1.0) var balloon_string_damping := 0.15
## How quickly the drawn plane swings round to its heading (per second).
@export var visual_turn_speed := 14.0
## A bump makes the plane wobble: this far (radians), this fast, dying away at `bump_wobble_fade`
## per second.
@export var bump_wobble_angle := 0.35
@export var bump_wobble_speed := 32.0
@export var bump_wobble_fade := 2.5

@export_group("Launch and scoring")
## Speed of the throw (units/s).
@export var launch_speed := 6.5
## World scale used when showing distance: 4 units = 1 metre.
@export var units_per_meter := 4.0

@export_group("Scoring")
## Points for each metre of progress along the course.
@export var points_per_meter := 10.0
## Style points: full marks while the average distance from the optimal path stays within
## this fraction of the corridor radius...
@export_range(0.0, 0.9) var style_full_fraction := 0.25
## ...then the award falls smoothly to zero at the corridor edge. Above 1 the fall is
## steeper near the path (harder); below 1 it is gentler.
@export_range(0.25, 4.0) var style_curve_power := 1.0
## A pass at or above this quality (0..1) gets the "perfect" pop-up and sound. At 0.95, with the
## curve above, that means averaging within about 35% of the corridor's radius of the path.
@export_range(0.0, 1.0) var style_perfect_quality := 0.95
## A moment starts counting once the plane comes within this many corridor radii of its
## path; skipped stretches count as this far off.
@export_range(1.0, 4.0) var style_capture_factor := 2.0
## Points and corridor radius (units) for each style moment. The optimal paths are part of
## the course layout (scripts/course.gd).
@export var style_moments := {
	"bedroom_turn": {"points": 100, "radius": 2.5},
	"sunbeam": {"points": 80, "radius": 2.0},
	"stair_downdraft": {"points": 120, "radius": 1.5},
	"landing_turn": {"points": 150, "radius": 3.0},
	"radiator": {"points": 100, "radius": 2.5},
	"lamp": {"points": 150, "radius": 1.5},
	"kettle": {"points": 100, "radius": 2.5},
	"window": {"points": 150, "radius": 2.0},
	"ridge_run": {"points": 120, "radius": 4.0},
	"gap": {"points": 150, "radius": 4.0},
}
## Outdoors, points for every second in the air, up to `airtime_max_seconds` (so circling
## forever doesn't pay forever).
@export var airtime_points_per_second := 5.0
@export var airtime_max_seconds := 90.0
## Coming to rest (not crashing) on a landing spot outdoors pays a bonus. Spots are in
## Course.landing_spots().
@export var landing_bonus := {
	"lavender": 200,
	"picnic": 400,
	"island": 500,
	"beach": 250,
}

@export_group("Endless")
## The tailwind in Endless (u/s toward -Z): the air carries the flyer along on top of its own
## flight, fading out within `endless_wind_ground_fade` of the ground so slides and landings look as
## they do in the Course. The flight model is untouched. Zero everywhere in the Course.
## It rises with distance: from `endless_wind_start` at the start to `endless_wind_full` at
## `endless_full_distance_m`, then `endless_wind_rise` more each 100 m up to `endless_wind_max`.
@export var endless_wind_start := 1.0
@export var endless_wind_full := 3.0
@export var endless_wind_rise := 0.1
@export var endless_wind_max := 3.5
@export var endless_wind_ground_fade := 4.0
## Difficulty reaches 1 at this many metres.
@export var endless_full_distance_m := 1000.0
## Recentring: once the flyer passes this world z, the whole world moves this far back toward +z
## (a whole number of tiles), so positions stay small enough for the phone's floats.
@export var endless_recentre_z := -4600.0
@export var endless_recentre_tiles := 42
## A piece is placed only if its need is at least this far below the height a good pilot is sure
## to have (x at difficulty 0, y at difficulty 1).
@export var endless_margin := Vector2(6.0, 3.0)
## A thermal drifts with the wind once reached; after drifting this far (x at difficulty 0, y at
## 1) its lift fades away over `endless_thermal_fade` seconds and its cloud thins.
@export var endless_thermal_life := Vector2(36.0, 24.0)
@export var endless_thermal_fade := 4.0
## Pieces are placed this many tiles ahead of the plane and kept this many behind.
@export var endless_tiles_ahead := 5
@export var endless_tiles_behind := 1
## Tiles fade out of the fog: visibility range end and its fade margin (units).
@export var endless_tile_fade := Vector2(440.0, 60.0)
## The look back over the bowl at the start of a session (seconds), and the fade-in on a retry.
@export var endless_intro_seconds := 1.4
@export var endless_retry_fade := 0.2
## Seconds from a touchdown (or splashdown) to the end card, so the slide shows.
@export var endless_card_delay_touchdown := 0.6
## Stars: pickup radius from the flyer's centre (units), what a big star and a full arc are worth
## (in stars), points per star, the pickup sound's level, and how many semitones it can rise.
@export var star_pickup_radius := 1.4
@export var big_star_pickup_radius := 1.5
## A spiral's stars round a thermal are taken from further away: nobody circles exactly, and
## they re-form ahead of you after each one (see EndlessStars._lay_spiral()).
@export var spiral_pickup_radius := 3.0
@export var big_star_value := 10
@export var arc_bonus := 5
@export var points_per_star := 10
@export var star_db := -10.0
@export var star_pitch_steps := 12
## Touching a wire, kite ring, washing or sail keeps this much of the speed (never a crash).
@export_range(0.1, 1.0) var snag_speed_keep := 0.75
## The height bar on the left fills over this many units above the ground, and warns below the
## second (units).
@export var height_bar_full := 30.0
@export var height_bar_warn := 4.0
## Passing through an arch at speed widens the view this many degrees for a moment.
@export var arch_pass_fov_kick := 3.0
@export var arch_pass_speed := 7.5
