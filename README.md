# Brainrot Base Tycoon

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Eizdy-ez/Brainrot-Base-Tycoon/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Eizdy-ez/Brainrot-Base-Tycoon/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Buy wild brainrots. Display them at your base. Get filthy rich.**

A 3D brainrot-collecting tycoon for Roblox, built for the make.fun bounty
[Make the best AI Roblox brainrot game](https://make.fun/bounty/roblox-brainrot-01).

**Play it here: https://www.roblox.com/games/130449382374278**

Nineteen original brainrot characters wander three sunny fields — a
toaster-headed toast tycoon, a lamp-headed daydreamer, a cookie robot, a
pumpkin owl, a pirate teapot, a satellite robot with a TV head, a waffle king
and more — in five rarities (Common, Rare, Epic, Legendary, Mythic) with
Shiny (×2) and Golden (×5) mutations. Buy them, stack them on your head,
display them at your base, and watch the cash roll in every second.

## How to play

1. **Buy** — wild brainrots wander the fields with a price tag. You start
   with $50, and the cheapest Commons cost $25–$50, so your first buy is
   always within reach. Bought brainrots stack on your head.
2. **Display** — step on a display pad at your base (up to 8) to place a
   brainrot. Every displayed brainrot earns cash per second into a pending
   pool. The HUD bar always shows 💰 your cash, ⚡ your income per second
   and 🏠 what is waiting to be collected.
3. **Collect** — step on the collect pad to bank the pending pool.
4. **Grow** — the buttons at the bottom of the screen run your empire:
   **UPGRADE** (four tracks — more Pads 4 → 6 → 8, Speed, Carry capacity
   and Luck), and zone unlocks for the **Candy Fields** ($5,000) and the
   **Golden Volcano** ($75,000), where far richer brainrots wander. Dash
   with Shift when you need to hurry home.
5. **Defend and steal** — **LOCK** seals your base for 45 seconds (90
   second cooldown, counted down right on the button). Rivals' unlocked
   bases can be stolen from — and yours can too. Every few minutes an
   event hits: **Gold Rain** (mutations everywhere) or a **Bandit** NPC
   who raids unlocked bases; tackle him to stop the theft.
6. **Quests and rebirth** — a chain of 10 quests pays out cash as you
   climb, and the plaza **Cash Kings** board tracks the richest tycoons.
   The **REBIRTH** button (behind a confirmation dialog) wipes everything
   back to a fresh $50 start when you want a clean run.

A step-by-step tutorial guides your first loop, and your progress saves
automatically.

## The cast (all original)

- **Common** — Toastino, Splashound, Moppina, Socktopus
- **Rare** — Lampadina, Biscotto Bot, Pumpkowl, Raviolibot
- **Epic** — Disco Fungo, Capitano Teapot, Astro Jelly, Vroom Broom, Satelerror
- **Legendary** — Drake Frutto, Volpina Neon, Tornadino
- **Mythic** — Waffleone, Balena Void, Gnocco d'Oro

Every character is modelled in code from plain Parts — object heads (a real
toaster, lamp, cookie disc, pumpkin, teapot and TV), big cartoon faces,
sleeved arms, trousers and shoes — with rarity sparkles and a floating
name / rarity / income billboard.

## What's inside

- **The full loop**: buy → carry → display → income per second → collect,
  with prices, income and the HUD reading from one shared state snapshot.
- **Three zones** with their own spawn pools and rarity weights, **eight
  player bases** with wide-spaced display pads, gates and barriers.
- **Live events**: Gold Rain and the base-raiding Bandit NPC.
- **Music & sound**: a cheerful public-domain APM soundtrack that follows
  the action, plus a full set of sound effects (buy, place, collect,
  upgrade, lock, fanfare) — every audio id verified against the Roblox
  asset API — with a mute toggle.
- **Persistence**: DataStore saves with pcall guards, retries and a
  session fallback; autosave plus save-on-leave.
- **Client juice**: floating +$/−$ cash deltas, collect bursts, camera
  shake, dash FOV kick, event banners and toasts.

## Tech

- All place content is authored as files: Luau sources in `src/`
  (`server/`, `client/`, `shared/`), assembled into `game.rbxl` with
  [Rojo](https://rojo.space) from `default.project.json`. The world itself
  is built procedurally by the server scripts at runtime.
- `main.ts` (Node, standard library only) packages the entry for make.fun.
- No external assets besides the verified Roblox audio ids above.
- `TOUR.json` walks a reviewer from the plaza into the fields and back to
  the base row, one step per screenshot.

## License

MIT — see `LICENSE`.
