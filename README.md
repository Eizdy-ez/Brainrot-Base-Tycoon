# Brainrot Base Tycoon

**Catch wild brainrots. Display them at your base. Get filthy rich.**

A full tycoon for Roblox, built for the make.fun bounty
[Make the best AI Roblox brainrot game](https://make.fun/bounties/roblox-brainrot-01).
Play it here: https://www.roblox.com/games/130449382374278

Wild Italian-brainrot characters — Tung Tung Tung Sahur, Cappuccino Assassino,
Bombardiro Crocodilo, Lirili Larila and eleven more — wander three spawn
fields in five rarities (Common, Rare, Epic, Legendary, Mythic) with Shiny
(×2) and Golden (×5) mutations. Touch one to carry it home (they stack on
your head), place it on a display pedestal, and it prints cash every second.
Collect, upgrade, fuse, unlock richer zones, survive the events, rebirth,
and top the Cash Kings leaderboard.

## How to play

1. **Catch** — run into a wild brainrot in the fields to pick it up.
2. **Place** — step on a glowing pad at your base to display it.
3. **Collect** — income piles up; step on the green pad to bank it.
4. **Grow** — buy more pads, speed, carry capacity and luck; fuse 3 identical
   brainrots into the next rarity; unlock the Neon Lagoon ($5,000) and the
   Golden Volcano ($75,000) for far richer spawns.
5. **Watch out** — every few minutes something happens: **Gold Rain** (mutations
   everywhere), the **Brainrot Wave** (a wall of water that knocks your carry
   loose — hide in your base!), or a **Bandit** who steals from unlocked bases.
   Lock your base, steal from careless rivals, tackle the bandit.
6. **Rebirth** — reset for a permanent +50% income multiplier and a golden aura,
   and climb the quest chain (10 quests) and the in-game leaderboard.

Shift (or the DASH button) gives you a speed burst. A step-by-step tutorial
arrow guides your first loop.

## What's inside

- **15 hand-modelled blocky brainrots** built from primitives in code, each
  with accessories (saxophone, espresso cup, propeller, cactus body, shark
  fins…), rarity colours, sparkles and name/rarity/income billboards.
- **Full progression**: 4 upgrade tracks, 3 zones with their own spawn pools,
  fusion, rebirth with aura, 10 chained quests, persistent DataStore saves
  (with session fallback), per-player bases for 8 players.
- **Live events**: Gold Rain, the Brainrot Wave, and a base-raiding Bandit NPC.
- **Music & sound**: a cheerful public-domain APM soundtrack that follows the
  action (calm fields, rave during events) plus a full set of verified sound
  effects — pickup, place, collect, buy, error, wave alarm, rebirth fanfare —
  with a mute toggle. Every audio id was verified against the Roblox asset API.
- **Client juice**: camera shake, collect bursts, dash FOV kick, toasts,
  event banners, per-player gate barriers.

## Tech

- All place content is authored as files: Luau sources in `src/`
  (`server/`, `client/`, `shared/`), assembled into `game.rbxl` with
  [Rojo](https://rojo.space) from `default.project.json`. The world itself is
  built procedurally by the server scripts at runtime.
- `main.ts` (Node, standard library only) packages the entry for make.fun.
- No external assets besides the verified Roblox audio ids above.
- `TOUR.json` walks a reviewer from the plaza into the fields and back to
  the base row, one step per screenshot.

## License

MIT — see `LICENSE`.
