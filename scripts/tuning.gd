class_name Tuning
extends Resource
## =============================================================================
##  PAPER PLANE TUNING: every number that changes how the game feels lives here.
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
@export_range(40.0, 110.0) var camera_fov_outside := 76.0
@export var camera_fov_ease := 1.5
## The camera aims this far above the plane's path ahead (units).
@export var camera_look_above := 0.3
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
## The wind never gets louder than this (decibels), even with a swell on top of a fast dive.
## (wind.wav peaks at -4.4 dB full scale, so at +2 the loudest wind still peaks below -2.)
@export var wind_max_db := 2.0

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
}
