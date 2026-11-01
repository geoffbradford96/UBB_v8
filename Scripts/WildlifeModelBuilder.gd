extends RefCounted
class_name WildlifeModelBuilder

# =================================================================================
# GALACTIC WILDLIFE — 108 SPECIES REGISTRY & PROCEDURAL 3D ANATOMY BUILDER
# =================================================================================
# Keys:
#   title: Display name
#   archetype: PRIMATE, CROCODILIAN, SERPENT, CORVID, AVIAN_FLYER, AVIAN_WALKER,
#              INSECT, FLYING_INSECT, BEETLE, ARACHNID, SCORPION, CENTIPEDE,
#              SHARK, FISH, EEL, CRAB, QUADRUPED, TANK_MAMMAL, BIPED_HOPPER, TURTLE
#   c1: Primary body Color
#   c2: Secondary / belly / pattern Color
#   c3: Accent / beak / horn / fang / stinger Color
#   scale: Vector3 overall proportion
#   cost: Requisition cost
#   count: Spawn count per card
#   hp: Max HP per creature
#   spd: Movement speed
#   dmg: Attack damage
#   rng: Attack range
#   aspd: Attack speed (attacks per sec)
#   fly: bool (flies in air)
#   rock: bool (throws/drops rocks like Corvids)
#   peck: bool (rapid beak peck)
#   poison_dps: Poison damage per second (0 if none)
#   poison_ticks: Poison duration in seconds
#   proj: Ranged projectile type ("NONE", "ROCK", "VENOM", "ACID", "QUILL", "LIGHTNING", "TONGUE", "SONIC", "WEB")
#   armor: Max breakable natural armor (chitin/shell/scales)
#   cmdr: bool (Commander unit)
#   desc: Card description
# =================================================================================

