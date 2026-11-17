# whip_misc

Small world fixes for whip, picked from xrp_misc and reworked.

## Blacklisted cars and peds

`Config.Blacklist`, checked on the server with OneSync's `entityCreating`: a listed model is refused before it
exists, on every game, so there is nothing to look for and delete. One lookup per entity.

Two lists for each of vehicles and peds:

- **ambient**: refused only when GTA made it itself (traffic, parked cars, scenario and street peds). A script, a
  garage or an admin can still spawn one: a player's own Mule comes out of the garage, `/car police` still works.
- **always**: refused from anyone, scripts included. For what must never be on the server (Oppressors, Hydras...).

Names or hashes both work. `Config.ReportMinutes` prints what was refused to the console every so often.

Changes from xrp_misc:
- **ambient vs always.** xrp refused a model whoever spawned it, so a blacklisted Mule couldn't be bought, stored
  or spawned by an admin either.
- **More cop models.** Rangers, snow cops, SWAT and marines are added, and the police cars and police helicopter
  are blacklisted too, so no empty ones are left parked about.
- **No false entries.** xrp's list carried `= false` entries (`FIRETRUK`, `paragon`) that did nothing. They are gone.

## A quieter world

Set on each player's game at start and after each spawn or revive (xrp re-ran scenarios every 10 s; once is enough):

- `Config.World`: random cops, garbage trucks, random boats and trains, distant sirens, police scanner chatter,
  flight music, random events
- `Config.Scenarios`: police by their cars, police bikes, ambulances, military planes, street races. Groups by name
  (xrp passed raw numbers, which `SetScenarioGroupEnabled` does not take).
- `Config.ClearAreas`: stations, hospitals, Fort Zancudo... Parked-car spawners there are switched **off**, not just
  emptied once, so they stay empty. Scenario peds are blocked there too (`peds = false` to keep them). One entry per
  area: a label, a point and a radius. xrp's Fort Zancudo box had a sign typo (`-3075.99`) and covered the wrong place.

Wanted level and AI dispatch (police, fire and ambulance responding) are already whip_core's: it turns them off at
every spawn, so they are not here.

## Crouch

**Ctrl** crouches and stands (`Config.Crouch`). Players can rebind it: Settings > Key Bindings > FiveM > Crouch.
`mode = 'hold'` makes it hold-to-crouch instead.

Changes from xrp_misc:
- The crouched walk goes through whip's walk override, so standing up gives back the player's own walk style
  (an emote walk, whip_ems' limp). xrp kept a copy of the walk style and put it back by hand.
- A rebindable key mapping, not a hard-coded key check every 7 ms. Nothing polls while standing except the one
  native that keeps GTA's own stealth walk (also Ctrl) off, and nothing at all in a vehicle.
- They stand up by themselves when they get in a car, fall, swim, climb, ragdoll or go down.
- No crouch over a whip screen or a placing mode (whip's placer uses Ctrl).
- Sprint and jump stay off while crouched (each a setting). xrp only did this when armed.
- Optional crouched speed.
- xrp's prone is not carried over. Neither is its every-100-ms action-mode loop: whip_core already keeps GTA's
  crouched combat walk off.

`exports.whip_misc:IsCrouched()` and `exports.whip_misc:SetCrouched(true|false)` on the client.

## Enter any seat

**F** at a door gets you into that door's seat: a back door, the back seat. GTA otherwise walks you round to the
driver's seat (`Config.EnterAnySeat`).

Built on top of whip_core's own fix (F at the front passenger door of an empty car sits you there with no slide),
and the same way: GTA's get-in starts as usual, and the moment it does it is told again, to the seat of the door you
are at, with no sliding across. That seat must be free; the driver's door, an occupied seat, bikes, boats, aircraft
and trains are left to GTA. F again, or pushing away from the car, stops the walk.

Changes from xrp_misc:
- **Doors are read from the car.** xrp looped over every "door", hood and boot included, so the boot could send you
  to seat 4. Here only the four seat doors count, and only the ones the car really has.
- **Never blocks GTA.** xrp waited 100 ms on every F press before anything happened, and could leave F switched off
  if it returned early (a bike, a boat). Here GTA's get-in is never held up: it is only redirected.
- **A seat must be free**, and a far-off door doesn't count (`maxDoorDistance`).
- **Cheap.** One native every 100 ms on foot, nothing more unless a get-in starts.

## Dice

`/roll [dice] [sides]` (default one six-sided die): the server rolls, and the result floats above the roller's head
in **whip's own /me capsule** for everyone within `Config.Dice.range`, e.g. *"rolls 2d6: 4, 3 (total 7)"*.

Changes from xrp_misc:
- **Rolled on the server, shown in whip's 3D capsule.** xrp drew its own 2D text every 7 ms on every client in
  range, for each roll, plus a garbage-collect loop.
- **Rate-limited** (`cooldownMs`), and limits on dice and sides with a usage message.
- The throw is upper-body only, so the roller can keep walking.

## Setup

`ensure whip_misc` after whip_core. If xrp_misc stays, remove its `entityfilter.lua`, `dispatchservices.lua`,
`vehGenerators.lua`, `blacklistScenario.lua`, `crouchprone.lua`, `enteranyseat.lua` and `diceroll.lua` (client and server) from its manifest.

## For other resources

```lua
exports.whip_misc:IsBlacklisted('rhino')   -- 'ambient', 'always' or nil (server)
```
