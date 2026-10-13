# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name HowToFly
extends RefCounted
## The player's guide, shown as About's "How to fly" page: the controls, how flying works, every
## kind of rising and sinking air and how to spot it, what the sounds mean, how each mode scores,
## and tips. A paragraph starting "# " is a heading. Keep it true to the game: when something here
## changes, change this too.

const TEXT := """Fly as far as you can. You are always gliding gently down; rising air takes you back up.

# Controls

Hold your phone sideways, like a steering wheel.

Tilt the top edge away from you to dive: the nose drops and you speed up.

Tilt the top edge toward you to climb: the nose rises and you slow down. Hold it too long and you stall: the nose drops and you lose height until you have speed again.

Tilt left or right to bank and turn. The further you tilt, the tighter the turn.

However you are holding the phone when a flight starts counts as level, so start in a comfortable position.

Settings (on the end card) has tilt sensitivity, sound on or off, and "Swap climb and dive" if you prefer it the other way round.

Back steps out of About and Settings; from anywhere else it closes the game.

On a computer: Up or W dives, Down or S climbs, Left/Right or A/D turn, and Escape steps back.

The red balloon and the paper plane fly exactly the same. Swap between them on the end card.

# How flying works

You are always gliding gently downhill. Height is what keeps you going: the only way to gain it is to find rising air.

Speed and height trade with each other. Dive to gain speed (to reach somewhere, or to squeeze through a gap); climb to trade speed back for a little height.

A gentle touch on a wall, the floor or a hillside bounces or slides you along. Flying hard and head-on into something crashes: the plane crumples and the balloon pops.

# Rising air: where to find it

Rising air lifts you. When rising air is carrying you up, you hear soft beeps, faster and higher the stronger it is. Each kind has a look of its own:

Warm air over the radiator, steam from the kettle, and sunbeams (through a window in the gallery, and through the skylight): a soft shimmer, drifting dust, or a shaft of light. Fly into them to climb.

Thermals outdoors: warm air rising off sun-warmed ground (the hay field, the barn roof, the ploughed field, the chalk pit, the beach sand, the barley field). Look for drifting motes, a faint shimmering column, a fluffy cloud sitting on top, and birds circling near the top. To use one, keep turning in a circle inside it; you climb as you go round. Once you reach a thermal it starts to drift slowly with the breeze, so follow the beeps and keep re-centring. Its cloud thins once you have climbed it, a hint to go and find the next.

Smoke: the bonfire's smoke and chimney smoke rise strongly. Fly through a plume for a quick lift.

Ridges: where the wind blows up a hillside (the long ridge on the left of the valley, and the bluff above the lake) the air rises all along the slope. Dandelion seeds float up it. Fly along the slope, a little way out from it, and you climb as you go. Don't touch it: in Endless, landing on a hillside ends the run. A gull may come and fly beside you.

Cloud streets (Endless): a straight line of clouds over a long band of rising air. Fly along underneath them.

# Sinking air: what to watch for

Sinking air pushes you down. It is useful for a quick dive, but costly when you need height.

The stair hall has a cool downdraft: pale wisps falling. Diving with it is fast.

Over the lake the air sinks gently. Low ticks tell you, faster the stronger it sinks. Crossing the water costs some height, so go over it high.

Outdoors, when you fly out of the side of rising air you hear a soft sigh: you have lost the lift, so turn back into it.

# Sounds

A chime: you have flown into rising air (each kind has its own note).

Beeps: you are climbing; faster and higher means stronger lift.

A sigh (outdoors): you have just flown out of the lift.

Low ticks: you are in sinking air.

A whoosh: you rushed close past something without touching it, or through an arch at speed.

A tink: a star. Each star in a row along a line rings a note higher.

A bell: through a kite ring.

A flutter: a kite ring snagged you.

A tap: a bump.

# The Course

A kid lets the balloon go (or throws the paper plane) in the bedroom. Fly out of the door, along the gallery, down the stairs, through the living room and the kitchen, and out of the window into the valley. From there go where you like: thermal to thermal down the valley, along the ridge, or through the Gap in the far hills to the lake.

Distance: 10 points for every metre along the way.

Style: ten moments pay extra for flying close to the best line through them: the door turn, the sunbeam, the downdraft dive, the landing turn, the radiator lift, under the lamp, the kettle steam, out of the window, the ridge run, and through the Gap. Golden pop-ups mean a near-perfect pass.

Airtime: 5 points for every second in the air outdoors, up to 90 seconds.

Landings: come to rest in the lavender (+200), on the picnic blanket (+400), on the island (+500) or on the beach (+250). Coming down on the water is a splashdown: no bonus, but not a crash.

A flight ends when you come to rest or crash. Come to rest outdoors once, without crashing, and Endless opens.

# Endless

Endless starts in the air beyond the lake, above a country that never ends. A breeze behind you carries you along. Stay up as long as you can: the run ends the moment you touch the ground, or crash. (Turning round and flying back past the start ends it too.)

The bar on the left shows your height above the ground. It turns coral and pulses when you are very low.

Stars: 1 each; big stars are worth 10. Stars lie in lines along the best way through, so they show you where to fly. Take every star of a line for a bonus (+5). Missing one breaks its line, and the rest dim.

The Barley Field's spiral starts low over the field. Dive down to it, then circle: the stars form in front of you as you climb.

Kite rings: fly through for a bell. Touching a ring snags you: you lose some speed, but never crash.

The viaduct's wall is solid stone: dive through an arch (the middle one holds a big star) or go over the top. At speed you will hear the rush of it.

Thermals here drift with the breeze, and fade once they have drifted a while. Climb, then move on.

Bumps and snags break the line of stars you are on, but the run goes on.

Score: 10 points for every metre and 10 for every star. Your stars are banked after every run.

# Tips

Arrive high: it is much easier to lose height than to find it.

In a thermal, keep turning steadily. If the beeps fade, you have drifted out: turn back toward where they were strongest.

Climb gently in rising air (just a little nose-up) and you rise faster than if you dive through it.

Give yourself time: line up with a gap or an arch early, then hold steady.

Watch the clouds and the birds. They mark the rising air before you can feel it.

Follow the stars: they lead into rising air.
"""