const SPECIES_CATALOG: Dictionary = {
	# --- 1. COMMANDERS (6 APEX ALPHAS) ---
	"WildlifeAlphaGorillaCommander": {
		"title": "Alpha Silverback Commander", "archetype": "PRIMATE", "cmdr": true,
		"c1": Color(0.16, 0.16, 0.18), "c2": Color(0.75, 0.78, 0.82), "c3": Color(0.28, 0.25, 0.24),
		"scale": Vector3(1.55, 1.55, 1.55), "cost": 4.0, "count": 1, "hp": 520.0, "spd": 4.4, "dmg": 38.0, "rng": 2.4, "aspd": 1.1,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Colossal Silverback Ape Warlord. Chest-pounding roar grants +22% Speed & Attack Speed to nearby Wildlife."
	},
	"WildlifeMammothCommander": {
		"title": "Ancient Mammoth Commander", "archetype": "TANK_MAMMAL", "cmdr": true,
		"c1": Color(0.42, 0.26, 0.14), "c2": Color(0.30, 0.18, 0.10), "c3": Color(0.95, 0.92, 0.82),
		"scale": Vector3(1.75, 1.65, 1.80), "cost": 5.0, "count": 1, "hp": 680.0, "spd": 3.6, "dmg": 44.0, "rng": 2.8, "aspd": 0.85,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 120.0,
		"desc": "Towering Woolly Mammoth Matriarch with sweeping ivory tusks, thick hide, and primal herd leadership aura."
	},
	"WildlifeElderRavenCommander": {
		"title": "Elder Ravenlord Commander", "archetype": "CORVID", "cmdr": true,
		"c1": Color(0.08, 0.08, 0.12), "c2": Color(0.18, 0.14, 0.28), "c3": Color(0.85, 0.75, 0.25),
		"scale": Vector3(1.45, 1.45, 1.45), "cost": 4.0, "count": 1, "hp": 360.0, "spd": 5.8, "dmg": 28.0, "rng": 10.5, "aspd": 1.25,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "Flying Corvid Mastermind. Drops heavy boulders from the sky and rallies nearby avian & wildlife flocks."
	},
	"WildlifeApexCrocCommander": {
		"title": "Deinosuchus Croc Commander", "archetype": "CROCODILIAN", "cmdr": true,
		"c1": Color(0.18, 0.34, 0.16), "c2": Color(0.48, 0.46, 0.30), "c3": Color(0.92, 0.90, 0.80),
		"scale": Vector3(1.65, 1.45, 1.75), "cost": 4.0, "count": 1, "hp": 560.0, "spd": 4.0, "dmg": 42.0, "rng": 2.5, "aspd": 1.0,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 110.0,
		"desc": "Prehistoric Giant Crocodile King with heavy osteoderm scale armor, crushing jaws, and reptile pack aura."
	},
	"WildlifeQueenHornetCommander": {
		"title": "Empress Hornet Commander", "archetype": "FLYING_INSECT", "cmdr": true,
		"c1": Color(0.95, 0.62, 0.05), "c2": Color(0.12, 0.10, 0.08), "c3": Color(0.85, 0.15, 0.10),
		"scale": Vector3(1.45, 1.45, 1.45), "cost": 4.0, "count": 1, "hp": 380.0, "spd": 5.5, "dmg": 22.0, "rng": 7.5, "aspd": 1.35,
		"fly": true, "rock": false, "peck": false, "poison_dps": 8.0, "poison_ticks": 4, "proj": "VENOM", "armor": 60.0,
		"desc": "Flying Giant Hornet Queen. Fires venomous stingers and periodically spawns free Hornet swarmers in battle!"
	},
	"WildlifeMegalodonCommander": {
		"title": "Apex Great White Commander", "archetype": "SHARK", "cmdr": true,
		"c1": Color(0.28, 0.36, 0.46), "c2": Color(0.88, 0.90, 0.92), "c3": Color(0.95, 0.95, 0.95),
		"scale": Vector3(1.65, 1.55, 1.70), "cost": 4.0, "count": 1, "hp": 540.0, "spd": 4.6, "dmg": 45.0, "rng": 2.5, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Colossal Land-Striding Apex Shark. Serrated jaws tear targets apart while Blood Frenzy aura hastens allies."
	},

	# --- 2. PRIMATES & APES (8 CARDS) ---
	"WildlifeMonkey": {
		"title": "Small Monkey Troop", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.48, 0.32, 0.18), "c2": Color(0.76, 0.62, 0.45), "c3": Color(0.88, 0.72, 0.58),
		"scale": Vector3(0.68, 0.68, 0.68), "cost": 1.0, "count": 6, "hp": 35.0, "spd": 6.2, "dmg": 8.0, "rng": 1.6, "aspd": 1.6,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Troop of 6 small agile monkeys with curled tails. Ultra-cheap, hyper-fast swarming scratch and bite attacks."
	},
	"WildlifeGorilla": {
		"title": "Silverback Gorilla", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.18, 0.18, 0.20), "c2": Color(0.68, 0.72, 0.75), "c3": Color(0.25, 0.25, 0.28),
		"scale": Vector3(1.22, 1.20, 1.22), "cost": 3.0, "count": 2, "hp": 190.0, "spd": 4.5, "dmg": 26.0, "rng": 2.0, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Pair of muscular Silverback Gorillas. Knuckle-walking heavy primate bruisers that smash frontlines."
	},
	"WildlifeChimpanzee": {
		"title": "Chimpanzee Pack", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.22, 0.18, 0.15), "c2": Color(0.68, 0.54, 0.44), "c3": Color(0.85, 0.72, 0.60),
		"scale": Vector3(0.88, 0.88, 0.88), "cost": 2.0, "count": 4, "hp": 65.0, "spd": 5.5, "dmg": 14.0, "rng": 1.8, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Pack of 4 frenzied Chimpanzees. Fast, coordinated melee brawlers with relentless pouncing strikes."
	},
	"WildlifeMandrill": {
		"title": "Mandrill Troop", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.32, 0.28, 0.22), "c2": Color(0.15, 0.45, 0.88), "c3": Color(0.92, 0.18, 0.18),
		"scale": Vector3(0.95, 0.95, 0.95), "cost": 2.0, "count": 3, "hp": 85.0, "spd": 5.2, "dmg": 18.0, "rng": 1.8, "aspd": 1.3,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "3 war-faced Mandrills with vivid blue-and-crimson snouts and long canine fangs."
	},
	"WildlifeOrangutan": {
		"title": "Sumatran Orangutan", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.75, 0.34, 0.12), "c2": Color(0.45, 0.24, 0.12), "c3": Color(0.35, 0.20, 0.10),
		"scale": Vector3(1.12, 1.12, 1.12), "cost": 3.0, "count": 2, "hp": 165.0, "spd": 4.2, "dmg": 22.0, "rng": 6.5, "aspd": 1.0,
		"fly": false, "rock": true, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "2 long-armed red Orangutans that hurl heavy stones and branches at enemies from mid-range."
	},
	"WildlifeBaboon": {
		"title": "Savanna Baboon Pack", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.52, 0.44, 0.32), "c2": Color(0.65, 0.56, 0.42), "c3": Color(0.88, 0.45, 0.45),
		"scale": Vector3(0.86, 0.86, 0.86), "cost": 2.0, "count": 4, "hp": 60.0, "spd": 5.6, "dmg": 13.0, "rng": 1.8, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "4 barking Savanna Baboons that rush down lanes in a ferocious dog-muzzled troop."
	},
	"WildlifeLemur": {
		"title": "Ring-Tailed Lemur Mob", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.55, 0.55, 0.58), "c2": Color(0.92, 0.92, 0.94), "c3": Color(0.12, 0.12, 0.14),
		"scale": Vector3(0.62, 0.62, 0.62), "cost": 1.0, "count": 7, "hp": 28.0, "spd": 6.5, "dmg": 7.0, "rng": 1.5, "aspd": 1.7,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Mob of 7 hyper-agile Ring-Tailed Lemurs. Extremely cheap, fast-leaping distraction swarm."
	},
	"WildlifeGibbon": {
		"title": "Acrobatic Gibbon Trio", "archetype": "PRIMATE", "cmdr": false,
		"c1": Color(0.25, 0.22, 0.18), "c2": Color(0.88, 0.85, 0.78), "c3": Color(0.18, 0.16, 0.14),
		"scale": Vector3(0.80, 0.85, 0.80), "cost": 2.0, "count": 4, "hp": 52.0, "spd": 6.4, "dmg": 12.0, "rng": 1.9, "aspd": 1.5,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "4 long-armed Gibbons that bound across the battlefield at breakneck speed."
	},

	# --- 3. CROCODILIANS, LIZARDS & TURTLES (12 CARDS) ---
	"WildlifeCrocodile": {
		"title": "Nile Crocodile", "archetype": "CROCODILIAN", "cmdr": false,
		"c1": Color(0.22, 0.38, 0.18), "c2": Color(0.52, 0.50, 0.32), "c3": Color(0.92, 0.90, 0.82),
		"scale": Vector3(1.15, 1.05, 1.25), "cost": 3.0, "count": 2, "hp": 175.0, "spd": 4.2, "dmg": 28.0, "rng": 2.1, "aspd": 1.0,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 45.0,
		"desc": "2 armored Nile Crocodiles with ridged osteoderm scales and bone-crushing death-roll jaws."
	},
	"WildlifeSaltwaterCroc": {
		"title": "Saltwater Bull Croc", "archetype": "CROCODILIAN", "cmdr": false,
		"c1": Color(0.18, 0.28, 0.16), "c2": Color(0.45, 0.44, 0.28), "c3": Color(0.95, 0.92, 0.84),
		"scale": Vector3(1.38, 1.25, 1.48), "cost": 3.0, "count": 1, "hp": 290.0, "spd": 4.0, "dmg": 36.0, "rng": 2.3, "aspd": 0.95,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 70.0,
		"desc": "Massive apex Saltwater Crocodile with thick armored hide and the strongest bite force on Earth."
	},
	"WildlifeAlligator": {
		"title": "Swamp Alligator Pack", "archetype": "CROCODILIAN", "cmdr": false,
		"c1": Color(0.14, 0.20, 0.14), "c2": Color(0.38, 0.40, 0.30), "c3": Color(0.90, 0.88, 0.78),
		"scale": Vector3(1.08, 1.0, 1.15), "cost": 2.0, "count": 2, "hp": 145.0, "spd": 4.4, "dmg": 22.0, "rng": 2.0, "aspd": 1.1,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 35.0,
		"desc": "2 dark broad-snouted American Alligators that lunge from ambush."
	},
	"WildlifeCaiman": {
		"title": "Spectacled Caiman Trio", "archetype": "CROCODILIAN", "cmdr": false,
		"c1": Color(0.28, 0.42, 0.20), "c2": Color(0.58, 0.55, 0.36), "c3": Color(0.92, 0.90, 0.80),
		"scale": Vector3(0.88, 0.85, 0.95), "cost": 2.0, "count": 3, "hp": 95.0, "spd": 4.8, "dmg": 16.0, "rng": 1.9, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 25.0,
		"desc": "3 agile river Caimans with rapid snapping jaws and scaly backs."
	},
	"WildlifeGharial": {
		"title": "Gharial Crocodilian", "archetype": "CROCODILIAN", "cmdr": false,
		"c1": Color(0.32, 0.40, 0.26), "c2": Color(0.62, 0.60, 0.45), "c3": Color(0.94, 0.94, 0.88),
		"scale": Vector3(1.05, 0.95, 1.25), "cost": 2.0, "count": 2, "hp": 130.0, "spd": 4.6, "dmg": 19.0, "rng": 2.1, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 30.0,
		"desc": "2 long-snouted Gharials with 110 needle-sharp interlocking teeth for high-speed strikes."
	},
	"WildlifeKomodoDragon": {
		"title": "Komodo Dragon", "archetype": "LIZARD", "cmdr": false,
		"c1": Color(0.34, 0.30, 0.24), "c2": Color(0.46, 0.40, 0.32), "c3": Color(0.85, 0.22, 0.25),
		"scale": Vector3(1.12, 1.05, 1.18), "cost": 3.0, "count": 2, "hp": 160.0, "spd": 4.6, "dmg": 22.0, "rng": 2.0, "aspd": 1.1,
		"fly": false, "rock": false, "peck": false, "poison_dps": 7.0, "poison_ticks": 5, "proj": "NONE", "armor": 30.0,
		"desc": "2 giant Komodo Monitor Lizards whose toxic anticoagulant bite inflicts lethal Poison over time!"
	},
	"WildlifeMonitorLizard": {
		"title": "Nile Monitor Lizard", "archetype": "LIZARD", "cmdr": false,
		"c1": Color(0.26, 0.34, 0.20), "c2": Color(0.75, 0.68, 0.28), "c3": Color(0.85, 0.25, 0.30),
		"scale": Vector3(0.90, 0.88, 0.98), "cost": 2.0, "count": 3, "hp": 80.0, "spd": 5.3, "dmg": 14.0, "rng": 1.8, "aspd": 1.3,
		"fly": false, "rock": false, "peck": false, "poison_dps": 3.0, "poison_ticks": 3, "proj": "NONE", "armor": 0.0,
		"desc": "3 fast whip-tailed Monitor Lizards that slash with claws and venomous jaws."
	},
	"WildlifeGilaMonster": {
		"title": "Venomous Gila Monster", "archetype": "LIZARD", "cmdr": false,
		"c1": Color(0.14, 0.12, 0.12), "c2": Color(0.95, 0.48, 0.18), "c3": Color(0.95, 0.35, 0.15),
		"scale": Vector3(0.78, 0.78, 0.82), "cost": 2.0, "count": 3, "hp": 85.0, "spd": 4.2, "dmg": 13.0, "rng": 1.7, "aspd": 1.15,
		"fly": false, "rock": false, "peck": false, "poison_dps": 8.0, "poison_ticks": 5, "proj": "NONE", "armor": 20.0,
		"desc": "3 orange-and-black beaded Gila Monsters that clamp onto targets and chew potent neurotoxin into them."
	},
	"WildlifeChameleon": {
		"title": "Horned Chameleon", "archetype": "LIZARD", "cmdr": false,
		"c1": Color(0.22, 0.72, 0.28), "c2": Color(0.55, 0.88, 0.22), "c3": Color(0.92, 0.45, 0.55),
		"scale": Vector3(0.85, 0.90, 0.85), "cost": 2.0, "count": 3, "hp": 70.0, "spd": 4.0, "dmg": 16.0, "rng": 8.0, "aspd": 1.2,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "TONGUE", "armor": 0.0,
		"desc": "3 Three-Horned Chameleons that lash enemies from range with ballistic sticky tongues!"
	},
	"WildlifeFrilledLizard": {
		"title": "Frilled Dragon Lizard", "archetype": "LIZARD", "cmdr": false,
		"c1": Color(0.62, 0.45, 0.26), "c2": Color(0.88, 0.52, 0.18), "c3": Color(0.95, 0.28, 0.12),
		"scale": Vector3(0.76, 0.82, 0.78), "cost": 1.0, "count": 4, "hp": 48.0, "spd": 5.8, "dmg": 10.0, "rng": 6.5, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 4.0, "poison_ticks": 3, "proj": "VENOM", "armor": 0.0,
		"desc": "4 fast-running Frilled Lizards with flared neck crests that spit stinging venom."
	},
	"WildlifeSnappingTurtle": {
		"title": "Alligator Snapping Turtle", "archetype": "TURTLE", "cmdr": false,
		"c1": Color(0.24, 0.28, 0.18), "c2": Color(0.42, 0.38, 0.26), "c3": Color(0.85, 0.82, 0.72),
		"scale": Vector3(1.10, 1.05, 1.12), "cost": 3.0, "count": 2, "hp": 180.0, "spd": 3.2, "dmg": 28.0, "rng": 1.9, "aspd": 0.9,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 85.0,
		"desc": "2 spiked-shell Alligator Snapping Turtles with heavy natural carapace armor and steel-shearing beaks."
	},
	"WildlifeGalapagosTortoise": {
		"title": "Giant Galapagos Tortoise", "archetype": "TURTLE", "cmdr": false,
		"c1": Color(0.28, 0.26, 0.22), "c2": Color(0.38, 0.35, 0.28), "c3": Color(0.55, 0.52, 0.44),
		"scale": Vector3(1.35, 1.35, 1.35), "cost": 3.0, "count": 1, "hp": 320.0, "spd": 2.8, "dmg": 20.0, "rng": 1.9, "aspd": 0.8,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 130.0,
		"desc": "Living boulder Tortoise with an almost impenetrable dome shell that absorbs heavy enemy fire."
	},

	# --- 4. VENOMOUS & CONSTRICTOR SNAKES (10 CARDS) ---
	"WildlifePoisonSnake": {
		"title": "Venomous Pit Viper", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.18, 0.68, 0.22), "c2": Color(0.58, 0.88, 0.28), "c3": Color(0.45, 1.0, 0.18),
		"scale": Vector3(0.92, 0.92, 0.92), "cost": 2.0, "count": 4, "hp": 55.0, "spd": 5.4, "dmg": 11.0, "rng": 1.9, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 9.0, "poison_ticks": 5, "proj": "NONE", "armor": 0.0,
		"desc": "4 slithering green Pit Vipers whose hollow fangs inject lethal Poison damage over time on every bite!"
	},
	"WildlifeKingCobra": {
		"title": "Hooded King Cobra", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.28, 0.24, 0.16), "c2": Color(0.78, 0.65, 0.35), "c3": Color(0.45, 0.95, 0.20),
		"scale": Vector3(1.15, 1.15, 1.15), "cost": 3.0, "count": 2, "hp": 115.0, "spd": 5.0, "dmg": 18.0, "rng": 7.0, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 11.0, "poison_ticks": 5, "proj": "VENOM", "armor": 0.0,
		"desc": "2 giant hooded King Cobras that rear up and spit blinding neurotoxic venom from range!"
	},
	"WildlifeBlackMamba": {
		"title": "Black Mamba", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.16, 0.16, 0.18), "c2": Color(0.42, 0.42, 0.45), "c3": Color(0.10, 0.08, 0.12),
		"scale": Vector3(0.95, 0.95, 0.95), "cost": 2.0, "count": 3, "hp": 65.0, "spd": 6.4, "dmg": 14.0, "rng": 1.9, "aspd": 1.65,
		"fly": false, "rock": false, "peck": false, "poison_dps": 10.0, "poison_ticks": 5, "proj": "NONE", "armor": 0.0,
		"desc": "3 fastest snakes on Earth. Slithers at extreme speed and delivers rapid-fire neurotoxic poison bites."
	},
	"WildlifeRattlesnake": {
		"title": "Diamondback Rattlesnake", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.58, 0.44, 0.26), "c2": Color(0.28, 0.20, 0.12), "c3": Color(0.85, 0.75, 0.52),
		"scale": Vector3(0.95, 0.95, 0.95), "cost": 2.0, "count": 3, "hp": 72.0, "spd": 5.0, "dmg": 15.0, "rng": 2.0, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 8.5, "poison_ticks": 5, "proj": "NONE", "armor": 0.0,
		"desc": "3 buzzing Diamondback Rattlesnakes that coil and strike with hemotoxic venom."
	},
	"WildlifeGaboonViper": {
		"title": "Gaboon Viper", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.45, 0.34, 0.28), "c2": Color(0.75, 0.66, 0.52), "c3": Color(0.50, 0.95, 0.25),
		"scale": Vector3(1.05, 1.05, 1.05), "cost": 2.0, "count": 2, "hp": 105.0, "spd": 4.4, "dmg": 20.0, "rng": 2.0, "aspd": 1.15,
		"fly": false, "rock": false, "peck": false, "poison_dps": 12.0, "poison_ticks": 5, "proj": "NONE", "armor": 0.0,
		"desc": "2 heavy-bodied Gaboon Vipers armed with 2-inch fangs and the largest venom yield of any snake."
	},
	"WildlifeInlandTaipan": {
		"title": "Inland Taipan", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.48, 0.42, 0.24), "c2": Color(0.22, 0.18, 0.12), "c3": Color(0.35, 1.0, 0.25),
		"scale": Vector3(0.92, 0.92, 0.92), "cost": 3.0, "count": 2, "hp": 90.0, "spd": 5.6, "dmg": 16.0, "rng": 1.9, "aspd": 1.45,
		"fly": false, "rock": false, "peck": false, "poison_dps": 16.0, "poison_ticks": 6, "proj": "NONE", "armor": 0.0,
		"desc": "2 Fierce Snakes possessing the deadliest drop-for-drop venom on Earth (16 Poison DPS!)."
	},
	"WildlifeSpittingCobra": {
		"title": "Mozambique Spitting Cobra", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.42, 0.28, 0.22), "c2": Color(0.88, 0.42, 0.32), "c3": Color(0.52, 1.0, 0.22),
		"scale": Vector3(0.90, 0.90, 0.90), "cost": 2.0, "count": 3, "hp": 65.0, "spd": 5.0, "dmg": 12.0, "rng": 8.5, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 8.0, "poison_ticks": 4, "proj": "VENOM", "armor": 0.0,
		"desc": "3 hooded Spitting Cobras that spray venomous jets into enemy eyes from 8.5m away!"
	},
	"WildlifeGreenAnaconda": {
		"title": "Giant Green Anaconda", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.22, 0.42, 0.16), "c2": Color(0.14, 0.16, 0.10), "c3": Color(0.65, 0.62, 0.32),
		"scale": Vector3(1.42, 1.35, 1.45), "cost": 3.0, "count": 1, "hp": 280.0, "spd": 4.2, "dmg": 34.0, "rng": 2.2, "aspd": 1.0,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 30.0,
		"desc": "Colossal Amazonian Green Anaconda that crushes enemies in its massive muscular coils."
	},
	"WildlifeReticulatedPython": {
		"title": "Reticulated Python", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.55, 0.45, 0.22), "c2": Color(0.20, 0.16, 0.12), "c3": Color(0.85, 0.72, 0.38),
		"scale": Vector3(1.22, 1.18, 1.25), "cost": 2.0, "count": 2, "hp": 150.0, "spd": 4.5, "dmg": 24.0, "rng": 2.1, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 longest snakes in the world, ambushing and constricting frontline targets."
	},
	"WildlifeSeaKrait": {
		"title": "Banded Sea Krait", "archetype": "SERPENT", "cmdr": false,
		"c1": Color(0.18, 0.58, 0.85), "c2": Color(0.10, 0.10, 0.14), "c3": Color(0.40, 0.95, 0.50),
		"scale": Vector3(0.82, 0.82, 0.82), "cost": 1.0, "count": 5, "hp": 42.0, "spd": 5.8, "dmg": 9.0, "rng": 1.8, "aspd": 1.5,
		"fly": false, "rock": false, "peck": false, "poison_dps": 7.5, "poison_ticks": 4, "proj": "NONE", "armor": 0.0,
		"desc": "5 blue-and-black striped venomous Sea Kraits. Cheap, fast slithering poison pack."
	},

	# --- 5. CORVIDS THAT THROW & DROP ROCKS (7 CARDS) ---
	"WildlifeCrow": {
		"title": "Rock-Dropping Crow Flock", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.10, 0.10, 0.14), "c2": Color(0.18, 0.18, 0.24), "c3": Color(0.28, 0.28, 0.32),
		"scale": Vector3(0.82, 0.82, 0.82), "cost": 2.0, "count": 5, "hp": 45.0, "spd": 6.2, "dmg": 14.0, "rng": 9.0, "aspd": 1.3,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "Murder of 5 clever Crows that fly above the battlefield and throw & drop rocks onto enemies below!"
	},
	"WildlifeRaven": {
		"title": "Boulder-Heaving Raven Flock", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.07, 0.07, 0.11), "c2": Color(0.15, 0.12, 0.22), "c3": Color(0.22, 0.22, 0.26),
		"scale": Vector3(0.98, 0.98, 0.98), "cost": 2.0, "count": 3, "hp": 72.0, "spd": 5.8, "dmg": 22.0, "rng": 9.5, "aspd": 1.15,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "3 large Common Ravens clutching heavy jagged stones in their talons to drop on enemy heads!"
	},
	"WildlifeMagpie": {
		"title": "Swooping Magpie Flock", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.10, 0.12, 0.16), "c2": Color(0.92, 0.94, 0.96), "c3": Color(0.18, 0.45, 0.68),
		"scale": Vector3(0.76, 0.76, 0.76), "cost": 1.0, "count": 5, "hp": 36.0, "spd": 6.6, "dmg": 11.0, "rng": 8.0, "aspd": 1.45,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "5 aggressive Magpies that pelt enemies with sharp pebbles and swoop down to peck!"
	},
	"WildlifeRook": {
		"title": "Rook Stone Bombardiers", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.12, 0.10, 0.16), "c2": Color(0.22, 0.20, 0.28), "c3": Color(0.75, 0.75, 0.78),
		"scale": Vector3(0.85, 0.85, 0.85), "cost": 2.0, "count": 4, "hp": 52.0, "spd": 6.0, "dmg": 16.0, "rng": 9.0, "aspd": 1.25,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "4 pale-beaked Rooks dropping river stones in coordinated aerial volleys."
	},
	"WildlifeJackdaw": {
		"title": "Jackdaw Pebble Throwers", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.15, 0.16, 0.20), "c2": Color(0.48, 0.50, 0.55), "c3": Color(0.85, 0.88, 0.92),
		"scale": Vector3(0.72, 0.72, 0.72), "cost": 1.0, "count": 6, "hp": 32.0, "spd": 6.5, "dmg": 9.0, "rng": 8.0, "aspd": 1.55,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "6 silver-eyed Jackdaws rapidly tossing gravel and stones from the air."
	},
	"WildlifeBlueJay": {
		"title": "Crested Blue Jay Mob", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.18, 0.48, 0.92), "c2": Color(0.92, 0.94, 0.98), "c3": Color(0.12, 0.14, 0.20),
		"scale": Vector3(0.75, 0.75, 0.75), "cost": 1.0, "count": 5, "hp": 38.0, "spd": 6.4, "dmg": 10.0, "rng": 8.5, "aspd": 1.4,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "5 noisy Blue Jays that dive-bomb and hurl stones & acorns at enemy squads."
	},
	"WildlifeCaledonianCrow": {
		"title": "Tool-Maker Caledonian Crows", "archetype": "CORVID", "cmdr": false,
		"c1": Color(0.09, 0.09, 0.12), "c2": Color(0.20, 0.18, 0.25), "c3": Color(0.65, 0.58, 0.45),
		"scale": Vector3(0.86, 0.86, 0.86), "cost": 2.0, "count": 4, "hp": 55.0, "spd": 6.2, "dmg": 18.0, "rng": 9.5, "aspd": 1.35,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "4 genius tool-making Crows that drop sharpened flint rocks to crack enemy armor!"
	},

	# --- 6. PECKING BIRDS, RAPTORS & RATITES (15 CARDS) ---
	"WildlifePeckingBird": {
		"title": "Frenzied Pecking Bird Flock", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.32, 0.26, 0.22), "c2": Color(0.65, 0.55, 0.42), "c3": Color(0.95, 0.72, 0.15),
		"scale": Vector3(0.66, 0.66, 0.66), "cost": 1.0, "count": 7, "hp": 26.0, "spd": 6.8, "dmg": 8.0, "rng": 1.7, "aspd": 2.1,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Swarm of 7 fast-flying Pecking Birds that surround enemies and peck at blinding speed!"
	},
	"WildlifeWoodpecker": {
		"title": "Pileated Woodpecker Flock", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.14, 0.14, 0.16), "c2": Color(0.92, 0.92, 0.94), "c3": Color(0.95, 0.15, 0.15),
		"scale": Vector3(0.75, 0.75, 0.75), "cost": 2.0, "count": 5, "hp": 42.0, "spd": 6.2, "dmg": 12.0, "rng": 1.8, "aspd": 2.4,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "5 red-crested Woodpeckers whose jackhammer chisel beaks rapidly drill through armor!"
	},
	"WildlifeOstrich": {
		"title": "Charging Ostrich Pair", "archetype": "AVIAN_WALKER", "cmdr": false,
		"c1": Color(0.14, 0.14, 0.16), "c2": Color(0.92, 0.88, 0.85), "c3": Color(0.88, 0.62, 0.58),
		"scale": Vector3(1.22, 1.32, 1.18), "cost": 2.0, "count": 2, "hp": 140.0, "spd": 6.8, "dmg": 22.0, "rng": 2.1, "aspd": 1.25,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 giant sprinting Ostriches that charge at 70 km/h and deliver devastating kicks and pecks."
	},
	"WildlifeCassowary": {
		"title": "Southern Cassowary", "archetype": "AVIAN_WALKER", "cmdr": false,
		"c1": Color(0.10, 0.10, 0.12), "c2": Color(0.12, 0.38, 0.92), "c3": Color(0.92, 0.18, 0.18),
		"scale": Vector3(1.12, 1.18, 1.10), "cost": 3.0, "count": 2, "hp": 155.0, "spd": 6.0, "dmg": 28.0, "rng": 2.0, "aspd": 1.35,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 20.0,
		"desc": "2 helmet-crested living dinosaur Cassowaries with 5-inch dagger claws and ferocious pecks."
	},
	"WildlifeEmu": {
		"title": "Outback Emu Mob", "archetype": "AVIAN_WALKER", "cmdr": false,
		"c1": Color(0.42, 0.34, 0.25), "c2": Color(0.28, 0.24, 0.18), "c3": Color(0.20, 0.28, 0.38),
		"scale": Vector3(1.06, 1.12, 1.05), "cost": 2.0, "count": 3, "hp": 105.0, "spd": 6.4, "dmg": 16.0, "rng": 1.9, "aspd": 1.35,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "3 fast-running Outback Emus — undefeated veterans of the Great Emu War that swarm and peck!"
	},
	"WildlifeSecretaryBird": {
		"title": "Secretary Bird", "archetype": "AVIAN_WALKER", "cmdr": false,
		"c1": Color(0.75, 0.78, 0.82), "c2": Color(0.14, 0.14, 0.18), "c3": Color(0.95, 0.48, 0.12),
		"scale": Vector3(1.02, 1.15, 1.0), "cost": 2.0, "count": 2, "hp": 110.0, "spd": 5.8, "dmg": 21.0, "rng": 2.0, "aspd": 1.4,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 long-legged Secretary Raptors that stomp and peck enemies with pinpoint accuracy."
	},
	"WildlifeShoebill": {
		"title": "Shoebill Stork", "archetype": "AVIAN_WALKER", "cmdr": false,
		"c1": Color(0.46, 0.52, 0.60), "c2": Color(0.62, 0.68, 0.74), "c3": Color(0.82, 0.72, 0.48),
		"scale": Vector3(1.08, 1.16, 1.08), "cost": 2.0, "count": 2, "hp": 125.0, "spd": 4.8, "dmg": 26.0, "rng": 2.1, "aspd": 1.1,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 intimidating Shoebill Storks whose machine-gun clattering bills deliver massive pecks."
	},
	"WildlifeBaldEagle": {
		"title": "Bald Eagle Pair", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.26, 0.18, 0.12), "c2": Color(0.96, 0.96, 0.98), "c3": Color(0.98, 0.78, 0.12),
		"scale": Vector3(1.05, 1.05, 1.05), "cost": 2.0, "count": 2, "hp": 95.0, "spd": 6.4, "dmg": 22.0, "rng": 2.1, "aspd": 1.25,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 soaring Bald Eagles that dive from the sky with razor talons and hooked yellow beaks."
	},
	"WildlifeGoldenEagle": {
		"title": "Golden Eagle Hunter", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.38, 0.24, 0.12), "c2": Color(0.78, 0.58, 0.22), "c3": Color(0.95, 0.75, 0.15),
		"scale": Vector3(1.10, 1.10, 1.10), "cost": 3.0, "count": 2, "hp": 115.0, "spd": 6.5, "dmg": 26.0, "rng": 2.2, "aspd": 1.2,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 apex Golden Eagles capable of tackling heavy wolves and infantry from the air."
	},
	"WildlifePeregrineFalcon": {
		"title": "Peregrine Falcon", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.32, 0.36, 0.44), "c2": Color(0.90, 0.88, 0.84), "c3": Color(0.95, 0.78, 0.15),
		"scale": Vector3(0.84, 0.84, 0.84), "cost": 2.0, "count": 3, "hp": 60.0, "spd": 7.8, "dmg": 19.0, "rng": 2.0, "aspd": 1.5,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "3 fastest animals on Earth! Supersonic 380 km/h stoop dive-strikes and rapid talon pecks."
	},
	"WildlifeHarpyEagle": {
		"title": "Harpy Eagle", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.22, 0.24, 0.28), "c2": Color(0.92, 0.94, 0.96), "c3": Color(0.35, 0.35, 0.40),
		"scale": Vector3(1.16, 1.16, 1.16), "cost": 3.0, "count": 2, "hp": 135.0, "spd": 5.8, "dmg": 28.0, "rng": 2.2, "aspd": 1.15,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 double-crested rainforest Harpy Eagles with grizzly-claw-sized talons and tearing beaks."
	},
	"WildlifeGreatHornedOwl": {
		"title": "Great Horned Owl", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.42, 0.32, 0.22), "c2": Color(0.68, 0.58, 0.45), "c3": Color(0.98, 0.82, 0.12),
		"scale": Vector3(0.92, 0.92, 0.92), "cost": 2.0, "count": 3, "hp": 72.0, "spd": 6.0, "dmg": 18.0, "rng": 2.0, "aspd": 1.3,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "3 silent-winged Great Horned Owls that swoop down on unsuspecting backline units."
	},
	"WildlifeAndeanCondor": {
		"title": "Andean Condor", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.12, 0.12, 0.15), "c2": Color(0.95, 0.95, 0.98), "c3": Color(0.85, 0.32, 0.38),
		"scale": Vector3(1.24, 1.15, 1.20), "cost": 2.0, "count": 2, "hp": 130.0, "spd": 5.5, "dmg": 20.0, "rng": 2.2, "aspd": 1.1,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 massive 10-foot-wingspan Andean Condors with white neck ruffs and tearing scavenger beaks."
	},
	"WildlifeCanadaGoose": {
		"title": "Angry Canada Goose Flock", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.45, 0.38, 0.30), "c2": Color(0.12, 0.12, 0.14), "c3": Color(0.95, 0.95, 0.95),
		"scale": Vector3(0.88, 0.88, 0.88), "cost": 1.0, "count": 5, "hp": 45.0, "spd": 6.0, "dmg": 11.0, "rng": 1.8, "aspd": 1.6,
		"fly": true, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "5 fearless honking Canada Geese that hiss, beat their wings, and peck anything that moves!"
	},
	"WildlifePelican": {
		"title": "Great White Pelican", "archetype": "AVIAN_FLYER", "cmdr": false,
		"c1": Color(0.94, 0.94, 0.96), "c2": Color(0.20, 0.20, 0.24), "c3": Color(0.98, 0.65, 0.18),
		"scale": Vector3(1.08, 1.05, 1.08), "cost": 2.0, "count": 2, "hp": 105.0, "spd": 5.6, "dmg": 20.0, "rng": 8.0, "aspd": 1.05,
		"fly": true, "rock": true, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ROCK", "armor": 0.0,
		"desc": "2 huge-pouched Pelicans that carry heavy rocks and fish in their throat pouches to drop on foes!"
	},

	# --- 7. INSECTS, ARACHNIDS & BUG SWARMS (20 CARDS) ---
	"WildlifeAntSwarm": {
		"title": "Fire Ant Swarm", "archetype": "INSECT", "cmdr": false,
		"c1": Color(0.78, 0.18, 0.08), "c2": Color(0.48, 0.10, 0.05), "c3": Color(0.95, 0.35, 0.12),
		"scale": Vector3(0.55, 0.55, 0.55), "cost": 1.0, "count": 9, "hp": 22.0, "spd": 5.8, "dmg": 6.0, "rng": 1.5, "aspd": 1.6,
		"fly": false, "rock": false, "peck": false, "poison_dps": 3.0, "poison_ticks": 3, "proj": "NONE", "armor": 0.0,
		"desc": "Swarm of 9 stinging red Fire Ants. Very cheap carpet of mandibles and burning alkaloid stings."
	},
	"WildlifeArmyAntSwarm": {
		"title": "Driver Army Ant Swarm", "archetype": "INSECT", "cmdr": false,
		"c1": Color(0.18, 0.12, 0.10), "c2": Color(0.32, 0.18, 0.12), "c3": Color(0.65, 0.25, 0.15),
		"scale": Vector3(0.58, 0.58, 0.58), "cost": 2.0, "count": 10, "hp": 26.0, "spd": 6.0, "dmg": 8.0, "rng": 1.5, "aspd": 1.65,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Relentless column of 10 African Driver Army Ants with scissor-like soldier jaws."
	},
	"WildlifeBulletAntSwarm": {
		"title": "Bullet Ant Pack", "archetype": "INSECT", "cmdr": false,
		"c1": Color(0.24, 0.14, 0.12), "c2": Color(0.12, 0.08, 0.08), "c3": Color(0.92, 0.28, 0.12),
		"scale": Vector3(0.72, 0.72, 0.72), "cost": 2.0, "count": 6, "hp": 42.0, "spd": 5.6, "dmg": 11.0, "rng": 1.6, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 8.0, "poison_ticks": 4, "proj": "NONE", "armor": 10.0,
		"desc": "6 giant rainforest Bullet Ants whose poneratoxin sting hits like a gunshot with heavy poison!"
	},
	"WildlifeHornetSwarm": {
		"title": "Giant Murder Hornet Swarm", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.95, 0.58, 0.05), "c2": Color(0.14, 0.10, 0.08), "c3": Color(0.92, 0.18, 0.10),
		"scale": Vector3(0.75, 0.75, 0.75), "cost": 2.0, "count": 6, "hp": 38.0, "spd": 6.6, "dmg": 11.0, "rng": 1.8, "aspd": 1.55,
		"fly": true, "rock": false, "peck": false, "poison_dps": 6.0, "poison_ticks": 4, "proj": "NONE", "armor": 0.0,
		"desc": "Swarm of 6 flying Asian Giant Hornets with 6mm venomous stingers and crushing mandibles."
	},
	"WildlifeWaspSwarm": {
		"title": "Yellowjacket Wasp Swarm", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.98, 0.85, 0.08), "c2": Color(0.10, 0.10, 0.12), "c3": Color(0.85, 0.20, 0.12),
		"scale": Vector3(0.65, 0.65, 0.65), "cost": 1.0, "count": 7, "hp": 25.0, "spd": 6.8, "dmg": 7.0, "rng": 1.7, "aspd": 1.7,
		"fly": true, "rock": false, "peck": false, "poison_dps": 4.0, "poison_ticks": 3, "proj": "NONE", "armor": 0.0,
		"desc": "7 furious flying Yellowjacket Wasps that sting repeatedly without losing their stingers."
	},
	"WildlifeKillerBeeSwarm": {
		"title": "Africanized Killer Bee Swarm", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.88, 0.68, 0.12), "c2": Color(0.18, 0.14, 0.10), "c3": Color(0.95, 0.82, 0.25),
		"scale": Vector3(0.60, 0.60, 0.60), "cost": 1.0, "count": 8, "hp": 20.0, "spd": 6.8, "dmg": 6.0, "rng": 1.6, "aspd": 1.8,
		"fly": true, "rock": false, "peck": false, "poison_dps": 4.5, "poison_ticks": 3, "proj": "NONE", "armor": 0.0,
		"desc": "Cloud of 8 aggressive Killer Bees that chase down and blanket enemy squads in stings."
	},
	"WildlifeLocustSwarm": {
		"title": "Plague Locust Cloud", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.58, 0.68, 0.22), "c2": Color(0.78, 0.65, 0.25), "c3": Color(0.38, 0.48, 0.16),
		"scale": Vector3(0.62, 0.62, 0.62), "cost": 1.0, "count": 9, "hp": 22.0, "spd": 6.5, "dmg": 6.5, "rng": 1.6, "aspd": 1.75,
		"fly": true, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Sky-darkening swarm of 9 flying Desert Locusts that strip enemy lines bare."
	},
	"WildlifeMosquitoSwarm": {
		"title": "Vampiric Mosquito Swarm", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.28, 0.24, 0.26), "c2": Color(0.65, 0.12, 0.15), "c3": Color(0.92, 0.18, 0.22),
		"scale": Vector3(0.62, 0.62, 0.62), "cost": 1.0, "count": 7, "hp": 24.0, "spd": 6.6, "dmg": 7.0, "rng": 1.7, "aspd": 1.65,
		"fly": true, "rock": false, "peck": false, "poison_dps": 3.0, "poison_ticks": 3, "proj": "NONE", "armor": 0.0,
		"desc": "7 giant blood-sucking Mosquitoes that drain health from organic targets to heal themselves!"
	},
	"WildlifeDragonflySwarm": {
		"title": "Meganeura Dragonfly Swarm", "archetype": "FLYING_INSECT", "cmdr": false,
		"c1": Color(0.12, 0.68, 0.88), "c2": Color(0.18, 0.88, 0.55), "c3": Color(0.85, 0.95, 1.0),
		"scale": Vector3(0.82, 0.82, 0.88), "cost": 2.0, "count": 5, "hp": 45.0, "spd": 7.4, "dmg": 13.0, "rng": 1.8, "aspd": 1.6,
		"fly": true, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "5 prehistoric-sized Dragonflies with 95% hunting interception accuracy and four buzzing wings."
	},
	"WildlifePrayingMantis": {
		"title": "Giant Praying Mantis Pack", "archetype": "INSECT", "cmdr": false,
		"c1": Color(0.24, 0.75, 0.22), "c2": Color(0.48, 0.88, 0.35), "c3": Color(0.85, 0.95, 0.28),
		"scale": Vector3(0.96, 1.02, 0.96), "cost": 2.0, "count": 3, "hp": 80.0, "spd": 5.2, "dmg": 22.0, "rng": 2.0, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 15.0,
		"desc": "3 camouflaged Praying Mantises with spiked raptorial scythe forelegs that slice targets."
	},
	"WildlifeHerculesBeetle": {
		"title": "Hercules Horned Beetle", "archetype": "BEETLE", "cmdr": false,
		"c1": Color(0.65, 0.58, 0.22), "c2": Color(0.14, 0.12, 0.10), "c3": Color(0.10, 0.08, 0.08),
		"scale": Vector3(1.12, 1.08, 1.15), "cost": 3.0, "count": 2, "hp": 165.0, "spd": 4.2, "dmg": 26.0, "rng": 2.1, "aspd": 1.0,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 65.0,
		"desc": "2 chitin-plated Hercules Beetles with giant thoracic pincer horns capable of lifting 850x their weight."
	},
	"WildlifeStagBeetle": {
		"title": "Mandible Stag Beetle Pack", "archetype": "BEETLE", "cmdr": false,
		"c1": Color(0.22, 0.10, 0.08), "c2": Color(0.12, 0.08, 0.08), "c3": Color(0.48, 0.16, 0.10),
		"scale": Vector3(0.95, 0.95, 1.02), "cost": 2.0, "count": 3, "hp": 95.0, "spd": 4.6, "dmg": 18.0, "rng": 1.9, "aspd": 1.15,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 40.0,
		"desc": "3 glossy Stag Beetles armed with antler-like crushing mandibles and hard wing-cases."
	},
	"WildlifeBombardierBeetle": {
		"title": "Bombardier Beetle Pack", "archetype": "BEETLE", "cmdr": false,
		"c1": Color(0.16, 0.22, 0.35), "c2": Color(0.85, 0.38, 0.12), "c3": Color(0.98, 0.65, 0.10),
		"scale": Vector3(0.88, 0.88, 0.88), "cost": 2.0, "count": 3, "hp": 75.0, "spd": 4.8, "dmg": 16.0, "rng": 8.0, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 5.0, "poison_ticks": 3, "proj": "ACID", "armor": 25.0,
		"desc": "3 Bombardier Beetles that fire boiling 100°C explosive hydroquinone acid spray from range!"
	},
	"WildlifeGoliathBeetle": {
		"title": "Heavy Goliath Beetle", "archetype": "BEETLE", "cmdr": false,
		"c1": Color(0.38, 0.16, 0.12), "c2": Color(0.92, 0.90, 0.85), "c3": Color(0.14, 0.14, 0.16),
		"scale": Vector3(1.18, 1.15, 1.18), "cost": 3.0, "count": 2, "hp": 185.0, "spd": 4.0, "dmg": 22.0, "rng": 2.0, "aspd": 0.95,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 80.0,
		"desc": "2 tanky Goliath Scarab Beetles with thick striped exoskeletons that shrug off gunfire."
	},
	"WildlifeEmperorScorpion": {
		"title": "Emperor Scorpion Pack", "archetype": "SCORPION", "cmdr": false,
		"c1": Color(0.10, 0.10, 0.14), "c2": Color(0.18, 0.22, 0.28), "c3": Color(0.85, 0.22, 0.15),
		"scale": Vector3(1.02, 1.0, 1.05), "cost": 2.0, "count": 3, "hp": 105.0, "spd": 4.6, "dmg": 17.0, "rng": 1.9, "aspd": 1.2,
		"fly": false, "rock": false, "peck": false, "poison_dps": 6.5, "poison_ticks": 4, "proj": "NONE", "armor": 35.0,
		"desc": "3 glossy black Emperor Scorpions with crushing pincer claws and venomous overhead tail stingers."
	},
	"WildlifeDeathstalkerScorpion": {
		"title": "Deathstalker Scorpion Swarm", "archetype": "SCORPION", "cmdr": false,
		"c1": Color(0.88, 0.75, 0.28), "c2": Color(0.68, 0.55, 0.18), "c3": Color(0.45, 0.98, 0.20),
		"scale": Vector3(0.78, 0.78, 0.80), "cost": 2.0, "count": 5, "hp": 50.0, "spd": 5.5, "dmg": 11.0, "rng": 1.8, "aspd": 1.45,
		"fly": false, "rock": false, "peck": false, "poison_dps": 11.0, "poison_ticks": 5, "proj": "NONE", "armor": 15.0,
		"desc": "5 translucent yellow Deathstalker Scorpions carrying deadly chlorotoxin venom in their tails."
	},
	"WildlifeTarantula": {
		"title": "Goliath Birdeater Tarantula", "archetype": "ARACHNID", "cmdr": false,
		"c1": Color(0.38, 0.24, 0.14), "c2": Color(0.55, 0.35, 0.20), "c3": Color(0.85, 0.18, 0.15),
		"scale": Vector3(1.08, 1.05, 1.08), "cost": 2.0, "count": 2, "hp": 135.0, "spd": 4.8, "dmg": 22.0, "rng": 2.0, "aspd": 1.2,
		"fly": false, "rock": false, "peck": false, "poison_dps": 6.0, "poison_ticks": 4, "proj": "NONE", "armor": 20.0,
		"desc": "2 massive hairy Goliath Birdeater Spiders with 1-inch fangs and urticating bristles."
	},
	"WildlifeBlackWidowSwarm": {
		"title": "Black Widow Spider Swarm", "archetype": "ARACHNID", "cmdr": false,
		"c1": Color(0.08, 0.08, 0.10), "c2": Color(0.95, 0.12, 0.12), "c3": Color(0.92, 0.94, 0.98),
		"scale": Vector3(0.72, 0.72, 0.72), "cost": 2.0, "count": 5, "hp": 45.0, "spd": 5.4, "dmg": 10.0, "rng": 7.0, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 9.5, "poison_ticks": 5, "proj": "WEB", "armor": 0.0,
		"desc": "5 red-hourglass Black Widows that shoot sticky silk webs and inject latrotoxin venom!"
	},
	"WildlifeFunnelWebSpider": {
		"title": "Sydney Funnel-Web Pack", "archetype": "ARACHNID", "cmdr": false,
		"c1": Color(0.14, 0.12, 0.16), "c2": Color(0.28, 0.20, 0.22), "c3": Color(0.88, 0.15, 0.20),
		"scale": Vector3(0.80, 0.80, 0.80), "cost": 2.0, "count": 4, "hp": 62.0, "spd": 5.5, "dmg": 14.0, "rng": 1.8, "aspd": 1.5,
		"fly": false, "rock": false, "peck": false, "poison_dps": 10.0, "poison_ticks": 5, "proj": "NONE", "armor": 0.0,
		"desc": "4 hyper-aggressive Funnel-Web Spiders whose downward-striking fangs pierce boot leather."
	},
	"WildlifeGiantCentipede": {
		"title": "Amazonian Giant Centipede", "archetype": "CENTIPEDE", "cmdr": false,
		"c1": Color(0.68, 0.14, 0.08), "c2": Color(0.95, 0.78, 0.12), "c3": Color(0.14, 0.12, 0.10),
		"scale": Vector3(1.0, 0.95, 1.05), "cost": 2.0, "count": 3, "hp": 85.0, "spd": 5.8, "dmg": 16.0, "rng": 1.9, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 8.0, "poison_ticks": 4, "proj": "NONE", "armor": 20.0,
		"desc": "3 foot-long multi-legged Scolopendra Centipedes that coil around prey with venomous forcipules."
	},

	# --- 8. FISH, SHARKS, CRUSTACEANS & AQUATIC FAUNA (14 CARDS) ---
	"WildlifePiranhaSwarm": {
		"title": "Red-Bellied Piranha Swarm", "archetype": "FISH", "cmdr": false,
		"c1": Color(0.32, 0.42, 0.38), "c2": Color(0.92, 0.18, 0.12), "c3": Color(0.95, 0.95, 0.95),
		"scale": Vector3(0.68, 0.68, 0.68), "cost": 1.0, "count": 7, "hp": 28.0, "spd": 6.4, "dmg": 9.0, "rng": 1.6, "aspd": 1.9,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "7 razor-toothed Red-Bellied Piranhas that flop, leap, and frenzy-bite everything in sight!"
	},
	"WildlifeGreatWhiteShark": {
		"title": "Great White Land-Shark", "archetype": "SHARK", "cmdr": false,
		"c1": Color(0.32, 0.40, 0.50), "c2": Color(0.92, 0.94, 0.96), "c3": Color(0.96, 0.96, 0.96),
		"scale": Vector3(1.32, 1.25, 1.38), "cost": 3.0, "count": 1, "hp": 270.0, "spd": 4.8, "dmg": 36.0, "rng": 2.2, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Apex Great White Shark propelling across the battlefield with 300 serrated triangular teeth!"
	},
	"WildlifeHammerheadShark": {
		"title": "Hammerhead Shark", "archetype": "SHARK", "cmdr": false,
		"c1": Color(0.38, 0.44, 0.50), "c2": Color(0.88, 0.90, 0.92), "c3": Color(0.95, 0.95, 0.95),
		"scale": Vector3(1.12, 1.08, 1.15), "cost": 3.0, "count": 2, "hp": 155.0, "spd": 5.0, "dmg": 24.0, "rng": 2.1, "aspd": 1.15,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 wide-headed Hammerhead Sharks with 360-degree electro-reception and sweeping bite attacks."
	},
	"WildlifeElectricEel": {
		"title": "High-Voltage Electric Eel", "archetype": "EEL", "cmdr": false,
		"c1": Color(0.22, 0.26, 0.32), "c2": Color(0.88, 0.52, 0.18), "c3": Color(0.25, 0.88, 1.0),
		"scale": Vector3(1.0, 0.95, 1.05), "cost": 2.0, "count": 2, "hp": 100.0, "spd": 4.8, "dmg": 21.0, "rng": 8.0, "aspd": 1.2,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "LIGHTNING", "armor": 0.0,
		"desc": "2 Amazonian Electric Eels that discharge 860-volt bio-electric lightning bolts at ranged targets!"
	},
	"WildlifeMudskipperPack": {
		"title": "Amphibious Mudskipper Pack", "archetype": "FISH", "cmdr": false,
		"c1": Color(0.45, 0.42, 0.30), "c2": Color(0.62, 0.58, 0.44), "c3": Color(0.25, 0.68, 0.88),
		"scale": Vector3(0.72, 0.72, 0.72), "cost": 1.0, "count": 6, "hp": 34.0, "spd": 5.8, "dmg": 8.0, "rng": 6.5, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "ACID", "armor": 0.0,
		"desc": "6 land-walking Mudskipper fish that hop on pectoral fins and spit pressurized water/mud jets!"
	},
	"WildlifeWalkingCatfish": {
		"title": "Armored Walking Catfish", "archetype": "FISH", "cmdr": false,
		"c1": Color(0.32, 0.28, 0.24), "c2": Color(0.68, 0.62, 0.52), "c3": Color(0.85, 0.75, 0.45),
		"scale": Vector3(0.88, 0.85, 0.92), "cost": 2.0, "count": 4, "hp": 68.0, "spd": 4.8, "dmg": 13.0, "rng": 1.8, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 4.0, "poison_ticks": 3, "proj": "NONE", "armor": 20.0,
		"desc": "4 air-breathing Walking Catfish with long barbels and venomous serrated pectoral spines."
	},
	"WildlifePufferfish": {
		"title": "Spiky Pufferfish", "archetype": "FISH", "cmdr": false,
		"c1": Color(0.85, 0.72, 0.32), "c2": Color(0.95, 0.92, 0.78), "c3": Color(0.45, 0.98, 0.25),
		"scale": Vector3(0.92, 0.92, 0.92), "cost": 2.0, "count": 3, "hp": 90.0, "spd": 4.2, "dmg": 14.0, "rng": 1.8, "aspd": 1.2,
		"fly": false, "rock": false, "peck": false, "poison_dps": 11.0, "poison_ticks": 5, "proj": "NONE", "armor": 25.0,
		"desc": "3 inflated Spiky Pufferfish coated in lethal tetrodotoxin poison spines!"
	},
	"WildlifeAnglerfish": {
		"title": "Deep-Sea Anglerfish", "archetype": "FISH", "cmdr": false,
		"c1": Color(0.14, 0.10, 0.18), "c2": Color(0.24, 0.16, 0.28), "c3": Color(0.25, 0.98, 0.88),
		"scale": Vector3(1.05, 1.05, 1.05), "cost": 2.0, "count": 2, "hp": 120.0, "spd": 4.4, "dmg": 26.0, "rng": 2.0, "aspd": 1.1,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 abyssal Anglerfish with glowing bioluminescent head-lures and long inward-curving glass fangs."
	},
	"WildlifeMantisShrimp": {
		"title": "Peacock Mantis Shrimp", "archetype": "CRAB", "cmdr": false,
		"c1": Color(0.12, 0.75, 0.42), "c2": Color(0.18, 0.45, 0.95), "c3": Color(0.98, 0.22, 0.18),
		"scale": Vector3(0.95, 0.95, 0.98), "cost": 3.0, "count": 2, "hp": 130.0, "spd": 5.4, "dmg": 34.0, "rng": 2.0, "aspd": 1.3,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 45.0,
		"desc": "2 rainbow Mantis Shrimp whose 23 m/s cavitation club punch shatters heavy armor and shields!"
	},
	"WildlifeCoconutCrab": {
		"title": "Giant Coconut Crab", "archetype": "CRAB", "cmdr": false,
		"c1": Color(0.58, 0.24, 0.16), "c2": Color(0.22, 0.35, 0.58), "c3": Color(0.85, 0.55, 0.32),
		"scale": Vector3(1.08, 1.05, 1.08), "cost": 2.0, "count": 2, "hp": 145.0, "spd": 4.0, "dmg": 25.0, "rng": 2.0, "aspd": 1.0,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 65.0,
		"desc": "2 largest land arthropods on Earth with 3,300-Newton crushing pincers and thick shells."
	},
	"WildlifeKingCrab": {
		"title": "Alaskan King Crab", "archetype": "CRAB", "cmdr": false,
		"c1": Color(0.85, 0.22, 0.14), "c2": Color(0.95, 0.65, 0.42), "c3": Color(0.98, 0.88, 0.75),
		"scale": Vector3(1.12, 1.05, 1.12), "cost": 2.0, "count": 2, "hp": 135.0, "spd": 4.2, "dmg": 21.0, "rng": 2.1, "aspd": 1.1,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 55.0,
		"desc": "2 long-legged spiky red King Crabs that scuttle sideways and pinch targets."
	},
	"WildlifePistolShrimp": {
		"title": "Snapping Pistol Shrimp", "archetype": "CRAB", "cmdr": false,
		"c1": Color(0.88, 0.38, 0.22), "c2": Color(0.95, 0.78, 0.55), "c3": Color(0.35, 0.92, 1.0),
		"scale": Vector3(0.86, 0.86, 0.86), "cost": 2.0, "count": 3, "hp": 72.0, "spd": 4.6, "dmg": 20.0, "rng": 8.5, "aspd": 1.15,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "SONIC", "armor": 25.0,
		"desc": "3 Pistol Shrimp whose oversized snapping claw fires superheated 4,700°C sonic cavitation bubbles!"
	},
	"WildlifeBullWalrus": {
		"title": "Arctic Tusker Walrus", "archetype": "WALRUS", "cmdr": false,
		"c1": Color(0.48, 0.34, 0.28), "c2": Color(0.58, 0.42, 0.35), "c3": Color(0.95, 0.92, 0.82),
		"scale": Vector3(1.38, 1.28, 1.42), "cost": 3.0, "count": 1, "hp": 310.0, "spd": 3.5, "dmg": 30.0, "rng": 2.2, "aspd": 0.9,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 50.0,
		"desc": "2-ton blubbery Bull Walrus armed with meter-long ivory tusks that impale frontlines."
	},
	"WildlifeOrcaPod": {
		"title": "Killer Whale Orca", "archetype": "SHARK", "cmdr": false,
		"c1": Color(0.08, 0.09, 0.12), "c2": Color(0.96, 0.96, 0.98), "c3": Color(0.90, 0.92, 0.95),
		"scale": Vector3(1.48, 1.38, 1.55), "cost": 4.0, "count": 1, "hp": 360.0, "spd": 4.8, "dmg": 38.0, "rng": 2.3, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Apex Killer Whale Orca that breaches and crushes anything in its lane."
	},

	# --- 9. LAND MAMMALS: PREDATORS, PACHYDERMS & CRITTERS (16 CARDS) ---
	"WildlifeAfricanLion": {
		"title": "African Lion Pride", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.82, 0.62, 0.28), "c2": Color(0.42, 0.24, 0.10), "c3": Color(0.95, 0.88, 0.72),
		"scale": Vector3(1.08, 1.08, 1.12), "cost": 3.0, "count": 3, "hp": 125.0, "spd": 5.6, "dmg": 22.0, "rng": 2.0, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Pride of 3 maned African Lions that pounce on enemy squads with roaring fury."
	},
	"WildlifeBengalTiger": {
		"title": "Royal Bengal Tiger", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.92, 0.48, 0.12), "c2": Color(0.10, 0.10, 0.12), "c3": Color(0.96, 0.96, 0.96),
		"scale": Vector3(1.15, 1.12, 1.18), "cost": 3.0, "count": 2, "hp": 165.0, "spd": 5.8, "dmg": 30.0, "rng": 2.0, "aspd": 1.25,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 striped orange-and-black Bengal Tigers with high single-target pouncing burst damage."
	},
	"WildlifeCheetah": {
		"title": "Sprinting Cheetah Pair", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.92, 0.75, 0.32), "c2": Color(0.12, 0.10, 0.08), "c3": Color(0.96, 0.94, 0.88),
		"scale": Vector3(0.94, 0.96, 1.02), "cost": 2.0, "count": 2, "hp": 85.0, "spd": 7.6, "dmg": 18.0, "rng": 1.9, "aspd": 1.5,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 fastest land mammals on Earth! Sprints across the map at 110 km/h to blitz backlines."
	},
	"WildlifeBlackPanther": {
		"title": "Stealth Black Jaguar", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.10, 0.10, 0.14), "c2": Color(0.18, 0.18, 0.24), "c3": Color(0.45, 0.92, 0.25),
		"scale": Vector3(1.04, 1.04, 1.08), "cost": 2.0, "count": 2, "hp": 115.0, "spd": 6.0, "dmg": 25.0, "rng": 2.0, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "2 shadow-coated Black Jaguars with skull-piercing jaws and off-path flanking agility."
	},
	"WildlifeGrayWolfPack": {
		"title": "Timber Wolf Pack", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.45, 0.48, 0.52), "c2": Color(0.78, 0.80, 0.84), "c3": Color(0.92, 0.78, 0.18),
		"scale": Vector3(0.88, 0.88, 0.92), "cost": 2.0, "count": 4, "hp": 68.0, "spd": 6.0, "dmg": 14.0, "rng": 1.8, "aspd": 1.4,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Pack of 4 howling Gray Wolves that hunt in formation and tear down isolated targets."
	},
	"WildlifeSpottedHyena": {
		"title": "Laughing Hyena Clan", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.68, 0.55, 0.35), "c2": Color(0.24, 0.18, 0.12), "c3": Color(0.18, 0.14, 0.12),
		"scale": Vector3(0.90, 0.90, 0.92), "cost": 2.0, "count": 4, "hp": 72.0, "spd": 5.6, "dmg": 15.0, "rng": 1.8, "aspd": 1.35,
		"fly": false, "rock": false, "peck": true, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "4 cackling Spotted Hyenas with 1,100 PSI bone-crushing jaws that shred armor."
	},
	"WildlifeGrizzlyBear": {
		"title": "Kodiak Grizzly Bear", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.38, 0.24, 0.14), "c2": Color(0.52, 0.34, 0.20), "c3": Color(0.85, 0.82, 0.75),
		"scale": Vector3(1.32, 1.30, 1.32), "cost": 3.0, "count": 1, "hp": 285.0, "spd": 4.5, "dmg": 34.0, "rng": 2.2, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Massive Kodiak Grizzly Bear that mauls enemies with 4-inch claws and crushing paw swipes."
	},
	"WildlifePolarBear": {
		"title": "Arctic Polar Bear", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.94, 0.96, 0.98), "c2": Color(0.84, 0.88, 0.92), "c3": Color(0.14, 0.14, 0.16),
		"scale": Vector3(1.36, 1.34, 1.38), "cost": 3.0, "count": 1, "hp": 300.0, "spd": 4.6, "dmg": 36.0, "rng": 2.2, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "Largest land carnivore on Earth! White Arctic Polar Bear with devastating maul strikes."
	},
	"WildlifeHoneyBadger": {
		"title": "Fearless Honey Badger", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.94), "c3": Color(0.85, 0.85, 0.85),
		"scale": Vector3(0.78, 0.76, 0.82), "cost": 2.0, "count": 3, "hp": 110.0, "spd": 5.2, "dmg": 18.0, "rng": 1.8, "aspd": 1.45,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 35.0,
		"desc": "3 Honey Badgers! Loose rubbery skin shrugs off bites and arrows — Honey Badger doesn't care!"
	},
	"WildlifeWolverine": {
		"title": "Feral Wolverine", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.28, 0.18, 0.12), "c2": Color(0.68, 0.52, 0.28), "c3": Color(0.88, 0.85, 0.78),
		"scale": Vector3(0.84, 0.82, 0.86), "cost": 2.0, "count": 3, "hp": 95.0, "spd": 5.5, "dmg": 20.0, "rng": 1.8, "aspd": 1.5,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 20.0,
		"desc": "3 ferocious mountain Wolverines that punch far above their weight class."
	},
	"WildlifeAfricanElephant": {
		"title": "African Bush Elephant", "archetype": "TANK_MAMMAL", "cmdr": false,
		"c1": Color(0.45, 0.46, 0.48), "c2": Color(0.36, 0.37, 0.39), "c3": Color(0.96, 0.94, 0.86),
		"scale": Vector3(1.62, 1.58, 1.65), "cost": 4.0, "count": 1, "hp": 460.0, "spd": 3.8, "dmg": 38.0, "rng": 2.5, "aspd": 0.9,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 80.0,
		"desc": "6-ton African Bush Elephant with giant flapping ears, sweeping trunk, and long ivory tusks."
	},
	"WildlifeWhiteRhino": {
		"title": "Armored White Rhinoceros", "archetype": "TANK_MAMMAL", "cmdr": false,
		"c1": Color(0.52, 0.52, 0.54), "c2": Color(0.40, 0.40, 0.42), "c3": Color(0.88, 0.85, 0.75),
		"scale": Vector3(1.42, 1.35, 1.48), "cost": 3.0, "count": 1, "hp": 340.0, "spd": 4.6, "dmg": 34.0, "rng": 2.3, "aspd": 0.95,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 90.0,
		"desc": "Thick-skinned White Rhinoceros that charges down lanes with its twin keratin horns."
	},
	"WildlifeHippo": {
		"title": "River Hippopotamus", "archetype": "TANK_MAMMAL", "cmdr": false,
		"c1": Color(0.42, 0.34, 0.40), "c2": Color(0.68, 0.48, 0.52), "c3": Color(0.94, 0.92, 0.82),
		"scale": Vector3(1.40, 1.30, 1.45), "cost": 3.0, "count": 1, "hp": 350.0, "spd": 4.2, "dmg": 36.0, "rng": 2.2, "aspd": 0.95,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 50.0,
		"desc": "Deadliest large land mammal in Africa! Yawning 180-degree jaws with 20-inch canine tusks."
	},
	"WildlifeCapeBuffalo": {
		"title": "Cape Buffalo Herd", "archetype": "TANK_MAMMAL", "cmdr": false,
		"c1": Color(0.18, 0.16, 0.15), "c2": Color(0.28, 0.25, 0.22), "c3": Color(0.75, 0.72, 0.65),
		"scale": Vector3(1.18, 1.15, 1.22), "cost": 3.0, "count": 2, "hp": 195.0, "spd": 4.8, "dmg": 25.0, "rng": 2.1, "aspd": 1.05,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 40.0,
		"desc": "2 'Black Death' Cape Buffalos with fused boss horns that stampede side-by-side."
	},
	"WildlifeRedKangaroo": {
		"title": "Boxing Red Kangaroo", "archetype": "BIPED_HOPPER", "cmdr": false,
		"c1": Color(0.76, 0.38, 0.20), "c2": Color(0.88, 0.72, 0.55), "c3": Color(0.25, 0.20, 0.18),
		"scale": Vector3(1.02, 1.08, 1.02), "cost": 2.0, "count": 3, "hp": 90.0, "spd": 6.2, "dmg": 18.0, "rng": 1.9, "aspd": 1.35,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "NONE", "armor": 0.0,
		"desc": "3 muscular Red Kangaroos that bound forward, balance on their tails, and double-kick enemies!"
	},
	"WildlifePorcupine": {
		"title": "Crested Porcupine", "archetype": "QUADRUPED", "cmdr": false,
		"c1": Color(0.22, 0.18, 0.15), "c2": Color(0.95, 0.95, 0.92), "c3": Color(0.12, 0.10, 0.10),
		"scale": Vector3(0.85, 0.85, 0.85), "cost": 2.0, "count": 3, "hp": 78.0, "spd": 4.4, "dmg": 15.0, "rng": 7.5, "aspd": 1.3,
		"fly": false, "rock": false, "peck": false, "poison_dps": 0.0, "poison_ticks": 0, "proj": "QUILL", "armor": 30.0,
		"desc": "3 quill-covered Crested Porcupines that launch volleys of razor-sharp barbed quills!"
	}
}


