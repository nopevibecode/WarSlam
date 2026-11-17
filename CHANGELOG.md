# Changelog

## Unreleased

- **Base profiles re-tuned for slow weapons** on simulated damage with
  Overpower, Bloodrage and pairs: Base 3.60 and Base 3.80 now queue Heroic
  Strike at 94 rage instead of 72 and use a 0.60 Slam window (+4% to +5% on
  average, up to +7% at high rage). Base 3.40 is back to the Auto window
  (same as Base 3.50), and both fast profiles let a pair be at most 10 rage
  short instead of 20 (+0.4%). Applied once to your existing base profiles.
- **Defaults button** now also applies the simulated values for your weapon's
  speed (when it has a base profile) and resets that base profile if it's
  active. Before, it went back to generic values (Slam window 0.60, Heroic
  Strike at 71, pairs with no leeway).
- **Sunder Armor on by default when Nampower is in use** (bosses: full rules,
  other mobs: opportunity Sunders only), for new installs and the Defaults
  button, which no longer switches off the Sunder build. Without Nampower it
  stays off by default.
- **Overpower instead of a Slam only when it's worth it:** alone, it only
  takes a slot that costs the next Slam if the stance swap loses 10 rage or
  less (`OP_BLOCKED_LOSS`, capped by the rage-loss slider);
  otherwise it waits for a pair with Bloodthirst or Whirlwind (two strikes
  for the Slam).
- **Sunder refresh in rotation holes:** a GCD slot nothing else can use (both
  Bloodthirst and Whirlwind on cooldown, typically the swing after a pair)
  now refreshes a full Sunder stack early, when it has 15s or less left
  (`SUNDER_HOLE`), so the refresh doesn't take another strike's slot later.
  On trash, a hole with rage at the Heroic Strike threshold or more adds a
  Sunder stack instead of wasting the GCD (seen at 100 rage on Flamewaker
  Elites).
- **Longer log:** 20,000 lines instead of 5,000, so a full raid fits.
- **No pair once this swing's Slam is lost:** if the swing had no Slam and
  its Slam window has closed, a Bloodthirst + Whirlwind pair would also cost
  the next Slam (two strikes for two swings) and leave a hole. The first
  strike now goes alone, and the second stays ready for a real pair.
- **Rend before leaving Battle Stance** ("...and Rend", Overpower section,
  on by default): after Overpower, when swapping back would lose 5 rage or
  more, Rend spends 10 of it, if its GCD costs no Slam and your last Rend is
  (nearly) over, and never on bleed-immune targets: with Deep Wounds, a
  target showing no Deep Wounds after 2 of your crits (or a "Rend failed ...
  immune" line) is remembered as immune. The settings window is a little
  taller to fit it.

## 1.1 — 2026-11-13

### Overpower and stance dancing
- **Overpower** is now part of the rotation. Berserker Stance stays home, and
  WarSlam only visits Battle Stance to use Overpower when your target dodges.
- **Rage-loss slider** (default 0) caps how much rage a stance swap may throw
  away. Tactical Mastery is read from your talents.
- **"...even if it costs the next Slam"** (on by default) lets Overpower take
  any GCD slot, including one that costs the next Slam.
- **Pairs:** Overpower can pair with Bloodthirst or Whirlwind, ahead of Slam.
- **Stay in Battle to dump rage** (on by default, 3s at most): before swapping
  back, WarSlam spends rage on Bloodthirst or a Heroic Strike instead of
  losing it to the swap.
- **Right target only:** an Overpower window only opens when your current
  target dodged. Nampower compares the mob's ID, so a dodge from another mob
  with the same name doesn't count.
- **4s window:** WarSlam stops retrying an Overpower the server refuses, and
  never swaps back while an Overpower is still on its way.
- **Your own Battle Stance is left alone.** WarSlam only swaps back from
  Battle Stance visits it started itself.
- **Opening:** after a Charge, WarSlam moves you to Berserker as soon as the
  swap loses no rage.

### Bloodrage
- **Bloodrage for pairs** (Rotation tab, Cooldowns), with three modes:
  - Off.
  - **With Death Wish** (default): only after you used Death Wish.
  - **Always.**

  It fires Bloodrage when a pair is short of 10 rage or less, after any
  stance swap the pair needs.
- **Kept for Death Wish:** Bloodrage is always ready again within 15s of
  Death Wish coming back.
- **Second half of Death Wish:** Bloodrage is held for the first 15s of Death
  Wish. From then on it goes out as soon as its rage fits under the cap, so
  its Enrage overlaps Death Wish (`BLOODRAGE_DW_AFTER`, 0 turns this off).
- Never below 30% health.

### Rotation fixes
- **Battle Shout** takes the next GCD slot when it's due, even if another
  ability wanted that slot.
- **No Slam while the auto attack is overdue,** so a Slam can no longer stall
  a swing.
- **Swing stall rule** waits 1.0s, so a late auto after Flurry drops isn't
  mistaken for a stall.
- **No targeting on its own:** WarSlam doesn't queue anything through
  Nampower for 0.4s after you change target, so a press right after a target
  swap can't hit your previous target.
- **Talents** are re-read at every combat start.
- **Load error fixed** ("attempt to call global WarSlamST"): the 1.12 client
  limits how many outside variables one function may use.

## 1.0 — 2026-11-11

First public version.

- **One-button Slam rotation** for OctoWoW warriors: `/run WarSlamST()` for
  single target, `/run WarSlamMT()` for multiple targets.
- **Bloodthirst + Whirlwind pairs** between autos for fast weapons.
- **Heroic Strike dump**, with its cost read from Improved Heroic Strike.
- **Sunder Armor:** full rules on bosses, opportunity Sunders on trash.
- **Battle Shout upkeep.**
- **Death Wish on demand** with `/run WarSlamDW()`, plus an optional Juju
  Flurry 9s later (delay slider).
- **Settings window** with Rotation, Advanced and Profiles & Tools tabs, plus
  per-weapon profiles.
- **Requires** the SP_SwingTimer fork for OctoWoW. Nampower is recommended.
