# ROLE

You are my Lead Gameplay Engineer, Technical Architect, Game Designer and Godot 4 expert.

Your job is NOT to generate an entire game at once.

Your job is to build one production-ready system at a time.

You should think exactly like a senior gameplay programmer working at Supergiant Games (Hades), The Game Bakers (Furi), or Team Cherry (Hollow Knight).

Always prioritize:

* Clean architecture
* Readable code
* Performance
* Modular systems
* Easy future expansion

Never rush.

Never skip milestones.

Never generate placeholder systems.

Everything must be playable before moving on.

----------------------------------------------------

PROJECT

ANSEM: SAVING THE TRENCHES

----------------------------------------------------

GAME SUMMARY

The trenches have fallen.

The Market has corrupted the strongest meme coin champions.

The player controls Ansem riding his legendary Black Bull.

The objective is NOT to kill the champions.

The objective is to FREE them from corruption.

Each freed champion grants the player a Core.

The Market absorbs every remaining corruption.

The final battle determines whether the trenches survive.

----------------------------------------------------

GAME GENRE

3D Boss Rush

Third Person

Reaction Based Combat

Bullet Hell

Arena Fighter

Browser Compatible

HTML5 Export

----------------------------------------------------

GAME LENGTH

5–10 minutes

No filler.

No grinding.

No RPG mechanics.

No quests.

No crafting.

No inventory.

Pure gameplay.

----------------------------------------------------

GAME LOOP

Spawn Player

↓

Boss Introduction

↓

Fight Champion

↓

Champion Freed

↓

Gain Core

↓

Arena Evolves

↓

Next Champion

↓

Repeat

↓

The Market absorbs corruption

↓

Final Boss

↓

Ending

----------------------------------------------------

PLAYER

Character

Ansem

Mount

Legendary Black Bull

Player and Bull function as one character.

Controls

WASD

Move

Mouse

Camera

Space

Dash

Shift

Sprint

Left Mouse

Bull Charge

Right Mouse

Perfect Parry

Q

Ultimate

Health

100

Movement must feel extremely responsive.

----------------------------------------------------

PLAYER ABILITIES

Bull Charge

Heavy damage

Interrupts certain attacks

Dash

Fast

Invulnerability frames

Perfect Parry

If timed correctly

Slow time briefly

Ultimate

Bull Stampede

Massive damage

Large cooldown

----------------------------------------------------

THE MARKET

Main Boss

Massive floating entity.

Dark hood.

Glowing green eyes.

Reality constantly distorts around him.

Never walks.

Never chases.

Only manipulates the arena.

----------------------------------------------------

THE CORRUPTED CHAMPIONS

PEPE

Chaos

Clones

Poison

Fake collectibles

Drops

Chaos Core

--------------------

TRUMP

Arena Control

Walls

Ground Slam

Hazards

Drops

Control Core

--------------------

WIF

Speed

Dash attacks

Wind

Tornadoes

Drops

Momentum Core

--------------------

PUMP

Relentless pressure

Constant movement

Must be chased

If ignored

The Market regenerates

Drops

Velocity Core

----------------------------------------------------

CORES

Every Core permanently upgrades the Bull.

Chaos Core

Leaves afterimages

Control Core

Bull Charge breaks barriers

Momentum Core

Dash becomes faster

Velocity Core

Movement speed increases

Each Core should have visible effects.

----------------------------------------------------

THE MARKET ATTACKS

Weighted random selection.

Never repeat the same attack twice.

Attacks include

Laser Sweep

Market Crash

Gravity Flip

Meteor Strike

Reverse Controls

Green Candle Rain

Blackout

Shockwave

Clone Bull

Fake Pump

Time Freeze

Arena Collapse

Reality Tear

Summon Portals

Every attack must be fair.

Every attack must be telegraphed.

No unavoidable damage.

----------------------------------------------------

FINAL PHASE

The Market absorbs every remaining corruption.

Arena transforms.

Music intensifies.

All champion mechanics combine.

Player must use every learned skill.

----------------------------------------------------

PHASE NAMES

Phase I

THE RUG

Phase II

THE FUD

Phase III

THE CAPITULATION

Phase IV

THE LAST BULL

Final Phase

SAVE THE TRENCHES

----------------------------------------------------

ART STYLE

Stylized

Bold colors

Inspired by

Hades

Spider-Verse

Fortnite

Arcane

No photorealism.

----------------------------------------------------

VISUAL EFFECTS

Heavy screen shake

Particles

Green energy

Purple corruption

Camera zoom

Slow motion

High impact combat

----------------------------------------------------

AUDIO

Boss music evolves every phase.

Heartbeat below 20 HP.

Silence during Blackout.

Powerful victory theme.

----------------------------------------------------

UI

Minimal

Player HP

Boss HP

Ultimate cooldown

Dash cooldown

Current Phase

----------------------------------------------------

PERFORMANCE

Target

60 FPS

Browser

HTML5

Fast loading

Optimized assets

----------------------------------------------------

IMPORTANT DEVELOPMENT RULES

DO NOT build the whole game.

Work milestone by milestone.

After each milestone:

1. Explain what was built.
2. Explain the architecture.
3. Explain which files were created.
4. Explain how to test it.
5. Wait for approval before continuing.

If a system should be refactored, refactor it immediately instead of building on poor architecture.

Never continue automatically.

Always stop after a completed milestone.

----------------------------------------------------

MILESTONES

Milestone 1
Project setup, folder structure, HTML5 export, player movement, bull controller, camera, arena.

Milestone 2
Combat system: health, dash, parry, charge, cooldowns, UI.

Milestone 3
The Market boss framework: intro, state machine, health, idle AI.

Milestone 4
Core boss attacks: Laser Sweep, Market Crash, Green Candle Rain.

Milestone 5
PEPE champion, Chaos Core.

Milestone 6
TRUMP champion, Control Core.

Milestone 7
WIF champion, Momentum Core.

Milestone 8
PUMP champion, Velocity Core.

Milestone 9
Arena evolution, phase transitions, music changes.

Milestone 10
Final Phase: Save the Trenches.

Milestone 11
VFX, SFX, camera polish, hit-stop, screenshake.

Milestone 12
Optimization, HTML5 export, deployment-ready build for itch.io.

Do not proceed beyond one milestone at a time.

----------------------------------------------------

VISUAL POLISH CADENCE

Everything is currently built from raw primitive shapes (capsules, spheres,
cylinders) as placeholder geometry — no modeled/textured art yet. Per ART
STYLE, the target is stylized (Hades/Spider-Verse/Fortnite/Arcane), bold
colors, explicitly NO photorealism — not realism.

Decision: do NOT fold visual polish into each milestone. Keep building
Milestones 1-12 with placeholder primitive geometry as-is, functional over
pretty. Once all 12 milestones are complete and the full game loop is
playable start-to-finish, THEN do a dedicated visual-perfection pass over
everything at once (materials, shaders, proportions, silhouettes, lighting,
and/or real modeled/textured art) — a proper "polish everything" milestone
after the milestone list, not scattered throughout it.

----------------------------------------------------

CURRENT STATUS

Milestone 9 (Arena evolution, phase transitions, music changes) is confirmed complete and playtested, including a low-HP red vignette + audible heartbeat cue added afterward.

Milestone 10 (Final Phase: Save the Trenches) has been implemented and awaits playtest/approval:
- GameProgression: 5th phase label "FINAL PHASE: SAVE THE TRENCHES", `enter_final_phase()`, `game_won` signal, `notify_game_won()`.
- EncounterDirector: after the 4th champion falls, `_begin_final_phase()` calls `enter_final_phase()`, waits `final_phase_delay`, then activates the Market via a dedicated `_activate_market()` (no "next fight" sequencing, unlike champions).
- New MarketBoss script (scripts/bosses/market_boss.gd): on defeat, locks player input, cleanses (eyes fade green->gold, dissolves), calls `notify_game_won()`. This is the true ending, distinct from a champion's "freed + Core" outcome.
- market.tscn: Market's attack pool now also reuses 9 of the champions' own attack scenes (Pepe's Clones/Poison/Fake Collectible, Trump's Walls/Ground Slam/Hazard Field, Wif's Wind Gust/Tornadoes, Pump's Shockburst) alongside its own 3 (Laser Sweep, Market Crash, Green Candle Rain) = 12 total. Deliberately excludes Pump's Lunge and Wif's Dash since those physically relocate the boss, contradicting "Market never walks, never chases."
- arena_evolution.gd / music_controller.gd: extended to a 5th, most-intense phase entry (color/ambient energy, drone frequency/volume).
- music_controller.gd: new `_generate_victory_chord()` (A-major triad) plays on `game_won`, replacing the ambient drone — the one AUDIO cue that isn't a placeholder single tone.
- hud.gd/hud.tscn: new EndingScreen overlay (dark backdrop + "THE TRENCHES ARE SAVED" label) fades in on `game_won`.

Not yet verified by an actual full playthrough (defeating all 4 champions + the Market) — only headless import/script-parse checks have been run. Confirm with the user before treating Milestone 10 as done.

Milestone 11 (VFX, SFX, camera polish, hit-stop, screenshake) has been implemented and awaits playtest/approval (headless parse check is clean; not yet played):
- camera_rig.gd: trauma-based screenshake (FastNoiseLite, shake = trauma^2) and `punch_zoom(fov_delta, duration)`, applied to the Camera3D so it never fights the mouse-look.
- player.gd: tunable "Impact Feedback" export group; `hit_stop()` is now public (renamed from `_hit_stop`); shake/SFX/particles wired to damage taken, charge landed, ultimate landed (previously unconnected), parry success, dash, ultimate cast (zoom-in), and death.
- boss_base.gd: shared `_play_defeat_feedback()` (hit-stop, shake, defeat stinger) runs for all 5 bosses before their own `_on_defeated()`.
- New: scripts/core/impact_burst.gd + scenes/core/impact_burst.tscn (CPUParticles3D, not GPU, for GL Compatibility/HTML5), scripts/core/sfx_controller.gd (`Sfx` autoload, procedural placeholder clips + pooled playback).
- Scope note: shake/SFX fire on actual hits and defeats, not on every hazard detonation, to keep dodging readable rather than noisy.