static func get_species_key(raw_name: String) -> String:
	var clean = raw_name.replace("Card", "").split("@")[0]
	for i in range(clean.length() - 1, -1, -1):
		var ch = clean.substr(i, 1)
		if ch >= "0" and ch <= "9":
			clean = clean.substr(0, i)
		else:
			break
	if SPECIES_CATALOG.has(clean):
		return clean
	for k in SPECIES_CATALOG.keys():
		if k in raw_name:
			return k
	return "WildlifeMonkey"

static func get_species_info(raw_name: String) -> Dictionary:
	var key = get_species_key(raw_name)
	return SPECIES_CATALOG[key]

static func _make_mat(col: Color, rough: float = 0.72, metal: float = 0.05, emit_energy: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit_energy > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit_energy
	return m

static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, nm: String = "Part") -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = nm
	var bm = BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, rad: float, h: float, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE, nm: String = "SpherePart") -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = nm
	var sm = SphereMesh.new()
	sm.radius = rad
	sm.height = h
	mi.mesh = sm
	mi.position = pos
	mi.scale = scl
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, nm: String = "CylPart") -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = nm
	var cm = CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_eyes(head: Node3D, x_sep: float, y_pos: float, z_pos: float, rad: float, eye_mat: Material, pupil_mat: Material) -> void:
	for s in [-1.0, 1.0]:
		_add_sphere(head, rad, rad * 2.0, Vector3(s * x_sep, y_pos, z_pos), eye_mat)
		_add_sphere(head, rad * 0.55, rad * 1.1, Vector3(s * x_sep, y_pos, z_pos - rad * 0.55), pupil_mat)

