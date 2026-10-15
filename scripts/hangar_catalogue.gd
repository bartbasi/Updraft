# Updraft. Copyright (C) 2026 Bart Basi.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name HangarCatalogue
extends RefCounted
## Everything the Hangar sells: looks for the balloon and the paper plane, and trails for both,
## bought with stars earned by flying (nothing in Updraft costs money). Prices live only here,
## never in the save; ids are never renamed or reused, so a save from any version means the same
## things. How each look is drawn is Looks'.

const BALLOON := "balloon"
const PAPER := "paper"
const TRAIL := "trail"
const SLOTS: Array[String] = [BALLOON, PAPER, TRAIL]
## Owned by everyone, free.
const STARTERS := {BALLOON: "red", PAPER: "plain", TRAIL: "none"}
## Scales every price (rounded to 5), for tuning the pace in one place.
const PRICE_SCALE := 1.0
## The Hangar's tabs, in order.
const TABS := {BALLOON: "Balloon", PAPER: "Paper plane", TRAIL: "Trails"}

## id -> [slot, name, price]. In each slot's order in the Hangar.
const ITEMS := {
	"red": [BALLOON, "Red", 0],
	"sky": [BALLOON, "Sky blue", 50],
	"sunflower": [BALLOON, "Sunflower", 75],
	"mint": [BALLOON, "Mint", 150],
	"lilac": [BALLOON, "Lilac", 150],
	"bubblegum": [BALLOON, "Bubblegum", 150],
	"twotone": [BALLOON, "Two-tone", 300],
	"candy": [BALLOON, "Candy stripes", 400],
	"polka": [BALLOON, "Polka dots", 600],
	"smiley": [BALLOON, "Smiley", 800],
	"starry": [BALLOON, "Starry night", 1200],
	"rainbow": [BALLOON, "Rainbow", 2000],
	"plain": [PAPER, "Plain", 0],
	"pink": [PAPER, "Pink paper", 50],
	"skypaper": [PAPER, "Blue paper", 75],
	"notebook": [PAPER, "Notebook", 100],
	"lemon": [PAPER, "Lemon paper", 150],
	"graph": [PAPER, "Graph paper", 200],
	"newspaper": [PAPER, "Newspaper", 400],
	"map": [PAPER, "Old map", 800],
	"waves": [PAPER, "Wave print", 1500],
	"none": [TRAIL, "No trail", 0],
	"ribbon": [TRAIL, "Ribbon", 250],
	"confetti": [TRAIL, "Paper confetti", 600],
	"petals": [TRAIL, "Blossom petals", 1200],
	"rainbowtrail": [TRAIL, "Rainbow ribbon", 2000],
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


static func slot_of(id: String) -> String:
	return ITEMS[id][0] if ITEMS.has(id) else ""


static func name_of(id: String) -> String:
	return ITEMS[id][1] if ITEMS.has(id) else id


## The price in stars (0 for a starter).
static func price(id: String) -> int:
	if not ITEMS.has(id):
		return 0
	return int(roundf(ITEMS[id][2] * PRICE_SCALE / 5.0) * 5.0)


static func is_starter(id: String) -> bool:
	return STARTERS.values().has(id)


## A slot's items, in the Hangar's order.
static func in_slot(slot: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in ITEMS:
		if ITEMS[id][0] == slot:
			out.append(id)
	return out


## A count of stars as the Hangar writes it: "600", "1,200".
static func stars_text(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## The cheapest item not owned (and not a starter), or "" when everything is owned.
static func cheapest_unowned(owned: Array) -> String:
	var best := ""
	for id: String in ITEMS:
		if is_starter(id) or owned.has(id):
			continue
		if best == "" or price(id) < price(best):
			best = id
	return best
