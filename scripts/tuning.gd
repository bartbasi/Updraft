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

@export_group("Launch and scoring")
## Speed the plane is launched at (units/s).
@export var launch_speed := 6.0
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
## A pass at or above this quality (0..1) gets the "perfect" pop-up and sound.
@export_range(0.0, 1.0) var style_perfect_quality := 0.85
## A moment starts counting once the plane comes within this many corridor radii of its
## path; skipped stretches count as this far off.
@export_range(1.0, 4.0) var style_capture_factor := 2.0
## Points and corridor radius (units) for each style moment. The optimal paths are part of
## the course layout (scripts/course.gd).
@export var style_moments := {
	"bedroom_turn": {"points": 100, "radius": 2.5},
	"sunbeam": {"points": 80, "radius": 2.0},
	"stair_downdraft": {"points": 120, "radius": 2.0},
	"landing_turn": {"points": 150, "radius": 2.0},
	"radiator": {"points": 100, "radius": 2.5},
	"lamp": {"points": 150, "radius": 1.5},
	"kettle": {"points": 100, "radius": 2.5},
	"window": {"points": 150, "radius": 2.0},
}