static func build_animal_model(unit: Node3D, raw_name: String) -> Node3D:
	var key = get_species_key(raw_name)
	var info: Dictionary = SPECIES_CATALOG[key]
	var pivot = unit.get_node_or_null("VisualPivot")
	if not pivot:
		pivot = Node3D.new()
		pivot.name = "VisualPivot"
		unit.add_child(pivot)
	for child in pivot.get_children():
		if child.name in ["MeshInstance3D", "TurretPivot", "HumanoidRig", "AnimalModelRoot"]:
			child.queue_free()

	var root = Node3D.new()
	root.name = "AnimalModelRoot"
	root.scale = info.get("scale", Vector3.ONE)
	pivot.add_child(root)

	var c1: Color = info.get("c1", Color(0.5, 0.35, 0.2))
	var c2: Color = info.get("c2", Color(0.75, 0.6, 0.45))
	var c3: Color = info.get("c3", Color(0.9, 0.85, 0.7))
	var arch: String = info.get("archetype", "QUADRUPED")
	var m1 = _make_mat(c1, 0.75, 0.05)
	var m2 = _make_mat(c2, 0.70, 0.05)
	var m3 = _make_mat(c3, 0.55, 0.10)
	var m_dark = _make_mat(Color(0.08, 0.08, 0.09), 0.35, 0.1)
	var m_white = _make_mat(Color(0.95, 0.94, 0.88), 0.35, 0.05)
	var m_eye = _make_mat(Color(0.95, 0.82, 0.18), 0.25, 0.1, 0.4)

	match arch:
		"PRIMATE":
			_build_primate(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"CROCODILIAN":
			_build_crocodilian(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"LIZARD":
			_build_lizard(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"SERPENT":
			_build_serpent(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"CORVID", "AVIAN_FLYER":
			_build_avian_flyer(root, key, info, m1, m2, m3, m_dark, m_white, m_eye)
		"AVIAN_WALKER":
			_build_avian_walker(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"INSECT", "FLYING_INSECT", "BEETLE":
			_build_insect(root, key, arch, m1, m2, m3, m_dark, m_eye)
		"ARACHNID", "SCORPION", "CENTIPEDE":
			_build_arachnid_or_crawler(root, key, arch, m1, m2, m3, m_dark, m_eye)
		"SHARK", "FISH", "EEL", "WALRUS":
			_build_aquatic(root, key, arch, m1, m2, m3, m_dark, m_white, m_eye)
		"CRAB":
			_build_crab(root, key, m1, m2, m3, m_dark, m_eye)
		"TANK_MAMMAL":
			_build_tank_mammal(root, key, m1, m2, m3, m_dark, m_white, m_eye)
		"BIPED_HOPPER":
			_build_biped_hopper(root, key, m1, m2, m3, m_dark, m_eye)
		"TURTLE":
			_build_turtle(root, key, m1, m2, m3, m_dark, m_eye)
		_:
			_build_quadruped(root, key, info, m1, m2, m3, m_dark, m_white, m_eye)

	if info.get("cmdr", false):
		var crown_parent: Node3D = root.get_node_or_null("HeadPivot")
		var crown_pos = Vector3(0, 0.22, -0.02) if crown_parent != null else Vector3(0, 0.95, -0.25)
		if crown_parent == null:
			crown_parent = root
		var crown = _add_cyl(crown_parent, 0.20, 0.15, 0.11, crown_pos, _make_mat(Color(1.0, 0.78, 0.15), 0.2, 0.85, 0.9), Vector3.ZERO, "CommanderCrown")
		for i in range(4):
			var ang = float(i) * PI * 0.5
			_add_cyl(crown, 0.008, 0.038, 0.11, Vector3(cos(ang) * 0.14, 0.09, sin(ang) * 0.14), _make_mat(Color(0.2, 1.0, 0.45), 0.2, 0.6, 1.2))
	return root

static func _build_primate(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var is_ape = ("Gorilla" in key or "Chimpanzee" in key or "Orangutan" in key or "Baboon" in key or "Mandrill" in key)
	var is_gibbon = ("Gibbon" in key)
	var torso_y = 0.72 if is_ape else (0.64 if is_gibbon else 0.58)
	var torso = _add_sphere(root, 0.36 if is_ape else 0.24, 0.78 if is_ape else 0.54, Vector3(0, torso_y, 0.02), m1, Vector3(1.15, 1.0, 1.15), "Torso")
	_add_sphere(torso, 0.26 if is_ape else 0.17, 0.55 if is_ape else 0.38, Vector3(0, -0.02, -0.14), m2, Vector3(0.95, 0.9, 0.75), "Chest")
	if "Gorilla" in key:
		_add_sphere(torso, 0.34, 0.68, Vector3(0, 0.08, 0.10), m2, Vector3(1.12, 0.95, 1.05), "SilverBackSaddle")
	elif "Baboon" in key:
		_add_sphere(torso, 0.30, 0.56, Vector3(0, 0.14, -0.12), m2, Vector3(1.22, 1.05, 1.05), "BaboonMane")
	elif "Mandrill" in key:
		_add_sphere(torso, 0.18, 0.32, Vector3(0, -0.04, 0.26), m3, Vector3(1.1, 0.9, 0.6), "MandrillRump")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, torso_y + (0.42 if is_ape else 0.30), -0.26 if is_ape else -0.18)
	root.add_child(head)
	_add_sphere(head, 0.24 if is_ape else 0.17, 0.48 if is_ape else 0.34, Vector3.ZERO, m1)
	if "Gorilla" in key:
		_add_box(head, Vector3(0.30, 0.08, 0.14), Vector3(0, 0.11, -0.18), m1, Vector3.ZERO, "BrowRidge")
	elif "Orangutan" in key:
		for s in [-1.0, 1.0]:
			_add_sphere(head, 0.16, 0.34, Vector3(s * 0.22, -0.01, -0.06), m2, Vector3(0.45, 1.05, 0.85), "CheekFlange")
	elif is_gibbon:
		_add_sphere(head, 0.15, 0.30, Vector3(0, 0.0, -0.06), m2, Vector3(1.05, 1.05, 0.85), "FaceRing")
	var muzzle_len = 0.26 if ("Baboon" in key or "Mandrill" in key) else 0.14
	_add_box(head, Vector3(0.22, 0.16, muzzle_len), Vector3(0, -0.04, -0.16 - muzzle_len * 0.3), m2 if not is_gibbon else m3, Vector3.ZERO, "Muzzle")
	if "Mandrill" in key:
		_add_box(head, Vector3(0.05, 0.09, 0.24), Vector3(0, 0.02, -0.23), m3, Vector3.ZERO, "NasalBridge")
		for s in [-1.0, 1.0]:
			_add_box(head, Vector3(0.05, 0.08, 0.22), Vector3(s * 0.09, -0.01, -0.22), m2)
	elif "Proboscis" in key:
		_add_sphere(head, 0.075, 0.22, Vector3(0, -0.04, -0.28), m2, Vector3(0.85, 1.15, 1.15), "ProboscisNose")
	for s in [-1.0, 1.0]:
		_add_sphere(head, 0.07, 0.14, Vector3(s * (0.23 if is_ape else 0.17), 0.02, -0.02), m2, Vector3(0.45, 1.0, 0.85), "Ear")
	_add_eyes(head, 0.08, 0.05, -0.19, 0.038, m_eye, m_dark)

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.10, -0.10)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.18, 0.06, muzzle_len), Vector3(0, -0.02, -muzzle_len * 0.45), m2)
	for s in [-1.0, 1.0]:
		_add_cyl(jaw, 0.004, 0.022, 0.07, Vector3(s * 0.06, 0.03, -muzzle_len * 0.75), m_white)

	var arm_len = 0.56 if ("Orangutan" in key or is_gibbon) else (0.48 if is_ape else 0.34)
	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		var arm = Node3D.new()
		arm.name = "LegF" + side_tag
		arm.position = Vector3(s * (0.38 if is_ape else 0.24), torso_y + 0.18, -0.16)
		root.add_child(arm)
		_add_cyl(arm, 0.11 if is_ape else 0.065, 0.09 if is_ape else 0.055, arm_len, Vector3(0, -arm_len * 0.46, -0.04), m1, Vector3(14, 0, 0))
		_add_sphere(arm, 0.11 if is_ape else 0.07, 0.18 if is_ape else 0.12, Vector3(0, -arm_len * 0.95, -0.10), m2)

		var leg = Node3D.new()
		leg.name = "LegB" + side_tag
		leg.position = Vector3(s * (0.26 if is_ape else 0.17), torso_y - 0.18, 0.18)
		root.add_child(leg)
		_add_cyl(leg, 0.10 if is_ape else 0.065, 0.08 if is_ape else 0.05, 0.40 if is_ape else 0.30, Vector3(0, -0.18, 0.02), m1)
		_add_box(leg, Vector3(0.12, 0.07, 0.20), Vector3(0, -0.38 if is_ape else -0.28, -0.04), m2)

	if "Orangutan" in key:
		var rock_mat = _make_mat(Color(0.48, 0.46, 0.44), 0.90, 0.05)
		_add_sphere(root, 0.16, 0.28, Vector3(0.36, 0.38, -0.32), rock_mat, Vector3(1.15, 0.85, 1.05), "HeldRock")

	if not ("Gorilla" in key or "Chimpanzee" in key or "Orangutan" in key or is_gibbon):
		var tail = Node3D.new()
		tail.name = "TailPivot"
		tail.position = Vector3(0, torso_y + 0.04, 0.28)
		root.add_child(tail)
		var t_segs = 6 if "Lemur" in key else 4
		for t_i in range(t_segs):
			var t_mat = m1
			if "Lemur" in key:
				t_mat = m2 if (t_i % 2 == 0) else m3
			_add_cyl(tail, 0.038, 0.042, 0.20, Vector3(0, float(t_i) * 0.13 + 0.06, float(t_i) * 0.09 + 0.06), t_mat, Vector3(-38 + t_i * 8, 0, 0))

static func _build_crocodilian(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var body = _add_box(root, Vector3(0.62, 0.32, 1.35), Vector3(0, 0.26, 0.05), m1, Vector3.ZERO, "Torso")
	_add_box(body, Vector3(0.56, 0.12, 1.28), Vector3(0, -0.14, 0), m2, Vector3.ZERO, "Belly")
	for r in range(5):
		for c in [-1.0, 0.0, 1.0]:
			_add_box(body, Vector3(0.09, 0.08, 0.14), Vector3(c * 0.16, 0.18, -0.48 + float(r) * 0.24), m1, Vector3(-12, 0, 0), "Scute")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.30, -0.62)
	root.add_child(head)
	var snout_w = 0.15 if "Gharial" in key else (0.48 if "Alligator" in key else 0.40)
	var snout_l = 0.86 if "Gharial" in key else 0.68
	_add_box(head, Vector3(0.46, 0.20, 0.32), Vector3(0, 0.04, -0.12), m1)
	_add_box(head, Vector3(snout_w, 0.14, snout_l), Vector3(0, 0.0, -0.24 - snout_l * 0.5), m1)
	if "Gharial" in key:
		_add_sphere(head, 0.09, 0.16, Vector3(0, 0.09, -0.22 - snout_l * 0.88), m1, Vector3.ONE, "GharaBulb")
	_add_eyes(head, 0.16, 0.14, -0.14, 0.05, m_eye, m_dark)
	for t in range(5):
		for s in [-1.0, 1.0]:
			var tz = -0.32 - float(t) * (snout_l * 0.16)
			_add_cyl(head, 0.022, 0.003, 0.07, Vector3(s * (snout_w * 0.42), -0.08, tz), m_white)

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.06, -0.18)
	head.add_child(jaw)
	_add_box(jaw, Vector3(snout_w * 0.92, 0.10, snout_l), Vector3(0, -0.02, -snout_l * 0.45), m2)
	for t in range(5):
		for s in [-1.0, 1.0]:
			var tz = -0.12 - float(t) * (snout_l * 0.17)
			_add_cyl(jaw, 0.003, 0.024, 0.07, Vector3(s * (snout_w * 0.42), 0.05, tz), m_white)

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.26, 0.72)
	root.add_child(tail)
	for seg in range(4):
		var w = 0.46 * (1.0 - float(seg) * 0.20)
		var h = 0.26 * (1.0 - float(seg) * 0.16)
		var z = 0.22 + float(seg) * 0.32
		var t_seg = _add_box(tail, Vector3(w, h, 0.34), Vector3(0, 0, z), m1, Vector3.ZERO, "Coil" + str(seg))
		t_seg.set_meta("base_x", 0.0)
		_add_box(t_seg, Vector3(0.06, 0.10, 0.16), Vector3(0, h * 0.65, 0), m1)

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		for f_idx in range(2):
			var is_front = (f_idx == 0)
			var leg = Node3D.new()
			leg.name = ("LegF" if is_front else "LegB") + side_tag
			leg.position = Vector3(s * 0.34, 0.22, -0.38 if is_front else 0.42)
			root.add_child(leg)
			_add_box(leg, Vector3(0.18, 0.14, 0.16), Vector3(s * 0.06, -0.04, 0), m1, Vector3(0, 0, -s * 20.0))
			_add_box(leg, Vector3(0.16, 0.08, 0.24), Vector3(s * 0.12, -0.16, -0.04), m2)

static func _build_lizard(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var is_cham = ("Chameleon" in key)
	var is_frill = ("Frilled" in key)
	var is_gila = ("Gila" in key)
	var body_y = 0.46 if (is_cham or is_frill) else 0.32
	var body_scl = Vector3(0.62, 1.25, 1.32) if is_cham else (Vector3(1.18, 0.72, 1.38) if is_gila else Vector3(0.95, 0.68, 1.48))
	var body = _add_sphere(root, 0.30, 0.68, Vector3(0, body_y, 0.04), m1, body_scl, "Torso")
	_add_sphere(body, 0.25, 0.58, Vector3(0, -0.06, 0), m2, Vector3(0.88, 0.75, 1.25), "Belly")
	if is_gila:
		for b_i in range(4):
			_add_box(body, Vector3(0.56, 0.32, 0.10), Vector3(0, 0.04, -0.24 + float(b_i) * 0.16), m2, Vector3.ZERO, "BeadBand")
	elif is_cham:
		for c_i in range(6):
			_add_box(body, Vector3(0.05, 0.10, 0.08), Vector3(0, 0.28 - absf(float(c_i) - 2.5) * 0.03, -0.25 + float(c_i) * 0.10), m2)

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, body_y + (0.14 if is_frill else 0.06), -0.44)
	root.add_child(head)
	_add_sphere(head, 0.19, 0.38, Vector3.ZERO, m1, Vector3(0.95, 0.78, 1.22))
	_add_box(head, Vector3(0.18, 0.12, 0.26), Vector3(0, -0.02, -0.18), m1)

	if is_cham:
		_add_box(head, Vector3(0.12, 0.22, 0.22), Vector3(0, 0.14, 0.06), m1, Vector3(-28, 0, 0), "Casque")
		_add_cyl(head, 0.004, 0.022, 0.22, Vector3(0, 0.02, -0.30), m_white, Vector3(-86, 0, 0), "CenterHorn")
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.004, 0.020, 0.20, Vector3(s * 0.07, 0.06, -0.26), m_white, Vector3(-82, -s * 12.0, 0), "SideHorn")
			_add_sphere(head, 0.065, 0.13, Vector3(s * 0.12, 0.04, -0.12), m2, Vector3.ONE, "TurretEye")
	elif is_frill:
		var frill = Node3D.new()
		frill.name = "NeckFrill"
		frill.position = Vector3(0, 0.02, 0.06)
		head.add_child(frill)
		for s in [-1.0, 1.0]:
			_add_box(frill, Vector3(0.36, 0.42, 0.04), Vector3(s * 0.18, 0.02, 0.02), m2, Vector3(12, s * 22.0, -s * 14.0), "FrillWing")
			_add_box(frill, Vector3(0.24, 0.30, 0.05), Vector3(s * 0.16, 0.02, 0.01), m3, Vector3(12, s * 22.0, -s * 14.0))
	_add_eyes(head, 0.11, 0.04, -0.14, 0.038, m_eye, m_dark)

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.06, -0.08)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.16, 0.05, 0.24), Vector3(0, -0.02, -0.10), m2)
	if "Komodo" in key or "Monitor" in key:
		_add_box(jaw, Vector3(0.025, 0.01, 0.26), Vector3(0, 0.02, -0.28), m3, Vector3.ZERO, "ForkedTongue")
	elif is_cham:
		_add_cyl(jaw, 0.025, 0.018, 0.26, Vector3(0, 0.02, -0.22), m3, Vector3(-90, 0, 0), "BallisticTongue")

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, body_y - 0.02, 0.44)
	root.add_child(tail)
	if is_cham:
		for c_t in range(6):
			var ang = float(c_t) * 0.85
			var r_c = 0.22 - float(c_t) * 0.028
			_add_sphere(tail, 0.065 - float(c_t) * 0.007, 0.13, Vector3(0, -cos(ang) * r_c + 0.12, sin(ang) * r_c + 0.18), m2)
	elif is_gila:
		_add_cyl(tail, 0.05, 0.11, 0.48, Vector3(0, -0.04, 0.22), m2, Vector3(78, 0, 0))
	else:
		for seg in range(4):
			var t_s = _add_cyl(tail, 0.045 * (1.0 - float(seg) * 0.2), 0.065 * (1.0 - float(seg) * 0.2), 0.26, Vector3(0, -0.04 - float(seg) * 0.02, 0.14 + float(seg) * 0.22), m1, Vector3(82, 0, 0), "Coil" + str(seg))
			t_s.set_meta("base_x", 0.0)

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		for f_idx in range(2):
			var is_front = (f_idx == 0)
			var leg = Node3D.new()
			leg.name = ("LegF" if is_front else "LegB") + side_tag
			leg.position = Vector3(s * (0.18 if is_cham else 0.26), body_y - 0.08, -0.24 if is_front else 0.26)
			root.add_child(leg)
			var leg_h = 0.34 if (is_cham or is_frill) else 0.24
			_add_cyl(leg, 0.055, 0.042, leg_h, Vector3(s * 0.06, -leg_h * 0.45, 0), m1, Vector3(0, 0, -s * (14.0 if is_cham else 28.0)))
			_add_box(leg, Vector3(0.11, 0.05, 0.16), Vector3(s * 0.12, -leg_h * 0.90, -0.03), m2)

static func _build_serpent(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var has_hood = ("Cobra" in key)
	var has_rattle = ("Rattlesnake" in key)
	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.56 if has_hood else 0.24, -0.58)
	root.add_child(head)
	if has_hood:
		_add_sphere(head, 0.32, 0.52, Vector3(0, -0.14, 0.08), m2, Vector3(1.35, 1.0, 0.35), "CobraHood")
		_add_sphere(head, 0.30, 0.48, Vector3(0, -0.14, 0.10), m1, Vector3(1.25, 0.95, 0.32))
	_add_sphere(head, 0.17, 0.24, Vector3(0, 0, -0.06), m1, Vector3(1.15, 0.68, 1.45))
	_add_eyes(head, 0.11, 0.04, -0.14, 0.036, m_eye, m_dark)
	if "HornedViper" in key:
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.004, 0.022, 0.12, Vector3(s * 0.10, 0.10, -0.14), m3, Vector3(-18, 0, -s * 22.0), "ViperHorn")
	for s in [-1.0, 1.0]:
		_add_cyl(head, 0.018, 0.002, 0.09, Vector3(s * 0.06, -0.05, -0.20), m_white, Vector3(14, 0, 0), "Fang")

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.04, -0.04)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.20, 0.05, 0.26), Vector3(0, -0.02, -0.10), m2)
	_add_box(jaw, Vector3(0.02, 0.01, 0.22), Vector3(0, 0.02, -0.28), _make_mat(Color(0.95, 0.15, 0.22), 0.4, 0.1, 0.4), Vector3.ZERO, "Tongue")

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.14, -0.40)
	root.add_child(tail)
	var is_constrictor = ("Anaconda" in key or "Python" in key or "Gaboon" in key)
	for i in range(9):
		var frac = float(i) / 8.0
		var rad = lerpf(0.19 if is_constrictor else 0.15, 0.05, frac)
		var x_off = sin(float(i) * 0.95) * 0.24
		var y_off = 0.32 * (1.0 - float(i) * 0.32) if (has_hood and i < 3) else 0.0
		var seg_mat = m1 if (i % 2 == 0) else m2
		if "Coral" in key and (i % 3 == 2):
			seg_mat = m3
		var coil = _add_sphere(tail, rad, rad * 2.2, Vector3(x_off, y_off, float(i) * 0.20), seg_mat, Vector3(1.0, 0.78, 1.35), "Coil" + str(i))
		coil.set_meta("base_x", x_off)
	if has_rattle:
		var rattle_piv = Node3D.new()
		rattle_piv.name = "RattlePivot"
		rattle_piv.position = Vector3(sin(8.0 * 0.95) * 0.24, 0.10, 1.65)
		tail.add_child(rattle_piv)
		for r in range(4):
			_add_sphere(rattle_piv, 0.055 - float(r) * 0.008, 0.09, Vector3(0, float(r) * 0.05, float(r) * 0.04), m3)
	elif "SeaKrait" in key:
		_add_box(tail, Vector3(0.03, 0.18, 0.26), Vector3(sin(8.0 * 0.95) * 0.24, 0.04, 1.72), m1, Vector3.ZERO, "PaddleTail")

static func _build_avian_flyer(root: Node3D, key: String, info: Dictionary, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var body = _add_sphere(root, 0.24, 0.62, Vector3(0, 0.55, 0), m1, Vector3(0.92, 0.85, 1.35), "Torso")
	_add_sphere(body, 0.20, 0.48, Vector3(0, -0.04, -0.08), m2, Vector3(0.88, 0.80, 1.15), "Breast")
	if "Condor" in key:
		_add_cyl(root, 0.16, 0.19, 0.12, Vector3(0, 0.66, -0.26), m_white, Vector3(45, 0, 0), "CondorRuff")
	elif "Goose" in key:
		_add_cyl(root, 0.065, 0.085, 0.28, Vector3(0, 0.68, -0.26), m2, Vector3(28, 0, 0), "GooseNeck")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.74, -0.34)
	root.add_child(head)
	var head_mat = m_white if "BaldEagle" in key else (m2 if "Goose" in key else (m3 if "Condor" in key else m1))
	_add_sphere(head, 0.16, 0.32, Vector3.ZERO, head_mat)
	if "Woodpecker" in key or "BlueJay" in key or "Cockatoo" in key or "Kingfisher" in key or "Harpy" in key:
		var cr_mat = m3 if ("Cockatoo" in key or "Woodpecker" in key) else m1
		_add_box(head, Vector3(0.06, 0.14, 0.18), Vector3(0, 0.12, 0.04), cr_mat, Vector3(-28, 0, 0), "Crest")
	elif "Owl" in key:
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.01, 0.04, 0.14, Vector3(s * 0.11, 0.14, -0.04), m1, Vector3(-15, 0, -s * 24.0), "OwlTuft")
			_add_sphere(head, 0.075, 0.15, Vector3(s * 0.08, 0.02, -0.11), m2, Vector3(1.1, 1.1, 0.35), "FacialDisc")
	elif "Goose" in key:
		_add_box(head, Vector3(0.24, 0.08, 0.10), Vector3(0, -0.04, -0.04), m3, Vector3.ZERO, "Chinstrap")
	_add_eyes(head, 0.10 if "Owl" in key else 0.11, 0.03, -0.10, 0.042 if "Owl" in key else 0.034, m_eye, m_dark)

	var is_raptor = ("Eagle" in key or "Falcon" in key or "Owl" in key or "Condor" in key)
	var beak_len = 0.38 if ("Toucan" in key or "Pelican" in key or "Hornbill" in key or "Seagull" in key) else (0.28 if "Woodpecker" in key else 0.24)
	var beak_r = 0.09 if ("Toucan" in key or "Pelican" in key or "Hornbill" in key) else 0.048
	_add_cyl(head, 0.006, beak_r, beak_len, Vector3(0, -0.01, -0.14 - beak_len * 0.45), m3, Vector3(-98 if is_raptor else -90, 0, 0), "Beak")
	if is_raptor:
		_add_cyl(head, 0.003, 0.028, 0.10, Vector3(0, -0.06, -0.16 - beak_len * 0.82), m3, Vector3(-155, 0, 0), "BeakHook")
	elif "Pelican" in key:
		_add_sphere(head, 0.11, 0.26, Vector3(0, -0.10, -0.28), m3, Vector3(0.85, 0.95, 1.45), "PelicanPouch")

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		var wing = Node3D.new()
		wing.name = "Wing" + side_tag
		wing.position = Vector3(s * 0.20, 0.62, -0.04)
		root.add_child(wing)
		_add_box(wing, Vector3(0.58, 0.045, 0.34), Vector3(s * 0.28, 0, 0.02), m1, Vector3(0, -s * 8.0, 0))
		_add_box(wing, Vector3(0.46, 0.035, 0.24), Vector3(s * 0.66, 0, 0.08), m2 if not "BaldEagle" in key else m1, Vector3(0, -s * 18.0, 0))

		var talon = Node3D.new()
		talon.name = "LegB" + side_tag
		talon.position = Vector3(s * 0.10, 0.38, -0.04)
		root.add_child(talon)
		_add_cyl(talon, 0.028, 0.020, 0.18, Vector3(0, -0.08, -0.02), m3, Vector3(24, 0, 0))
		_add_box(talon, Vector3(0.08, 0.035, 0.12), Vector3(0, -0.16, -0.06), m3)

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.52, 0.32)
	root.add_child(tail)
	_add_box(tail, Vector3(0.32, 0.04, 0.38), Vector3(0, -0.02, 0.16), m_white if "BaldEagle" in key else m1, Vector3(-14, 0, 0))

	if info.get("rock", false):
		var rock_mat = _make_mat(Color(0.48, 0.46, 0.44), 0.90, 0.05)
		_add_sphere(root, 0.13, 0.24, Vector3(0, 0.20, -0.10), rock_mat, Vector3(1.15, 0.85, 1.05), "HeldRock")

static func _build_avian_walker(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var tall = ("Ostrich" in key or "Cassowary" in key or "Emu" in key or "Secretary" in key or "Shoebill" in key or "Swan" in key or "Goose" in key)
	var body_y = 0.78 if tall else 0.48
	var body = _add_sphere(root, 0.32 if tall else 0.24, 0.72 if tall else 0.52, Vector3(0, body_y, 0.06), m1, Vector3(0.95, 0.90, 1.28), "Torso")
	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		var w_piv = Node3D.new()
		w_piv.name = "Wing" + side_tag
		w_piv.position = Vector3(s * 0.28, body_y + 0.04, -0.04)
		root.add_child(w_piv)
		_add_box(w_piv, Vector3(0.08, 0.26, 0.42), Vector3(s * 0.04, -0.02, 0.06), m2)

	var neck_h = 0.52 if tall else 0.24
	var neck_mat = m2 if ("Ostrich" in key or "Cassowary" in key) else m1
	_add_cyl(root, 0.065, 0.095, neck_h, Vector3(0, body_y + neck_h * 0.55, -0.24), neck_mat, Vector3(16, 0, 0), "Neck")
	if "Cassowary" in key:
		_add_box(root, Vector3(0.06, 0.18, 0.06), Vector3(0, body_y + 0.16, -0.32), m3, Vector3.ZERO, "Wattle")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, body_y + neck_h + 0.10, -0.32)
	root.add_child(head)
	_add_sphere(head, 0.14, 0.28, Vector3.ZERO, neck_mat)
	if "Cassowary" in key:
		_add_box(head, Vector3(0.06, 0.22, 0.24), Vector3(0, 0.15, -0.02), m3, Vector3(-18, 0, 0), "Casque")
	elif "Secretary" in key:
		for q_i in range(5):
			_add_cyl(head, 0.005, 0.018, 0.22, Vector3((float(q_i) - 2.0) * 0.025, 0.10, 0.14), m2, Vector3(48, 0, (float(q_i) - 2.0) * 8.0), "CrestQuill")
	var beak_w = 0.20 if "Shoebill" in key else 0.08
	var beak_l = 0.34 if "Shoebill" in key else 0.24
	_add_box(head, Vector3(beak_w, 0.11 if "Shoebill" in key else 0.08, beak_l), Vector3(0, -0.02, -0.14 - beak_l * 0.4), m3, Vector3.ZERO, "Beak")
	_add_eyes(head, 0.09, 0.03, -0.08, 0.032, m_eye, m_dark)

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, body_y + 0.04, 0.42)
	root.add_child(tail)
	_add_box(tail, Vector3(0.28, 0.16, 0.32), Vector3(0, -0.02, 0.12), m2, Vector3(-18, 0, 0))

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		var leg = Node3D.new()
		leg.name = "LegB" + side_tag
		leg.position = Vector3(s * 0.16, body_y - 0.16, 0.02)
		root.add_child(leg)
		var leg_h = body_y - 0.14
		_add_cyl(leg, 0.048, 0.035, leg_h, Vector3(0, -leg_h * 0.5, 0), m2 if "Secretary" in key else m3)
		_add_box(leg, Vector3(0.14, 0.05, 0.24), Vector3(0, -leg_h, -0.06), m3)

static func _build_insect(root: Node3D, key: String, arch: String, m1: Material, m2: Material, m3: Material, m_dark: Material, _m_eye: Material) -> void:
	var is_flyer = (arch == "FLYING_INSECT")
	var is_beetle = (arch == "BEETLE")
	var is_mantis = ("Mantis" in key)
	var is_dragonfly = ("Dragonfly" in key)
	var y_base = 0.45 if is_flyer else 0.28
	var thorax = _add_sphere(root, 0.16, 0.36, Vector3(0, y_base, -0.08), m1, Vector3(0.95, 0.85, 1.18), "Thorax")
	if is_mantis:
		_add_cyl(root, 0.055, 0.075, 0.34, Vector3(0, y_base + 0.16, -0.24), m1, Vector3(-36, 0, 0), "Prothorax")
	elif "Hercules" in key:
		_add_cyl(thorax, 0.014, 0.065, 0.56, Vector3(0, 0.16, -0.34), m2, Vector3(-86, 0, 0), "ThoraxHorn")

	var abd_r = 0.28 if is_beetle else (0.12 if is_dragonfly else 0.22)
	var abd_scl = Vector3(0.75, 0.75, 2.8) if is_dragonfly else Vector3(1.05, 0.85, 1.45)
	var abd = _add_sphere(root, abd_r, abd_r * 2.2, Vector3(0, y_base + 0.02, 0.36 if is_dragonfly else 0.30), m1 if is_beetle else m2, abd_scl, "Abdomen")
	if "Hornet" in key or "Wasp" in key or "Bee" in key:
		for st in range(3):
			_add_box(abd, Vector3(0.38, 0.26, 0.08), Vector3(0, 0, -0.14 + float(st) * 0.14), m1)
		_add_cyl(abd, 0.003, 0.04, 0.18, Vector3(0, -0.02, 0.36), m_dark, Vector3(85, 0, 0), "Stinger")
	elif "Bombardier" in key:
		_add_sphere(abd, 0.12, 0.24, Vector3(0, -0.02, 0.28), m3, Vector3.ONE, "AcidNozzle")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, y_base + (0.28 if is_mantis else 0.04), -0.36 if is_mantis else -0.32)
	root.add_child(head)
	_add_sphere(head, 0.14, 0.26, Vector3.ZERO, m1, Vector3(1.18, 0.85, 0.75) if is_mantis else Vector3.ONE)
	_add_eyes(head, 0.11 if is_mantis else 0.10, 0.04 if is_mantis else 0.03, -0.08, 0.052 if (is_mantis or is_dragonfly) else 0.045, m3, m_dark)
	for s in [-1.0, 1.0]:
		_add_cyl(head, 0.008, 0.018, 0.24, Vector3(s * 0.06, 0.14, -0.14), m_dark, Vector3(-35, 0, -s * 22.0), "Antenna")

	if "Hercules" in key or "Rhino" in key or "Goliath" in key:
		_add_cyl(head, 0.015, 0.055, 0.46, Vector3(0, 0.06, -0.26), m2, Vector3(-52, 0, 0), "BeetleHorn")
		_add_cyl(head, 0.012, 0.045, 0.32, Vector3(0, -0.04, -0.22), m2, Vector3(-78, 0, 0), "LowerHorn")
	elif "Stag" in key or "Ant" in key or "Termite" in key or "TigerBeetle" in key:
		for s in [-1.0, 1.0]:
			var m_len = 0.38 if "Stag" in key else 0.18
			_add_box(head, Vector3(0.05, 0.04, m_len), Vector3(s * 0.09, -0.02, -0.12 - m_len * 0.4), m3 if "Stag" in key else m2, Vector3(0, -s * 18.0, 0), "Mandible")
	elif "Mosquito" in key or "Assassin" in key:
		_add_cyl(head, 0.004, 0.016, 0.36, Vector3(0, -0.04, -0.24), m3, Vector3(-78, 0, 0), "Proboscis")

	if is_flyer or "Locust" in key or is_mantis:
		var wing_mat = _make_mat(Color(0.85, 0.94, 1.0), 0.15, 0.2, 0.25)
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var wing = Node3D.new()
			wing.name = "WingL" if s < 0 else "WingR"
			wing.position = Vector3(s * 0.14, y_base + 0.14, -0.04)
			root.add_child(wing)
			_add_box(wing, Vector3(0.56 if is_dragonfly else 0.52, 0.015, 0.18 if is_dragonfly else 0.22), Vector3(s * 0.26, 0, -0.02 if is_dragonfly else 0.04), wing_mat, Vector3(0, -s * 8.0, 0))
			if is_dragonfly:
				_add_box(wing, Vector3(0.50, 0.015, 0.16), Vector3(s * 0.24, -0.01, 0.18), wing_mat, Vector3(0, -s * 18.0, 0), "HindWing")

	for leg_i in range(3):
		var z_off = -0.16 + float(leg_i) * 0.16
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var leg = Node3D.new()
			if leg_i == 0:
				leg.name = "LegF" + ("L" if s < 0 else "R")
			elif leg_i == 2:
				leg.name = "LegB" + ("L" if s < 0 else "R")
			else:
				leg.name = "LegM" + ("L" if s < 0 else "R")
			leg.position = Vector3(s * 0.15, (y_base + 0.16) if (is_mantis and leg_i == 0) else (y_base - 0.04), -0.28 if (is_mantis and leg_i == 0) else z_off)
			root.add_child(leg)
			if is_mantis and leg_i == 0:
				_add_box(leg, Vector3(0.05, 0.24, 0.07), Vector3(s * 0.04, -0.06, -0.10), m2, Vector3(-42, 0, 0), "ScytheFemur")
				_add_box(leg, Vector3(0.04, 0.24, 0.06), Vector3(s * 0.04, -0.06, -0.24), m3, Vector3(48, 0, 0), "ScytheBlade")
			else:
				_add_cyl(leg, 0.022, 0.018, 0.16, Vector3(s * 0.08, 0.02, 0), m2, Vector3(0, 0, -s * 62.0))
				_add_cyl(leg, 0.018, 0.012, 0.22, Vector3(s * 0.18, -0.10, 0), m2, Vector3(0, 0, -s * 18.0))

static func _build_arachnid_or_crawler(root: Node3D, key: String, arch: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_eye: Material) -> void:
	if arch == "CENTIPEDE":
		var head = Node3D.new()
		head.name = "HeadPivot"
		head.position = Vector3(0, 0.20, -0.58)
		root.add_child(head)
		_add_box(head, Vector3(0.28, 0.12, 0.24), Vector3.ZERO, m2)
		_add_eyes(head, 0.10, 0.03, -0.10, 0.03, m_eye, m_dark)
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.008, 0.016, 0.26, Vector3(s * 0.08, 0.04, -0.20), m1, Vector3(-68, -s * 24.0, 0), "Antenna")
			_add_box(head, Vector3(0.05, 0.04, 0.18), Vector3(s * 0.14, -0.02, -0.14), m3, Vector3(0, s * 24.0, 0), "Forcipule")
		for seg in range(7):
			var z = -0.34 + float(seg) * 0.20
			var seg_piv = Node3D.new()
			seg_piv.name = "Seg" + str(seg)
			seg_piv.position = Vector3(0, 0.18, z)
			root.add_child(seg_piv)
			_add_box(seg_piv, Vector3(0.28, 0.11, 0.18), Vector3.ZERO, m1 if seg % 2 == 0 else m2)
			for s in [-1.0, 1.0]:
				_add_cyl(seg_piv, 0.018, 0.010, 0.24, Vector3(s * 0.22, -0.06, 0), m2, Vector3(0, 0, -s * 54.0))
			if seg == 6:
				for s in [-1.0, 1.0]:
					_add_cyl(seg_piv, 0.006, 0.020, 0.26, Vector3(s * 0.09, 0.0, 0.18), m1, Vector3(78, s * 16.0, 0), "Cerci")
		return

	_add_sphere(root, 0.22, 0.36, Vector3(0, 0.28, -0.14), m1, Vector3(1.1, 0.72, 1.15), "Cephalothorax")
	var abd = _add_sphere(root, 0.30, 0.56, Vector3(0, 0.34, 0.28), m1, Vector3(1.05, 0.88, 1.25), "Abdomen")
	if "BlackWidow" in key:
		_add_box(abd, Vector3(0.14, 0.04, 0.20), Vector3(0, 0.25, 0), m2, Vector3.ZERO, "Hourglass")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.28, -0.34)
	root.add_child(head)
	_add_eyes(head, 0.07, 0.05, -0.04, 0.032, m3, m_dark)
	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		if arch == "SCORPION":
			var claw = Node3D.new()
			claw.name = "LegF" + side_tag
			claw.position = Vector3(s * 0.20, 0.28, -0.30)
			root.add_child(claw)
			_add_cyl(claw, 0.032, 0.028, 0.22, Vector3(s * 0.08, 0, -0.08), m2, Vector3(75, -s * 28.0, 0))
			_add_box(claw, Vector3(0.14, 0.08, 0.28), Vector3(s * 0.12, 0.0, -0.24), m2, Vector3(0, -s * 14.0, 0), "Pincer")
		else:
			_add_cyl(head, 0.032, 0.010, 0.16, Vector3(s * 0.07, -0.05, -0.08), m3, Vector3(24, 0, 0), "Chelicera")

	if arch == "SCORPION":
		var tail = Node3D.new()
		tail.name = "TailPivot"
		tail.position = Vector3(0, 0.32, 0.42)
		root.add_child(tail)
		var seg_y: Array[float] = [0.06, 0.20, 0.36, 0.50, 0.58]
		var seg_z: Array[float] = [0.06, 0.14, 0.14, 0.04, -0.08]
		for t in range(5):
			_add_sphere(tail, 0.09 - float(t) * 0.006, 0.18, Vector3(0, seg_y[t], seg_z[t]), m1)
		_add_cyl(tail, 0.005, 0.045, 0.20, Vector3(0, 0.62, -0.16), m3, Vector3(-75, 0, 0), "Stinger")

	for leg_i in range(4):
		var z_off = -0.24 + float(leg_i) * 0.14
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var leg = Node3D.new()
			leg.name = ("LegF" if leg_i < 2 else "LegB") + ("L" if s < 0 else "R") + str(leg_i)
			leg.position = Vector3(s * 0.18, 0.26, z_off)
			root.add_child(leg)
			_add_cyl(leg, 0.026, 0.022, 0.20, Vector3(s * 0.09, 0.05, 0), m2, Vector3(0, 0, -s * 64.0))
			_add_cyl(leg, 0.022, 0.014, 0.28, Vector3(s * 0.22, -0.08, 0), m2, Vector3(0, 0, -s * 22.0))

static func _build_aquatic(root: Node3D, key: String, arch: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	if arch == "EEL":
		var head = Node3D.new()
		head.name = "HeadPivot"
		head.position = Vector3(0, 0.30, -0.58)
		root.add_child(head)
		_add_sphere(head, 0.16, 0.32, Vector3.ZERO, m1, Vector3(1.1, 0.82, 1.35))
		_add_eyes(head, 0.10, 0.04, -0.12, 0.032, m3, m_dark)
		var tail = Node3D.new()
		tail.name = "TailPivot"
		tail.position = Vector3(0, 0.28, -0.38)
		root.add_child(tail)
		for i in range(7):
			var x_w = sin(float(i) * 0.85) * 0.18
			var coil = _add_sphere(tail, 0.14 * (1.0 - float(i) * 0.09), 0.28, Vector3(x_w, 0, float(i) * 0.20), m1 if i % 2 == 0 else m2, Vector3(0.85, 1.0, 1.35), "Coil" + str(i))
			coil.set_meta("base_x", x_w)
			if "Electric" in key and i < 5:
				for s in [-1.0, 1.0]:
					_add_sphere(coil, 0.032, 0.064, Vector3(s * 0.12, 0.0, 0.0), m3, Vector3.ONE, "ElectricNode")
		return

	if arch == "WALRUS" or "Walrus" in key:
		var w_body = _add_sphere(root, 0.44, 0.92, Vector3(0, 0.44, 0.08), m1, Vector3(1.10, 0.82, 1.42), "Torso")
		_add_sphere(w_body, 0.38, 0.82, Vector3(0, -0.08, 0.0), m2, Vector3(1.02, 0.72, 1.34), "Belly")
		_add_sphere(root, 0.34, 0.68, Vector3(0, 0.64, -0.38), m1, Vector3(1.05, 1.08, 1.05), "WalrusNeck")
		var w_head = Node3D.new()
		w_head.name = "HeadPivot"
		w_head.position = Vector3(0, 0.82, -0.62)
		root.add_child(w_head)
		_add_sphere(w_head, 0.26, 0.48, Vector3.ZERO, m1, Vector3(1.05, 0.95, 1.08))
		_add_box(w_head, Vector3(0.36, 0.20, 0.24), Vector3(0, -0.04, -0.20), m2, Vector3.ZERO, "WhiskerPad")
		_add_eyes(w_head, 0.16, 0.08, -0.14, 0.038, m_eye, m_dark)
		for s in [-1.0, 1.0]:
			_add_cyl(w_head, 0.046, 0.009, 0.48, Vector3(s * 0.12, -0.26, -0.22), m3, Vector3(10, 0, 0), "Tusk")
			for w_i in range(3):
				_add_cyl(w_head, 0.005, 0.012, 0.18, Vector3(s * 0.18, -0.06 - float(w_i) * 0.03, -0.26), m3, Vector3(0, 0, -s * 42.0), "Whisker")
		var w_jaw = Node3D.new()
		w_jaw.name = "JawPivot"
		w_jaw.position = Vector3(0, -0.12, -0.10)
		w_head.add_child(w_jaw)
		_add_box(w_jaw, Vector3(0.24, 0.08, 0.22), Vector3(0, -0.02, -0.10), m1)
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var fl = Node3D.new()
			fl.name = "LegF" + ("L" if s < 0 else "R")
			fl.position = Vector3(s * 0.42, 0.30, -0.26)
			root.add_child(fl)
			_add_box(fl, Vector3(0.42, 0.07, 0.28), Vector3(s * 0.16, -0.08, 0.02), m1, Vector3(8, s * 18.0, -s * 24.0))
		var w_tail = Node3D.new()
		w_tail.name = "TailPivot"
		w_tail.position = Vector3(0, 0.26, 0.68)
		root.add_child(w_tail)
		for s in [-1.0, 1.0]:
			_add_box(w_tail, Vector3(0.24, 0.06, 0.38), Vector3(s * 0.18, -0.04, 0.16), m1, Vector3(-8, -s * 22.0, 0))
		return

	var is_manta = ("MantaRay" in key)
	var is_puffer = ("Pufferfish" in key)
	var is_piranha = ("Piranha" in key)
	var body_scale = Vector3(1.55, 0.35, 1.35) if is_manta else (Vector3(1.18, 1.15, 1.18) if is_puffer else (Vector3(0.58, 1.18, 1.25) if is_piranha else Vector3(0.88, 0.92, 1.48)))
	var body = _add_sphere(root, 0.30, 0.72, Vector3(0, 0.44, 0.02), m1, body_scale, "Torso")
	_add_sphere(body, 0.26, 0.62, Vector3(0, -0.08, -0.02), m2, Vector3(0.82, 0.75, 1.38), "Belly")
	if not is_manta:
		var df_h = 0.52 if ("Orca" in key or "Swordfish" in key or "Megalodon" in key) else 0.34
		_add_box(body, Vector3(0.05, df_h, 0.26), Vector3(0, 0.32, 0.04), m1, Vector3(-22, 0, 0), "DorsalFin")
	if "Orca" in key:
		_add_sphere(body, 0.16, 0.32, Vector3(0, 0.18, 0.20), m3, Vector3(1.08, 0.75, 1.15), "SaddlePatch")
	elif is_puffer:
		for sp_i in range(10):
			var ang = float(sp_i) * TAU / 10.0
			_add_cyl(body, 0.005, 0.028, 0.18, Vector3(cos(ang) * 0.28, sin(ang) * 0.22, -0.10 + float(sp_i % 3) * 0.12), m3, Vector3(0, 0, rad_to_deg(-ang + PI * 0.5)), "PufferSpine")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.44, -0.42)
	root.add_child(head)
	if "Hammerhead" in key:
		_add_box(head, Vector3(0.76, 0.12, 0.22), Vector3(0, 0.04, -0.14), m1, Vector3.ZERO, "Cephalofoil")
		_add_eyes(head, 0.36, 0.04, -0.16, 0.042, m_eye, m_dark)
	else:
		_add_sphere(head, 0.22, 0.46, Vector3(0, 0.02, -0.10), m1, Vector3(0.95, 0.85, 1.25))
		var eye_y = 0.18 if "Mudskipper" in key else 0.06
		_add_eyes(head, 0.16, eye_y, -0.16, 0.046 if "Mudskipper" in key else 0.042, m_eye, m_dark)
	if "Orca" in key:
		for s in [-1.0, 1.0]:
			_add_sphere(head, 0.06, 0.14, Vector3(s * 0.18, 0.08, -0.06), m2, Vector3(0.5, 0.8, 1.3), "EyePatch")
	if "Anglerfish" in key:
		_add_cyl(head, 0.01, 0.02, 0.32, Vector3(0, 0.24, -0.18), m1, Vector3(-42, 0, 0))
		_add_sphere(head, 0.07, 0.14, Vector3(0, 0.34, -0.32), _make_mat(Color(0.3, 1.0, 0.85), 0.1, 0.2, 2.2), Vector3.ONE, "Esclure")
	elif "Swordfish" in key:
		_add_cyl(head, 0.006, 0.042, 0.62, Vector3(0, 0.02, -0.46), m3, Vector3(-90, 0, 0), "SwordBill")
	elif "WalkingCatfish" in key:
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.005, 0.016, 0.32, Vector3(s * 0.16, -0.04, -0.22), m3, Vector3(0, 0, -s * 55.0), "Barbel")

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.08, -0.06)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.28, 0.09 if is_piranha else 0.08, 0.34 if is_piranha else 0.30), Vector3(0, -0.02, -0.14 if is_piranha else -0.12), m2)
	if arch == "SHARK" or is_piranha or "Angler" in key or "Barracuda" in key:
		for s in [-1.0, 0.0, 1.0]:
			_add_cyl(jaw, 0.003, 0.026, 0.08, Vector3(s * 0.08, 0.05, -0.22), m_white)
			_add_cyl(head, 0.024, 0.003, 0.08, Vector3(s * 0.08, -0.05, -0.26), m_white)

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var fin = Node3D.new()
		fin.name = ("Wing" if is_manta else "LegF") + ("L" if s < 0 else "R")
		fin.position = Vector3(s * 0.24, 0.32, -0.14)
		root.add_child(fin)
		var fin_sz = Vector3(0.68, 0.04, 0.56) if is_manta else Vector3(0.32, 0.05, 0.22)
		var fin_off = Vector3(s * 0.32, 0.0, 0.06) if is_manta else Vector3(s * 0.14, -0.04, 0)
		_add_box(fin, fin_sz, fin_off, m1, Vector3(0, 0, -s * (8.0 if is_manta else 22.0)))

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.44, 0.48)
	root.add_child(tail)
	_add_box(tail, Vector3(0.16, 0.20, 0.36), Vector3(0, 0, 0.16), m1)
	if "Orca" in key:
		_add_box(tail, Vector3(0.54, 0.05, 0.24), Vector3(0, 0.0, 0.38), m1, Vector3.ZERO, "HorizontalFluke")
	elif is_manta:
		_add_cyl(tail, 0.006, 0.03, 0.65, Vector3(0, 0, 0.42), m_dark, Vector3(88, 0, 0), "WhipTail")
	else:
		_add_box(tail, Vector3(0.06, 0.48, 0.24), Vector3(0, 0.04, 0.38), m1)

static func _build_crab(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, _m_dark: Material, _m_eye: Material) -> void:
	var is_shrimp = ("Shrimp" in key)
	var cara_scl = Vector3(0.88, 0.72, 1.38) if is_shrimp else Vector3(1.28, 0.65, 1.05)
	_add_sphere(root, 0.34, 0.56, Vector3(0, 0.32, -0.04 if is_shrimp else 0.04), m1, cara_scl, "Carapace")
	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.38, -0.32 if is_shrimp else -0.26)
	root.add_child(head)
	for s in [-1.0, 1.0]:
		_add_cyl(head, 0.02, 0.025, 0.14, Vector3(s * 0.12, 0.08, -0.04), m2)
		_add_sphere(head, 0.045, 0.09, Vector3(s * 0.12, 0.16, -0.06), m3)
		var claw = Node3D.new()
		claw.name = "LegF" + ("L" if s < 0 else "R")
		claw.position = Vector3(s * (0.24 if is_shrimp else 0.34), 0.28, -0.22 if is_shrimp else -0.18)
		root.add_child(claw)
		var c_scale = 1.55 if ("Pistol" in key and s > 0) else (0.75 if ("Pistol" in key and s < 0) else 1.0)
		if "MantisShrimp" in key:
			_add_sphere(claw, 0.12, 0.26, Vector3(s * 0.04, -0.04, -0.18), m3, Vector3(0.85, 1.1, 1.25), "RaptorialClub")
		else:
			_add_box(claw, Vector3(0.18, 0.14, 0.34) * c_scale, Vector3(s * 0.08, 0, -0.18), m2, Vector3(0, -s * 16.0, 0), "PincerClaw")
	if is_shrimp:
		var tail = Node3D.new()
		tail.name = "TailPivot"
		tail.position = Vector3(0, 0.28, 0.32)
		root.add_child(tail)
		for t_s in range(4):
			_add_box(tail, Vector3(0.28 - float(t_s) * 0.04, 0.16 - float(t_s) * 0.02, 0.18), Vector3(0, -float(t_s) * 0.02, float(t_s) * 0.16), m2 if t_s % 2 == 0 else m1)
	for leg_i in range(3):
		var z_off = -0.08 + float(leg_i) * 0.14
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var leg = Node3D.new()
			leg.name = ("LegF" if leg_i == 0 else "LegB") + ("L" if s < 0 else "R") + str(leg_i + 1)
			leg.position = Vector3(s * (0.24 if is_shrimp else 0.34), 0.24, z_off)
			root.add_child(leg)
			_add_cyl(leg, 0.028, 0.022, 0.20, Vector3(s * 0.10, 0.02, 0), m1, Vector3(0, 0, -s * 62.0))
			_add_cyl(leg, 0.022, 0.014, 0.24, Vector3(s * 0.22, -0.10, 0), m2, Vector3(0, 0, -s * 20.0))

static func _build_tank_mammal(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, _m_white: Material, m_eye: Material) -> void:
	var body = _add_sphere(root, 0.48, 0.96, Vector3(0, 0.72, 0.06), m1, Vector3(1.05, 0.95, 1.32), "Torso")
	_add_sphere(body, 0.42, 0.82, Vector3(0, -0.08, 0), m2, Vector3(0.95, 0.85, 1.25))
	if "Mammoth" in key:
		_add_sphere(body, 0.38, 0.76, Vector3(0, 0.22, -0.22), m1, Vector3(1.05, 1.05, 0.95), "WoolHump")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.86, -0.52)
	root.add_child(head)
	_add_sphere(head, 0.30, 0.58, Vector3(0, 0, -0.08), m1, Vector3(1.0, 0.92, 1.18))
	_add_eyes(head, 0.20, 0.06, -0.22, 0.042, m_eye, m_dark)

	if "Elephant" in key or "Mammoth" in key:
		for s_idx in range(2):
			var s = -1.0 if s_idx == 0 else 1.0
			var ear_piv = Node3D.new()
			ear_piv.name = "Ear" + ("L" if s < 0 else "R")
			ear_piv.position = Vector3(s * 0.26, 0.04, 0.02)
			head.add_child(ear_piv)
			var ear_sz = Vector3(0.06, 0.34, 0.26) if "Mammoth" in key else Vector3(0.06, 0.52, 0.42)
			_add_box(ear_piv, ear_sz, Vector3(s * 0.10, -0.02, 0.02), m2, Vector3(0, s * 28.0, 0), "EarBlade")
			_add_cyl(head, 0.016, 0.058, 0.68 if "Mammoth" in key else 0.58, Vector3(s * 0.16, -0.14, -0.38), m3, Vector3(-68, s * (16.0 if "Mammoth" in key else 6.0), 0), "Tusk")
		var tr_piv = Node3D.new()
		tr_piv.name = "TrunkPivot"
		tr_piv.position = Vector3(0, -0.04, -0.24)
		head.add_child(tr_piv)
		_add_cyl(tr_piv, 0.11, 0.06, 0.56, Vector3(0, -0.22, -0.10), m1, Vector3(26, 0, 0), "Trunk")
		_add_cyl(tr_piv, 0.06, 0.045, 0.24, Vector3(0, -0.46, -0.28), m1, Vector3(68, 0, 0), "TrunkTip")
	elif "Rhino" in key:
		_add_box(head, Vector3(0.32, 0.20, 0.32), Vector3(0, -0.04, -0.22), m1)
		_add_cyl(head, 0.015, 0.095, 0.44, Vector3(0, 0.18, -0.34), m3, Vector3(-24, 0, 0), "FrontHorn")
		_add_cyl(head, 0.012, 0.06, 0.22, Vector3(0, 0.12, -0.18), m3, Vector3(-18, 0, 0), "RearHorn")
	elif "Buffalo" in key or "Bison" in key:
		_add_box(head, Vector3(0.42, 0.14, 0.22), Vector3(0, 0.18, -0.08), m3, Vector3.ZERO, "BossShield")
		for s in [-1.0, 1.0]:
			_add_cyl(head, 0.015, 0.065, 0.40, Vector3(s * 0.28, 0.18, -0.08), m3, Vector3(0, 0, -s * 58.0), "Horn")
	elif "Hippo" in key:
		_add_box(head, Vector3(0.42, 0.26, 0.38), Vector3(0, -0.02, -0.24), m1, Vector3.ZERO, "HippoMuzzle")

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.12, -0.14)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.36 if "Hippo" in key else 0.32, 0.12, 0.36 if "Hippo" in key else 0.32), Vector3(0, -0.02, -0.14), m2)
	if "Hippo" in key:
		for s in [-1.0, 1.0]:
			_add_cyl(jaw, 0.01, 0.042, 0.20, Vector3(s * 0.13, 0.09, -0.26), m3)

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.68, 0.62)
	root.add_child(tail)
	_add_cyl(tail, 0.02, 0.04, 0.34, Vector3(0, -0.14, 0.08), m1, Vector3(28, 0, 0))

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		for f_idx in range(2):
			var is_front = (f_idx == 0)
			var leg = Node3D.new()
			leg.name = ("LegF" if is_front else "LegB") + side_tag
			leg.position = Vector3(s * 0.30, 0.48, -0.32 if is_front else 0.36)
			root.add_child(leg)
			_add_cyl(leg, 0.14, 0.13, 0.48, Vector3(0, -0.24, 0), m1)

static func _build_biped_hopper(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_eye: Material) -> void:
	var body = _add_sphere(root, 0.26, 0.62, Vector3(0, 0.62, 0.04), m1, Vector3(0.92, 1.15, 1.05), "Torso")
	_add_sphere(body, 0.22, 0.48, Vector3(0, -0.04, -0.10), m2, Vector3(0.85, 1.0, 0.85), "Pouch")
	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 1.06, -0.18)
	root.add_child(head)
	_add_sphere(head, 0.15, 0.32, Vector3(0, 0, -0.06), m1, Vector3(0.9, 0.95, 1.35))
	for s in [-1.0, 1.0]:
		_add_box(head, Vector3(0.06, 0.22, 0.08), Vector3(s * 0.10, 0.18, 0.02), m1, Vector3(-12, 0, -s * 14.0), "Ear")
	_add_eyes(head, 0.09, 0.04, -0.14, 0.032, m_eye, m_dark)
	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		var arm = Node3D.new()
		arm.name = "LegF" + side_tag
		arm.position = Vector3(s * 0.20, 0.78, -0.14)
		root.add_child(arm)
		_add_cyl(arm, 0.045, 0.04, 0.28, Vector3(0, -0.12, -0.08), m1, Vector3(35, 0, 0))
		var leg = Node3D.new()
		leg.name = "LegB" + side_tag
		leg.position = Vector3(s * 0.18, 0.46, 0.10)
		root.add_child(leg)
		_add_cyl(leg, 0.08, 0.05, 0.38, Vector3(0, -0.18, 0), m1)
		_add_box(leg, Vector3(0.10, 0.06, 0.34), Vector3(0, -0.40, -0.10), m3)
	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.42, 0.24)
	root.add_child(tail)
	_add_cyl(tail, 0.03, 0.09, 0.68, Vector3(0, -0.16, 0.28), m1, Vector3(62, 0, 0))

static func _build_turtle(root: Node3D, key: String, m1: Material, m2: Material, m3: Material, m_dark: Material, m_eye: Material) -> void:
	var is_tortoise = ("Tortoise" in key)
	var shell_scl = Vector3(1.10, 0.98, 1.24) if is_tortoise else Vector3(1.14, 0.68, 1.30)
	var shell = _add_sphere(root, 0.42, 0.68, Vector3(0, 0.38 if is_tortoise else 0.34, 0.04), m1, shell_scl, "Shell")
	_add_box(shell, Vector3(0.76, 0.10, 0.88), Vector3(0, -0.22, 0), m2)
	for r in [-1.0, 0.0, 1.0]:
		for c in ([-1.0, 0.0, 1.0] if not is_tortoise else [0.0]):
			_add_box(shell, Vector3(0.11, 0.12, 0.18), Vector3(c * 0.18, 0.30, r * 0.24), m2 if is_tortoise else m1)
	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.32, -0.52)
	root.add_child(head)
	_add_sphere(head, 0.16, 0.32, Vector3.ZERO, m2, Vector3(1.0, 0.9, 1.25))
	_add_cyl(head, 0.01, 0.08, 0.18, Vector3(0, -0.02, -0.18), m3, Vector3(-95, 0, 0), "HookBeak")
	_add_eyes(head, 0.10, 0.04, -0.10, 0.032, m_eye, m_dark)
	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, 0.26, 0.56)
	root.add_child(tail)
	_add_cyl(tail, 0.018, 0.055, 0.32, Vector3(0, -0.04, 0.14), m2, Vector3(74, 0, 0))
	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		for f_idx in range(2):
			var is_front = (f_idx == 0)
			var leg = Node3D.new()
			leg.name = ("LegF" if is_front else "LegB") + side_tag
			leg.position = Vector3(s * 0.38, 0.24, -0.28 if is_front else 0.32)
			root.add_child(leg)
			_add_cyl(leg, 0.095, 0.085, 0.26, Vector3(0, -0.12, 0), m2)

static func _build_quadruped(root: Node3D, key: String, _info: Dictionary, m1: Material, m2: Material, m3: Material, m_dark: Material, m_white: Material, m_eye: Material) -> void:
	var is_bear = ("Bear" in key)
	var is_cheetah = ("Cheetah" in key)
	var is_hyena = ("Hyena" in key)
	var is_badger = ("HoneyBadger" in key or "Wolverine" in key)
	var body_y = 0.42 if is_badger else (0.62 if is_bear else 0.56)
	var body_scale = Vector3(1.16, 1.08, 1.36) if is_bear else (Vector3(0.76, 0.88, 1.48) if is_cheetah else (Vector3(1.12, 0.72, 1.38) if is_badger else Vector3(0.95, 0.90, 1.38)))
	var body = _add_sphere(root, 0.32, 0.76, Vector3(0, body_y, 0.04), m1, body_scale, "Torso")
	if is_hyena:
		body.rotation_degrees.x = 12.0
	_add_sphere(body, 0.28, 0.66, Vector3(0, -0.06, 0), m2, Vector3(0.88, 0.80, 1.28), "Belly")

	if "Lion" in key:
		_add_sphere(root, 0.38, 0.76, Vector3(0, 0.66, -0.32), m2, Vector3(1.12, 1.12, 0.82), "LionMane")
	elif is_bear:
		_add_sphere(body, 0.28, 0.54, Vector3(0, 0.20, -0.18), m1, Vector3(1.05, 0.95, 0.95), "ShoulderHump")
	elif is_badger:
		_add_box(body, Vector3(0.46, 0.12, 0.92), Vector3(0, 0.26, 0), m2, Vector3.ZERO, "DorsalCape")
	elif "Porcupine" in key:
		for q in range(14):
			var qx = (float(q % 3) - 1.0) * 0.14
			var qz = -0.14 + float(int(float(q) / 3.0)) * 0.13
			_add_cyl(body, 0.004, 0.022, 0.48, Vector3(qx, 0.28, qz), m2, Vector3(38, qx * 45.0, 0), "Quill")
	elif "Tiger" in key:
		for st in range(4):
			_add_box(body, Vector3(0.64, 0.44, 0.06), Vector3(0, 0.04, -0.24 + float(st) * 0.16), m2)
	elif is_cheetah or is_hyena:
		for sp_i in range(6):
			var sx = -0.26 if (sp_i % 2 == 0) else 0.26
			var sz = -0.20 + float(int(float(sp_i) / 2.0)) * 0.20
			_add_sphere(body, 0.055, 0.11, Vector3(sx, 0.06, sz), m2, Vector3(0.5, 1.0, 1.0), "CoatSpot")

	var head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, body_y + (0.12 if is_badger else 0.16), -0.46 if is_bear else -0.44)
	root.add_child(head)
	_add_sphere(head, 0.20, 0.40, Vector3.ZERO, m1, Vector3(1.0, 0.92, 1.15))
	var muz_len = 0.30 if ("Wolf" in key or is_bear or is_hyena) else 0.24
	_add_box(head, Vector3(0.18, 0.14, muz_len), Vector3(0, -0.04, -0.18), m2 if is_hyena else m1)
	_add_sphere(head, 0.045, 0.09, Vector3(0, 0.01, -0.18 - muz_len * 0.5), m_dark, Vector3.ONE, "Nose")
	for s in [-1.0, 1.0]:
		var ear_scl = Vector3(0.5, 1.45, 0.5) if "Wolf" in key else Vector3(0.7, 1.0, 0.5)
		_add_sphere(head, 0.07, 0.14, Vector3(s * 0.15, 0.16, 0.02), m1, ear_scl, "Ear")
	_add_eyes(head, 0.11, 0.05, -0.16, 0.036, m_eye, m_dark)
	for s in [-1.0, 1.0]:
		var fang_h = 0.22 if "Sabertooth" in key else 0.08
		_add_cyl(head, 0.024 if "Sabertooth" in key else 0.018, 0.004, fang_h, Vector3(s * 0.07, -0.10 if "Sabertooth" in key else -0.06, -0.24), m_white, Vector3(8, 0, 0), "UpperFang")

	var jaw = Node3D.new()
	jaw.name = "JawPivot"
	jaw.position = Vector3(0, -0.08, -0.08)
	head.add_child(jaw)
	_add_box(jaw, Vector3(0.16, 0.06, 0.24), Vector3(0, -0.02, -0.10), m2)

	var tail = Node3D.new()
	tail.name = "TailPivot"
	tail.position = Vector3(0, body_y + 0.02, 0.46)
	root.add_child(tail)
	if is_bear:
		_add_sphere(tail, 0.07, 0.14, Vector3(0, 0, 0.06), m1)
	else:
		var t_len = 0.58 if is_cheetah else 0.46
		_add_cyl(tail, 0.025, 0.055, t_len, Vector3(0, -0.06, t_len * 0.38), m1, Vector3(58, 0, 0))
		if "Lion" in key:
			_add_sphere(tail, 0.055, 0.12, Vector3(0, -0.16, 0.40), m2, Vector3.ONE, "TailTuft")

	for s_idx in range(2):
		var s = -1.0 if s_idx == 0 else 1.0
		var side_tag = "L" if s < 0 else "R"
		for f_idx in range(2):
			var is_front = (f_idx == 0)
			var leg = Node3D.new()
			leg.name = ("LegF" if is_front else "LegB") + side_tag
			leg.position = Vector3(s * (0.24 if is_bear else 0.20), body_y - 0.12, -0.26 if is_front else 0.28)
			root.add_child(leg)
			var leg_h = 0.28 if is_badger else (0.46 if is_bear else 0.42)
			var leg_r = 0.10 if is_bear else 0.075
			_add_cyl(leg, leg_r, leg_r * 0.78, leg_h, Vector3(0, -leg_h * 0.48, 0), m1)
			_add_box(leg, Vector3(0.13 if is_bear else 0.11, 0.06, 0.18 if is_bear else 0.16), Vector3(0, -leg_h * 0.95, -0.03), m2)
