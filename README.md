# WarSlam

One-button Slam rotation for warriors on the **OctoWoW** private server
(vanilla 1.12 client).

It's built and tested on OctoWoW, where Slam's cast time scales with your
haste and Slam can be cast while moving. On other 1.12 servers with
different Slam rules, the timings won't be right.

> **Tested with Fury.** WarSlam supports Arms (Mortal Strike instead of
> Bloodthirst, Improved Slam read from your talents), and the fundamentals
> are the same. But all the testing and fine tuning was done with a Fury
> spec, so results with Arms, especially with Improved Slam's shorter cast,
> aren't guaranteed.

You press one key and WarSlam picks the right ability at that moment: Slam,
a GCD ability (Bloodthirst / Mortal Strike / Whirlwind, optionally Sunder
Armor), and Heroic Strike or Cleave when you have rage to spare. It reads
your swing timer, so it handles Windfury resets and Flurry haste without you
having to react to them.

WarSlam only acts when you press the button. It never casts anything on its
own.

It isn't meant to play for you. It makes the split-second calls a human
can't react to in time, like where the Slam goes after a random Windfury or
Hand of Justice reset. The rest is still up to you:

- **Replace your Slam button with the WarSlam macro.** Keep your other
  abilities on their own keys: on short fights you may want to fire them
  yourself.
- **Execute isn't handled.** When the target is under 20%, switch to
  Execute yourself.


## Requirements

- The OctoWoW client (vanilla 1.12, English spell names).
- The **SP_SwingTimer** addon, in its version adapted to OctoWoW:
  https://github.com/nopevibecode/SP_SwingTimer
  (it can be installed from the launcher with that link too). WarSlam reads
  its `st_timer` value, the time left before your next swing, on every
  press. Without it, WarSlam does nothing.
- Optional: the **Nampower** client mod, for spell queuing (see below).


## Installation

**With the game launcher:** add the addon from its git link,
`https://github.com/nopevibecode/warslam`. The launcher's update button picks
up new versions. Then go to step 2.

**By hand:**

1. Download the files (green **Code** button, **Download ZIP**), and put them
   in a folder named exactly `WarSlam` (not `warslam-main`) in
   `Interface\AddOns\`, so you have:
   ```
   Interface\AddOns\WarSlam\WarSlam.toc
   Interface\AddOns\WarSlam\WarSlam.lua
   Interface\AddOns\WarSlam\WarSlamUI.lua
   ```
2. Restart the game (or log in). On the character screen, open **AddOns**
   and make sure **WarSlam** is ticked. Tick *Load out of date AddOns* if
   needed.
3. Create the macros below and put them on your bars.


## Macros

| Macro | Use it for |
|---|---|
| `/run WarSlamST()` | Single target |
| `/run WarSlamMT()` | Multiple targets |
| `/run WarSlamDW()` | Arm Death Wish for the next GCD (press again to cancel), see *Death Wish* |

Start auto attack first. Then press the macro as often as you can, or bind it
to your mouse wheel: the faster you press, the tighter the rotation.


## What it does

Each press, in this order:

1. **Heroic Strike / Cleave** (off the GCD): queued once per swing when your
   rage is high enough. Heroic Strike defaults to 71 rage (single target) and
   Cleave to 50 (multi target). While one is queued, its rage is set aside so
   the other abilities never spend it.
2. **Slam**: once per swing, as long as enough of the swing is left (60% by
   default). An early Slam, started right after the auto, doesn't delay the
   next auto.
3. **GCD ability**: only if its 1.5s global cooldown will be over in time
   for the next swing's Slam. In practice:
   - after an **early** Slam, a GCD ability goes out;
   - after a **late** Slam, or a Windfury reset, it waits so the next Slam
     isn't lost.

GCD priority:

| | Single target (`WarSlamST`) | Multi target (`WarSlamMT`) |
|---|---|---|
| 1 | Battle Shout if missing or 10s or less left | Battle Shout if missing or 10s or less left |
| 2 | Sunder Armor while under 5 stacks *(optional, off by default)* | Whirlwind |
| 3 | Bloodthirst / Mortal Strike | Bloodthirst / Mortal Strike |
| 4 | Whirlwind | |
| Rage dump | Heroic Strike | Cleave |

Battle Shout, once due, takes the **next GCD slot even if it costs a Slam**,
ahead of strike pairs and trades: with a fast weapon most slots after a Slam
are blocked, and waiting for a free one could let the buff drop. That's at
most one Slam every 2 minutes.

**Fury or Arms** is detected automatically: Bloodthirst if you have it,
Mortal Strike otherwise. There's nothing to change after a respec.

Timing is relative to your **current** swing speed, so Flurry and other haste
are handled. Only the 1.5s GCD is in fixed seconds.


## Nampower (optional)

If [Nampower](https://github.com/pepopo978/nampower) is installed, WarSlam
uses its spell queuing. In the last moments of a Slam cast or the GCD,
WarSlam works out what the swing will look like when it ends, and sends the
right spell early. Nampower holds it and fires it on the first possible
frame, so the next Slam or GCD ability no longer waits for your next key
press.

- Every press re-decides. If Windfury resets your swing after Bloodthirst was
  queued, the next press queues Slam over it.
- WarSlam only queues within the last 0.30s (*queue lead*), and never more
  than Nampower's own queue window.
- Without Nampower, or with *Use Nampower queuing* off, WarSlam works
  exactly as it does without it.

The settings window has a **Nampower** section that changes Nampower's own
settings directly. The **Recommended** button sets:

| Nampower setting | Value |
|---|---|
| Queue cast-time spells | on |
| Queue instant spells | on |
| Queue spells coming off cooldown | on |
| Queue on-swing spells | **off** (WarSlam handles Heroic Strike / Cleave itself) |
| Queue window | 300 ms |

These are Nampower settings: the game saves them, and they apply to all your
spells, not only WarSlam's.


## Fast swings: trading a Slam

With a slow swing, an early Slam leaves time for a GCD ability before the
next Slam: *auto, Slam, GCD, auto, Slam*. Haste shrinks the swing but not the
1.5s GCD, so once your **hasted** swing drops below about 2.3s, that no
longer fits. For a 2H weapon (2.9 to 3.8), that means a 2.9–3.0 weapon with
Flurry, or a 3.3–3.6 weapon with Flurry plus another ~20% haste. Every GCD
would then cost a Slam.

WarSlam then **trades** one Slam for two strikes when it pays off:

*auto, Slam + Bloodthirst, auto, Whirlwind (+ another GCD if it fits), auto, Slam...*

It only trades when a second strike (Bloodthirst / Mortal Strike /
Whirlwind) will be ready to fill the swing without a Slam, its GCD is also
over in time for the following Slam, and you have the rage for both. So
every trade gains a strike. When even that doesn't work out, WarSlam keeps
Slamming every swing.

In simulated 60s fights (no rage limit) the trade gained 4 to 6 strikes per
minute at swings of about 1.9–2.35s, and changed nothing at slower swings
(see *In depth*, §4).

**Both strikes up: fire both.** With a fast weapon, when Bloodthirst /
Mortal Strike **and** Whirlwind are both ready and you have the rage for both,
WarSlam fires both rather than waiting to Slam:

*auto, Slam, Bloodthirst, auto, Whirlwind (instead of the Slam), auto, Slam...*

Slam has no cooldown, so delaying one costs nothing. Delaying Bloodthirst or
Whirlwind wastes their cooldowns. Battle Shout and Sunder keep their
priority. **Pair now:** right after an auto, with both strikes up and the
rage for both, WarSlam fires them back to back instead of this swing's Slam
when they're done before the next Slam window closes (with Flurry at 2.61s:
done at 3.00s, window closes at 3.39s). That's auto, BT, WW, auto, Slam:
same cost as a pair, but a swing earlier. Otherwise, the usual pair waits for
the slot after a Slam (a 5-stack Sunder refresh only when it can go in that
very slot;
otherwise the urgent rule refreshes it at 4s). A pair starts either in the
first GCD slot after this swing's Slam, or when its first strike fits as a
normal GCD, ending before the next Slam window closes. Either way only the
second strike costs a Slam. When the first strike would cost a Slam too
(after a Sunder or Battle Shout late in the swing), BT would be the 2nd GCD
and WW the 3rd, which with Flurry costs two Slams, so WarSlam waits for the
next Slam. In the settings window, **BT + WW pair: rage leeway** (0–40)
allows the pair to start that much rage short of both costs, counting on the
auto in between. WarSlam measures how much rage your autos really bring and
never counts on more than a cautious figure (the average minus half its
usual spread, since a dodged or glancing auto brings less), nor on any rage at all when a Heroic Strike
is queued (HS replaces the auto, which then brings no rage). While a pair
waits for its second strike, Heroic Strike is held back unless the rage
covers both. If the second strike is short of rage before the auto has
landed, WarSlam waits for the auto; if it is still short after it, it goes
back to Slam. **Fast weapon: fire BT + WW together** turns it off. Both are
saved in profiles.

A queued Heroic Strike makes the auto bring no rage, which used to cost
pairs. So when BT/MS and Whirlwind are both off cooldown within 3 seconds,
Heroic Strike needs more rage: **Heroic Strike when a pair is near** (60–100,
default 90) replaces the usual 72 for that moment. The rest of the time the
usual threshold applies. Set it to 72 or lower to turn this off. Saved in
profiles.

The **Slow weapon rotation** select box in the settings decides whether
trading and pairing are allowed:

| Choice | Rotation |
|---|---|
| **Auto** (default) | From your equipped main hand's **base** speed: 3.6 or slower = slow weapon (no trade), faster = fast weapon (trade allowed). |
| **Yes** | Slow weapon: Slam + GCD, never trade. |
| **No** | Fast weapon: trade a Slam when it gains a strike, and fire Bloodthirst + Whirlwind together when both are up. |

The window shows the speed WarSlam read from your weapon and which rotation
is in use. Change the 3.6 limit with `/run WarSlamConfig.SLOW_SPEED=3.5`.


## PvP

In a **battleground**, or when your **target is an enemy player**, WarSlam
only does the basics: Slam, Bloodthirst / Mortal Strike, Whirlwind and the
Heroic Strike / Cleave dump. No Battle Shout, no Sunder, no opener. You can
turn this off with **PvP: only Slam + BT / MS / WW** in the settings.

**Stalled swing.** When your target is out of reach (kiting, running,
behind you), the swing timer sits at 0 and no auto lands. There's no Slam
window to protect then, so after 1.0s (`STALL`) WarSlam stops holding GCD
abilities back and uses Bloodthirst / Mortal Strike / Whirlwind right away.
As soon as autos land again, the normal rotation resumes. This works in PvE
too, e.g. when a boss moves out of reach.


## Profiles

Your best settings depend on your weapon and haste, so you can save them as
**profiles** and **link a profile to a weapon**. When you equip a linked
weapon, its profile loads by itself.

In the settings window (right column):

1. Set things up the way you want, type a name under **Save current settings
   as**, and click **Save**. Saving under an existing name updates it.
2. With that weapon equipped, pick the profile in **Saved profiles** and click
   **Link to this weapon**.
3. Do the same for your other weapons. From then on, swapping weapons loads
   the matching profile, and a chat message tells you which one.

**Load** and **Delete** act on the selected profile. **Unlink** removes the
link for the weapon you have equipped. A weapon without a link keeps whatever
settings are active. The window shows your weapon, its linked profile and the
active profile.

A profile holds every rotation setting from the window: Slam window, GCD
slack, double-press lock, Heroic Strike / Cleave thresholds, Heroic Strike
cost, Sunder, Battle Shout, opener, Slow weapon rotation, the BT + WW pair and
its rage leeway, PvP, Nampower on/off and queue lead. It doesn't hold Nampower's own settings (those belong to the
game) or the minimap icon position.

### Base profiles

WarSlam comes with 4 base profiles for the most common 2H speeds, created
once from your current settings. They come from simulated fights with Flurry
and about 6% haste, with rage matched to real dummy logs:

| Profile | Slam window | Slow weapon | Simulation |
|---|---|---|---|
| **Base 3.40** | 0.60 | Auto (= fast) | At a 2.47s swing, a window above ~0.62 costs 2–4 strikes per minute, so the Auto window is avoided. As a fast weapon, it gets the Slam trade and the BT + WW pair. |
| **Base 3.50** | Auto | Auto (= fast) | Fast weapon rules: without the BT + WW pair, Whirlwind barely gets a turn (0.7/min on the dummy, against 6/min with the pair). |
| **Base 3.60** | Auto | Auto (= slow) | Same strikes for every window. Rage, not timing, is the limit. |
| **Base 3.80** | Auto | Auto (= slow) | Same, and the fast rules were slightly worse in raids. |

**A weapon without a link uses the base profile of its speed**, if there is
one: equip an unlinked 3.60 weapon and "Base 3.60" loads. Your own links
always win. You can edit a base profile (load it, change things, save it
under the same name) or delete it; deleted ones aren't re-created.

You can also use commands: `/warslam profile` lists them,
`/warslam profile save <name>`, `load <name>`, `delete <name>`,
`link <name>`, and `/warslam profile unlink`.


## Boss opener

Between the **1st and 2nd auto attack** of a boss fight, WarSlam doesn't
Slam. That swing's GCDs go to:

1. **Battle Shout**, if it has 60s or less left;
2. **Sunder Armor**, up to 5 stacks, even if Sunder is otherwise off;
3. then Bloodthirst / Mortal Strike and Whirlwind as usual.

From the 2nd **real** auto on, the normal rotation takes over. Swing resets
from Windfury, Hand of Justice and other extra attacks don't count, so a proc
during the first swing doesn't end the opener early. The GCD timing rules
still apply, so the first Slam after the opener isn't lost.

A "boss" is a skull-level target. Tick *...on every fight* in the settings to
use the opener on every pull, e.g. to try it on a training dummy. Change the
60s with `/run WarSlamConfig.OPENER_SHOUT=90`.


## Death Wish

Death Wish triggers the GCD, so pressed by hand during a Slam it gets queued
for the end of the cast and takes that swing's Slam. Instead, press
`/run WarSlamDW()` when you want it, for example when your boss timer says
30 seconds left, and keep pressing your WarSlam button:

- WarSlam fires Death Wish in the **next GCD slot**: right after the current
  Slam, or as the first GCD during the Sunder build. It goes before a BT +
  WW pair; only an urgent Sunder goes first.
- It disarms itself once Death Wish has really gone off (its cooldown
  started), so a failed cast stays armed. Press the macro again to cancel.
- If Death Wish is on cooldown, the macro says so and doesn't arm.
- **9 seconds after Death Wish** (by default), the next WarSlam press uses a
  **Juju Flurry** from your bags on yourself. It can't be used during a Slam
  cast, so it often lands a little after the delay: that's why the default
  is 9 rather than 10. Set the delay with the **Juju Flurry delay** slider,
  or untick **Juju Flurry after Death Wish**, in the settings window. Items are off the GCD, so this
  costs nothing. No Juju in your bags: the arm message tells you, and
  WarSlam simply skips it.

## Overpower and stance dancing

When your target **dodges** (an auto, or any of your strikes),
Overpower is usable for a few seconds (5 in theory, about 4 in practice on OctoWoW), in Battle Stance. With **Nampower**, WarSlam
checks the dodging mob's ID against your target's, so only a dodge by your
actual target counts, even with several mobs of the same name around, and
Whirlwind and Cleave dodges count too. Without Nampower it only has the
combat log text (a name), so Whirlwind and Cleave dodges are ignored: they
hit several mobs, and the one that dodged may be another mob with your
target's name. WarSlam handles the
stance dance, starting from Berserker Stance:

1. Overpower is a strike like Bloodthirst and Whirlwind: it can replace any
   GCD, and it **pairs with BT / MS or WW**, including the pair right after
   the auto that goes before the Slam (auto, BT, Overpower, auto, Slam).
   When your rage is above what a swap keeps, the other strike goes first
   to spend it, then the swap and Overpower; when it's already low,
   Overpower goes first. A pair only starts if the rage covers both
   strikes and the swaps in between.
2. With no pair to make, Overpower takes the **next GCD slot** on its own.
   With a fast weapon that slot usually costs the next Slam: Overpower
   (5 rage) replaces it. Untick **...even if it costs the next Slam** to
   only use slots that cost no Slam (and the Sunder build).
3. Swaps are off the GCD and never happen during a Slam cast: **Battle
   Stance**, the next press casts **Overpower**, then back to **Berserker
   Stance** (Whirlwind needs it).

A swap throws away the rage above what **Tactical Mastery** keeps (5 per
point, read from your talents). WarSlam only swaps when that loss is within
the **Rage a swap may lose** slider (default 0, so no loss). After the
Overpower, if swapping back would throw rage away (an auto often lands while
you're in Battle), WarSlam **stays in Battle to dump it** first: Bloodthirst
/ Mortal Strike if it's ready (even when Whirlwind is due: WW follows right
after the swap), **Heroic Strike** (Cleave in multi target)
while your rage is at or above what Tactical Mastery keeps plus its cost
(25 + 12 = 37 at 5/5 and 3/3 Improved Heroic Strike), and the usual Slam.
It never stays more than 3 seconds, nor when Whirlwind is due. Untick **Stay
in Battle to dump rage** to swap back straight away. WarSlam only manages
the Battle Stance visits it starts itself (or where it casts an Overpower):
if you're in Battle Stance on your own, after a Charge say, it swaps you to
Berserker as soon as that loses **no** rage at all (your rage within what
Tactical Mastery keeps), and otherwise leaves your stance alone. Talents are read again at
every combat start and written to the log ("talents: Tactical Mastery
x/5..."). Without
Tactical Mastery, a swap keeps no rage, so Overpower only happens when your
rage is within the slider. In Defensive Stance, WarSlam never swaps. In PvP
mode there's no Overpower.

In the simulator, with your weapon at 6% haste and 5/5 Tactical Mastery
(about 3 dodges per minute):

| Rage per auto | Rage a swap may lose | Overpower per min | Strikes per min | Rage lost per min |
|---|---|---|---|---|
| 26 (dummy) | off | 0 | 22.8 | 0 |
| 26 (dummy) | 0 | 1.3 | 23.5 | 10 |
| 36 (raid) | off | 0 | 26.6 | 0 |
| 36 (raid) | 0 | 0.5 | 26.8 | 8 |
| 36 (raid) | 10 | 1.2 | 27.2 | 14 |
| 36 (raid) | 30 | 2.0 | 27.6 | 50 (fewer Heroic Strikes) |

(Figures from before Overpower could pair; with pairs, Overpower per minute
rises to about 2.0 at dummy rage, with strikes per minute unchanged.)

The strike test counts Overpower with the other strikes.

## Bloodrage for pairs

When a strike pair (BT / MS, WW, Overpower) is short of rage by no more than
the 10 Bloodrage gives at once, WarSlam can fire **Bloodrage** to complete
it: before the pair starts, or when its 2nd strike comes and the rage came
up short. If that strike needs a stance swap (Overpower into Battle,
Whirlwind back into Berserker), the swap goes **first** and Bloodrage after
it, since a swap would throw Bloodrage's rage away. Bloodrage is off the GCD;
its rage arrives a moment later, so the strike goes on the next press.

Setting **Bloodrage for pairs** (Rotation tab, Cooldowns):

- **Off**: never.
- **With Death Wish** (default): only after you used Death Wish, and only
  while its cooldown has more than 45s left. That covers the whole Death
  Wish buff and the next ~2 minutes, and Bloodrage (60s cooldown) is always
  back within 15s of Death Wish being usable again, so it's there during
  your next Death Wish window.
- **Always**: whenever it's off cooldown, except when Death Wish comes back
  within 45s (it's kept for that window). With Death Wish ready and unused,
  or no Death Wish at all, it's free to fire.

In both modes Bloodrage is kept for the **second half of Death Wish**, so the
Enrage it procs (+20% damage for 8s) overlaps it: during the first 15s of
Death Wish it's held (even for pairs), and from 15s in it goes out as soon as
its 10 rage fits under your rage cap (never wasted by overflowing). Outside
Death Wish the pair rules above still apply.

Never below 30% health (Bloodrage costs health). In the simulator at dummy
rage it fires about once a minute (its cooldown) and turns about one Slam a
minute into a Bloodthirst or Whirlwind, for the same strikes per minute.

## Sunder Armor (optional)

When it's enabled, the full rules below apply to **bosses** (skull level or
world boss). Tick **boss rules on all mobs** to use them everywhere, e.g. on a
training dummy.

On **other mobs**, Sunder is only an *opportunity* strike: it goes out in a
free GCD slot when Bloodthirst / Mortal Strike or Whirlwind is up but you
don't have the rage for it, and only if the next auto will still pay for that
strike after the Sunder. No refresh, no urgent Sunder on trash.

On bosses:

- **Fewer than 5 stacks (after the opener): no Slam.** GCDs go back to back:
  Battle Shout if it's due, then Bloodthirst / Mortal Strike or Whirlwind when
  one is ready and leaves 15 rage for the next Sunder, Sunder in every other
  slot. Instants chain cleanly with Sunder, where a Slam cast would sit in
  between. In the simulator, 5 stacks are up 8–10s sooner (about 8s into the
  fight instead of 18s) for the same strikes per minute. WarSlam reads the
  real debuff, so everyone's Sunders count. Untick **build: no Slam** to go
  back to the old way (Sunder as first GCD, Slams in between).
  **Safety:** if two of your Sunders in a row don't raise the visible
  stacks (sunder-immune boss, raid debuff limit reached), or the target is
  still under 5 stacks after 20s, WarSlam leaves the build phase for that
  target until combat ends and treats it like trash (opportunity Sunders
  only), so Slams come back.
- **5 stacks, more than 8s left:** WarSlam leaves it alone.
- **8s or less left:** Sunder takes the next GCD slot that comes up (after an
  early Slam), as the first GCD ability after Battle Shout. That's usually
  one refresh per ~22s, without ever costing a Slam.
- **4s or less left:** if no GCD slot came up in time, Sunder goes before
  everything, Slam included. If there isn't enough rage,
  WarSlam holds Slam and keeps the rage for Sunder, because losing 5 stacks
  costs far more than one Slam. You can change the 4s with
  `/run WarSlamConfig.SUNDER_URGENT=5`.

If a mob already has Sunder when WarSlam first sees it, e.g. stacks put up
out of range or before a `/reload`, WarSlam assumes the Sunder is fresh from
that moment. So it still refreshes it instead of leaving it alone.

- **With Nampower**, WarSlam sees every Sunder that *lands* on a mob, cast by
  you or anyone else nearby, and tracks each mob separately even when they
  share a name. The refresh is timed from the latest Sunder, so you only step
  in when nobody else has kept it up, e.g. when the tanks forget.
- **Without Nampower**, only your own Sunders are known. Stacks from others
  are timed from when WarSlam first noticed them.

`/warslam` shows the current target's stacks, when the last Sunder landed and
who cast it.


## Settings

Click the **Slam icon on your minimap**, or type `/warslam config`, to open the
settings window. Drag the icon to move it around the minimap. Right-click it
to show the status. Changes apply straight away and are saved between
sessions.

The top of the window always shows the **active profile** (and whether it's
linked to your weapon) and your **weapon**, with the rotation it gets (fast
or slow). Below that, three tabs:

**Rotation**: what you change per weapon or per fight.

| Setting | What it does | Default |
|---|---|---|
| Slam window | Fraction of the swing that must be left to start Slam. Higher = Slam never delays the auto but fewer GCDs fit; lower = more GCDs but late Slams can push the auto back a little. | 0.60 |
| Auto (Slam window) | **Base Slam cast ÷ base weapon speed**, rounded down to 0.05. The base cast comes from your Improved Slam points (0 = 2.5s, 1 = 2.2s, 2 = 2.0s), the weapon speed from its tooltip. Haste shortens Slam and your swing alike, so this ratio doesn't change with haste and no Slam is needed to know it (2.5 / 3.6 = 0.694 → 0.65). Rounding down lets Slam start a touch later: it clips the auto very slightly, for more room for GCDs. Your real Slams are still measured as a check, and `/warslam` warns you if they disagree with the formula. If the weapon speed can't be read, the last real Slam is used instead. | off |
| Heroic Strike at rage | Single target rage dump threshold. | 71 |
| Cleave at rage | Multi target rage dump threshold. | 50 |
| Heroic Strike cost | Shown, not set: read from your talents (15, minus 1 per Improved Heroic Strike point, so 12 at 3/3). | auto |
| Juju Flurry after Death Wish | After `/run WarSlamDW()`, use a Juju Flurry from your bags (see *Death Wish*). | on |
| Juju Flurry delay | Seconds between Death Wish and the Juju Flurry (5–15). | 9 |
| Bloodrage for pairs | Off / With Death Wish / Always: Bloodrage to complete a pair short of rage (see *Bloodrage for pairs*). | With Death Wish |
| Slow weapon rotation | Auto / Yes / No: whether trading a Slam for two strikes is allowed (see *Fast swings*). | Auto |
| Fire BT + WW together | Fast weapons: fire both strikes for one Slam (see *Fast swings*). | on |
| Sunder Armor | Bosses: build to 5 stacks, refresh at 8s, before everything at 4s. Other mobs: opportunity Sunders only (see *Sunder Armor*). | off |
| Keep Battle Shout up | Battle Shout is the first GCD ability (both buttons) when it's missing or has 10s or less left. Change the 10s with `/run WarSlamConfig.SHOUT_REFRESH=15`. | on |
| Boss opener | Battle Shout and Sunder before the 2nd auto (see *Boss opener*). | on |
| PvP: only Slam + BT / MS / WW | In battlegrounds or against enemy players: no Battle Shout, Sunder or opener. | on |
| Overpower (stance dance) | After a dodge: Battle Stance, Overpower, back to Berserker (see *Overpower and stance dancing*). | on |
| ...even if it costs the next Slam | Overpower takes the next GCD slot, before BT + WW pairs, even when that costs the next Slam. Off: only slots that cost no Slam. | on |
| Rage a swap may lose | Rage the swap *to* Battle may throw away above what Tactical Mastery keeps (0–30). | 0 |
| Stay in Battle to dump rage | After Overpower, stay in Battle up to 3s to dump the rage a swap would lose: Bloodthirst / MS, Heroic Strike, Slam. Off: swap back straight away. | on |

**Advanced**: set once.

| Setting | What it does | Default |
|---|---|---|
| GCD slack | Lets a GCD ability run into the next Slam window by this many seconds. Slow weapons only; fast weapons always use 0. Keep at 0. | 0 |
| Double-press lock | After sending Slam or a GCD ability, ignores presses until the game confirms the cast (or this many seconds pass). | 0.50 |
| BT + WW pair: rage leeway | How much rage short of both costs a pair may start, counting on the auto in between. | 0 |
| Heroic Strike when a pair is near | Rage Heroic Strike needs while BT and WW come off cooldown within 3s. | 90 |
| Sunder build: no Slam | Bosses, under 5 Sunders: no Slam, chain Battle Shout / BT / WW / Sunder GCDs. | on |
| Boss Sunder rules on all mobs | Full Sunder rules on every target instead of bosses only (for dummy tests). | off |
| Opener on every fight | Use the opener on every pull, not only against bosses. | off |
| Nampower | Use Nampower queuing, WarSlam queue lead (how early WarSlam may queue before a cast or GCD ends), Nampower's own queue settings, and a **Recommended** button. Greyed out when Nampower isn't installed. | on, 0.30s |

**Profiles & Tools**: profiles and weapon links (see *Profiles*), the 60s
strike test, **Log to file**, **Debug to chat**, the log size with **Clear
logs**, and **Show the minimap button** (also `/warslam minimap`).

**Defaults**, at the bottom of every tab, puts WarSlam's settings back to the
values above. It doesn't change Nampower's settings.


## Commands

| Command | |
|---|---|
| `/warslam config` | Open the settings window (same as clicking the minimap icon) |
| `/warslam minimap` | Hide / show the minimap icon |
| `/warslam` | Show which spells were found, your spec, `st_timer`, attack speed, Nampower status, Sunder on your target and Battle Shout time left |
| `/warslam debug` | Toggle decision messages in chat |
| `/warslam log` | Toggle logging to file |
| `/warslam clear` | Empty the log and the proc list (same as the **Clear logs** button); test results are kept |
| `/warslam mem` | Show your UI's total Lua memory and the size of WarSlam's logs |
| `/warslam test [seconds]` | Start a strike test (default 60s); `/warslam test stop` ends it |
| `/warslam results` | Show your last 10 strike tests |
| `/warslam procs` | Show your last 10 extra attack procs |
| `/warslam profile ...` | List, save, load, delete, link or unlink profiles (see *Profiles*) |


## Strike test

To compare settings, count your strikes over a fixed time on a training
dummy. This works better than DPS, which swings a lot with crits.

1. Type `/warslam test` (60 seconds), `/warslam test 120` for another length,
   or click **Start 60s test** in the settings window.
2. Start hitting the dummy. The timer starts at your first Slam, Bloodthirst,
   Mortal Strike or Whirlwind.
3. When time is up, WarSlam prints the result, for example:
   ```
   TEST 60s: 28 strikes (28.0/min) | Slam 16, BT 8, MS 0, WW 4 | HS 3, Cleave 0, Sunder 2, autos 19 | start: 35s into fight, 5 Sunder on target, 42 rage | slamFrac=auto ...
   ```

The **start** part says how the test began: a *fresh pull* (within 4s of
combat starting: opener, no rage, no Sunders, no Flurry yet) or *Ns into
fight*, with the Sunder stacks and rage at your first strike. Only compare
tests that started the same way: on your dummy, fresh pulls ran about 3
strikes per minute lower than mid-fight starts.

**Strikes** = Slam + Bloodthirst + Mortal Strike + Whirlwind. Dodged, parried
or missed attempts count too, and a Whirlwind that hits several targets counts
once. Heroic Strike, Cleave and auto attacks are shown separately. Each result
records the settings it was run with.

If you get extra attack procs during the test, they're listed at the end of
the result (e.g. `procs: Hand of Justice 3, Wing of the Timelord 1`).

Your own Sunders are listed too (they're not counted as strikes). For
comparable results, test with Sunder off, or remember that on a fresh dummy
the first 5 stacks cost 5 GCDs.

`/warslam results` shows your last 10 tests. `/warslam test stop` ends a test
early. Results are also kept in the log file.


## Extra attack procs

WarSlam records every extra attack proc it sees in the combat log ("You gain
1 extra attack through ..."): Hand of Justice, Wing of the Timelord,
Windfury and so on. For each proc it saves:

- the attack that triggered it, and how much of the swing was left at that moment;
- how much of the swing was left when it procced;
- the next three attacks, with timing and swing %;
- the spell WarSlam chose next, and whether it cast or queued it.

```
PROC Hand of Justice x1 at 25% of swing left | trigger: Mortal Strike 0.01s before (25% of swing left) | next: auto +0.05s (99% left), Slam +2.30s (23% left) | WarSlam: cast Slam +0.25s
```

`/warslam procs` shows the last 10. They're also saved in the log file, and
printed in chat when debug is on.


## Log file

With logging on, the last 5,000 decisions are saved to:

```
WTF\Account\<YOUR ACCOUNT>\SavedVariables\WarSlam.lua
```

The game writes this file only on `/reload` or logout. Each line has the time,
the swing timer, % of swing left, rage and what was cast or why nothing was.
It's useful for tuning the settings or reporting a problem.


## Performance

WarSlam is light. Each press does a few calculations, and swing tracking
costs almost nothing per frame. The parts worth knowing about:

- **File log:** it can hold up to 5,000 lines (about 1MB) and makes the
  saved file bigger, which adds a little to `/reload`, logout and loading
  screens. Keep **Log to file** off in raids unless you're investigating
  something. **Clear logs** (or `/warslam clear`) empties it.
- **Other players' casts** are only listened to when **Sunder Armor** is
  enabled, since that's the only thing that needs them. With Sunder off,
  WarSlam adds nothing to the raid's event traffic.
- `/warslam mem` shows your whole UI's Lua memory and WarSlam's log size. The
  memory line is also at the bottom of the settings window.


## Troubleshooting

- **Nothing happens:** run `/warslam`. If `st_timer = nil`, SP_SwingTimer isn't
  installed or isn't loaded. If a spell shows `slot nil`, it isn't in your spellbook,
  or your client isn't in English.
- **A different spell is cast** (e.g. Charge): check you don't have another
  macro with the same name.
- **`/warslam` says "Unknown command":** the addon isn't loaded. Enable it on
  the character screen.
- **Something feels off:** turn on `/warslam debug`, or the log, and look at
  why each press did what it did.

---

# In depth: how WarSlam decides, and every setting

This part explains the reasoning behind the rotation and every parameter you
can change. You don't need it to
use the addon. It's for tuning, or for understanding why a press did what it
did.

**How to read the timelines in this section:**

```
A  auto attack            R  swing reset (Windfury, Hand of Justice...)
a  where the auto was due (it waited for the Slam to finish)
=  Slam may start here (more than 60% of the swing left)
.  too late to start a Slam in this swing
S  Slam casting           B / W / H / U  Bloodthirst / Whirlwind / Battle Shout / Sunder
-  the 1.5s global cooldown after an instant ability
One character = 0.1s. The "seconds" ruler shows the last digit (…8 9 0 1 = 8s, 9s, 10s, 11s).
```

## 1. The building blocks

**Swing timer.** SP_SwingTimer exposes `st_timer`: the seconds left
before your next main-hand auto. WarSlam divides it by your **current**
attack speed, which includes Flurry and other haste, to get the % of the swing
left. Every rule below works on that percentage, so the rotation adapts to
haste by itself.

**Slam's cast time scales with haste on this server.** Its base cast is 2.5s,
or 2.2s / 2.0s with 1 / 2 points in Improved Slam, and haste shortens it
exactly like your swing: 2.5s on an unhasted 3.6 weapon, 1.83s at 2.64 with
Flurry. So the fraction of the swing a Slam takes is **base cast ÷ base
weapon speed**, whatever your haste (2.5 / 3.6 = 0.694). WarSlam reads both
and still measures your real Slams as a check.

**The auto can't land while you're casting.** If the auto comes due during a
Slam, it waits until the Slam ends. So a Slam only "doesn't delay the auto" if
it starts with **at least 69% of the swing left**:

```
Late Slam at 62% of the swing left, 3.6 swing
  seconds     0         1         2         3         4         5
              |---------|---------|---------|---------|---------|
  autos       A                                   a  A
  Slam window ==============.........................============
  you                       SSSSSSSSSSSSSSSSSSSSSSSSS
```

Here the Slam started with 62% left, so its last 7% ran past the moment the
auto was due. The auto was pushed back by about 0.27s.

**The GCD is 1.5s and doesn't scale with haste.** That's what makes
everything tighter as your weapon gets faster: the swing shrinks, the GCD
doesn't.

## 2. The Slam window (`SLAM_FRAC`)

WarSlam starts a Slam only while more than `SLAM_FRAC` of the swing is left,
and only once per swing.

| Value | Effect |
|---|---|
| **"Auto"** | Base Slam cast (from Improved Slam) ÷ base weapon speed, rounded down to 0.05. With 0 points: 0.70 at 3.40, 0.65 at 3.60 and 3.80. With 2 points: 0.55 at 3.40 and 3.60, 0.50 at 3.80. The rounding lets Slam clip the auto very slightly. |
| **0.60 (default)** | The window is longer, so a GCD fits after an early Slam more often. Slams started between 60% and 69% delay the auto by up to 9% of a swing (0.3s at 3.6). |
| 0.55 | The classic macro value: even more room for GCDs, more auto delay. |

You chose 0.60 after testing: the best flow, with only a small delay on late
Slams.

**Early and late Slams.** An *early* Slam starts right after the auto, at
95–99% left. A *late* Slam starts at the end of the window, just above 60%,
usually because a GCD ability ran first.

## 3. The GCD rule: auto, Slam, GCD, auto, Slam

After a Slam, WarSlam only uses a GCD ability (Bloodthirst, Mortal Strike,
Whirlwind, Sunder, Battle Shout) if its 1.5s GCD **ends before the next
swing's Slam window closes**:

```
GCD allowed if   1.5s  <=  time until the next auto  +  swing x (1 - SLAM_FRAC)
```

If it doesn't fit, the GCD would cost the next Slam, so WarSlam waits. The
debug and log lines show this as `GCD check: ... -> OK / BLOCKED`.

**Unhasted 3.6 weapon:** every swing has room for Slam + GCD. The second Slam
starts at about 86% left (still early enough), so the pattern repeats:

```
3.6 swing (no haste): Slam 2.50s
  seconds     0         1         2         3         4         5         6         7         8         9         0         1
              |---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|---------|
  autos       A                                   A                                   A                                   A
  Slam window ==============......................==============......................==============......................===
  you          SSSSSSSSSSSSSSSSSSSSSSSSSB--------------SSSSSSSSSSSSSSSSSSSSSSSSSW--------------SSSSSSSSSSSSSSSSSSSSSSSSSB----
```

**2.64 swing (Flurry):** after an early Slam the GCD fits, but it pushes the
next Slam late (70% left). A late Slam ends right at the auto, so there's no
room for a GCD after it. The result alternates: *early Slam + GCD, late Slam,
early Slam + GCD...*

```
2.64 swing (Flurry): Slam 1.83s
  seconds     0         1         2         3         4         5         6         7         8
              |---------|---------|---------|---------|---------|---------|---------|---------|
  autos       A                         A                          A                         A
  Slam window ===========...............===========................==========................==
  you          SSSSSSSSSSSSSSSSSSB--------------SSSSSSSSSSSSSSSSSSS SSSSSSSSSSSSSSSSSSW--------
```

**When does a GCD fit after an early Slam?** With a perfect press 0.1s after
the auto:

```
swing needed  =  (1.5 + 0.1) / (2 - 0.694 - SLAM_FRAC)
```

This is your **hasted** swing. The same limits as unhasted weapon speeds:

| `SLAM_FRAC` | Hasted swing needed | = weapon speed with Flurry (+30%) | = with Flurry + 20% more haste |
|---|---|---|---|
| 0.55 | 2.12s | 2.76 | 3.31 |
| 0.60 | 2.27s | 2.95 | 3.54 |
| 0.69 (Auto) | 2.61s | 3.39 | 4.07 |

So with the default 0.60 and Flurry, any 2H weapon from about 3.0 up keeps
the Slam + GCD rhythm. With extra haste on top (trinkets, buffs), even a 3.6
weapon drops below the limit. Below it, the normal rule never lets a GCD
through, and the trade in §4 takes over.

**GCD slack (`GCD_SLACK`).** It lets a GCD run past the point where the next
Slam is still possible. We tried 0.4s, and the logs showed it cost Slams:
after a late Slam, a GCD squeezed in and pushed the next Slam out of its
window. Keep it at 0. With a **fast weapon** it's always 0, whatever the
slider says: your logs at 0.20 showed GCDs ending just after the next Slam
window, leaving whole swings with no Slam. Only slow weapons use the slider.

## 4. Fast swings: trading a Slam (`SLOW_WEAPON`)

When the hasted swing is below the limit in §3, no GCD fits after a Slam.
Slamming every swing gives one strike per swing, for example a 2.9 weapon
with Flurry:

```
2.9 weapon with Flurry = 2.23 swing, trade OFF: Slam 1.55s
  seconds     0         1         2         3         4         5         6         7         8         9
              |---------|---------|---------|---------|---------|---------|---------|---------|---------|
  autos       A                     A                      A                     A                     A
  Slam window =========.............=========..............=========.............=========.............==
  you          SSSSSSSSSSSSSSS       SSSSSSSSSSSSSSSS       SSSSSSSSSSSSSSS       SSSSSSSSSSSSSSS
```

The trade gives up one Slam to fit **two** instant strikes. The swing without
a Slam is used for Whirlwind:

```
2.9 weapon with Flurry = 2.23 swing, trade ON
  seconds     0         1         2         3         4         5         6         7         8         9
              |---------|---------|---------|---------|---------|---------|---------|---------|---------|
  autos       A                     A                      A                     A                     A
  Slam window =========.............=========..............=========.............=========.............==
  you          SSSSSSSSSSSSSSSB--------------W--------------SSSSSSSSSSSSSSSS      SSSSSSSSSSSSSSS
```

Over those 3 swings that's 4 strikes (Slam, BT, WW, Slam) instead of 3.

WarSlam only trades if all of these hold:

1. a strike (Bloodthirst / Mortal Strike / Whirlwind) is ready now;
2. a **second** strike will be ready by the end of the first one's GCD, or up
   to `TRADE_SOON` (0.1s) later, so it's ready when the first one's GCD ends;
3. the second strike's GCD also ends before the Slam window of the swing
   after. Otherwise it costs that Slam too, and the trade gains nothing;
4. you have the rage for both: cost 1 + cost 2 − the rage the auto in
   between will bring (the cautious measured figure, at most `TRADE_RAGE`
   = 10, and none when a Heroic Strike is queued, since HS replaces that
   auto).

Simulated 60s on a dummy, with no rage limit and a press every 0.18s.
Strikes per minute, trade off → on:

| 2H weapon | No haste | Flurry (+30%) | Flurry + 20% more |
|---|---|---|---|
| 3.8 | 27 → 27 (3.80s swing) | 30 → 30 (2.92s) | 34 → 34 (2.44s) |
| 3.6 | 27 → 27 (3.60s) | 32 → 32 (2.77s) | 31 → **35** (2.31s) |
| 3.3 | 27 → 28 (3.30s) | 33 → 33 (2.54s) | 28 → **34** (2.12s) |
| 3.0 | 30 → 31 (3.00s) | 31 → **35** (2.31s) | 31 → **35** (1.92s) |
| 2.9 | 30 → 30 (2.90s) | 27 → **33** (2.23s) | 32 → 32 (1.86s) |

The trade pays off at hasted swings of about 1.9–2.35s. At 1.86s, condition 3
fails, so WarSlam keeps Slamming. Your 3.6 weapon only gets there with extra
haste on top of Flurry. In real fights, the rage check turns some trades down,
so the gain is a bit smaller.

## 5. Windfury and extra attacks

An extra attack (Windfury, Hand of Justice, Wing of the Timelord...) lands
immediately and **resets the swing timer**. If that happens while a GCD is
running, the new swing's Slam window can close before the GCD ends. WarSlam
then uses a GCD ability instead of waiting, which is the best option left.
This is the pattern your procs showed: Bloodthirst at 17% left → Hand of
Justice → reset → Whirlwind at about 42% left.

```
Windfury reset during a GCD, 2.64 swing
  seconds     0         1         2         3         4         5         6
              |---------|---------|---------|---------|---------|---------|
  autos       A                  R                          A
  Slam window ===========........===========................==========.....
  you          SSSSSSSSSSSSSSSSSSB--------------W--------------
```

**Auto or reset?** WarSlam tells them apart by where the swing timer was when
it jumped back up:

| Swing timer before the jump | Meaning |
|---|---|
| 0.15s or less (it had run out) | a real auto |
| more than that, **or** an "extra attack" message came within 0.3s | a reset |

Each new swing in the log is marked `auto` or `reset`. This is what lets the
boss opener (§8) last until the 2nd *real* auto.

**Proc log.** Each proc is recorded with its trigger, its swing %, the next
three attacks and WarSlam's next choice (`/warslam procs`).

## 6. Rage

- **Heroic Strike / Cleave** are queued at most once per swing, at 71 / 50
  rage. They're off the GCD, so they go out in the same press as Slam or a
  GCD ability. A queued one stops that swing from generating rage, hence the
  high thresholds.
- **Reserved rage.** While Heroic Strike or Cleave is queued, its cost is set
  aside (`free` in the log), so the other abilities never spend it.
- **Slam's rage is paid when the cast ends**, not when it starts. We found
  this in the logs: Bloodthirsts queued during a Slam failed for lack of
  rage. When queuing during a Slam, WarSlam now also keeps the Slam's 15 rage
  aside.
- **Urgent Sunder** (§7) holds off Slam to save rage when Sunder is about to
  drop.
- In practice you're often rage-limited. In the dummy tests, about half the
  moments where a GCD ability was allowed had too little rage for one.

## 7. Sunder Armor

Bosses only (or every mob with `SUNDER_ANY`); on other mobs, Sunder is an
opportunity strike when BT / WW are up but short of rage.

- **Under 5 stacks:** Sunder is the first GCD ability (after Battle Shout),
  and may take a blocked GCD slot, costing that Slam.
- **5 stacks, 8s or less left (`SUNDER_REFRESH`):** refreshed in the next
  GCD slot, as the first GCD ability after Battle Shout. It never costs a
  Slam.
- **4s or less left (`SUNDER_URGENT`):** the safety net, for when no GCD slot
  came up in time (rage, procs, a GCD blocked by the timing rule). Sunder
  goes before everything, Slam included.
- **Who Sundered:** with Nampower, every Sunder that *lands* on a mob is
  seen, from anyone nearby, and tracked per mob GUID. Your own Sunders only
  count once the server confirms they landed. A queued Sunder that was
  replaced or failed doesn't count, and the next press queues it again. Missed or dodged
  Sunders don't count. Stacks that were already there when WarSlam first saw
  them are timed from that moment.
- The 1.12 client can't tell an addon how long a debuff has left, so the time
  left is worked out from the last Sunder seen (30s duration).

## 8. Battle Shout and the boss opener

**Battle Shout** is the first GCD ability in both buttons when it's missing or
has 10s or less left (`SHOUT_REFRESH`). Your own buffs' time left is
readable, so this uses the real remaining time.

**Boss opener:** between the 1st and 2nd real auto of a boss fight there's no
Slam. That swing goes to Battle Shout (if 60s or less left, `OPENER_SHOUT`),
then Sunder towards 5 stacks, then Bloodthirst/Whirlwind. The GCD rule still
protects the first Slam after it:

```
Boss opener, 3.6 swing, fresh target
  seconds     0         1         2         3         4         5         6         7         8
              |---------|---------|---------|---------|---------|---------|---------|---------|
  autos       A                                   A                                   A
  Slam window ==============......................==============......................=========
  you          H--------------U--------------U--------------SSSSSSSSSSSSSSSSSSSSSSSSS
```

## 9. Nampower queuing

Without Nampower, each step waits for your next key press. In your tests,
presses came every 0.18s, so each step waited about 0.1s on average:

```
no Nampower:   ...Slam ends|  .   press -> Bloodthirst      (up to one press interval lost)
Nampower:      ...press (queue Bloodthirst) |Slam ends -> Bloodthirst immediately
```

In the last `NP_LEAD` (0.30s) of a Slam cast or GCD, WarSlam works out the
swing state at the moment it ends and sends that spell early. Nampower holds
it and fires it on the first possible frame. Every press re-decides, and a
newer choice replaces the queued one.

Lessons from your logs:

- `NP_QueueCastTimeSpells` was **0** in your config, so queued Slams were
  silently ignored. The **Recommended** button turns it on.
- A 150ms Nampower window capped WarSlam's lead at 0.15s. Recommended sets
  300ms.
- **Never queue a Slam while the auto is waiting:** during a late Slam the
  auto waits for the cast to end. A Slam queued then would fire *before*
  the auto and push it back by a whole extra cast (seen once in the logs: a
  2.4s delay). WarSlam now waits for the auto first.

## 10. Every parameter

Settings marked **window** are in the settings window and saved between
sessions. The others can be changed for the current session with
`/run WarSlamConfig.NAME=value`; they reset at `/reload`. To change them
permanently, edit the `CFG` table at the top of `WarSlam.lua`.

### Rotation timing

| Parameter | Default | Where | What it does / when to change it |
|---|---|---|---|
| `SLAM_FRAC` | 0.60 | window | Fraction of the swing that must be left to start Slam, or `"auto"` (measured cast ÷ swing ≈ 0.69). Lower = more GCDs, late Slams delay the auto a bit. Higher = no delay, fewer GCDs (§2–3). |
| `SLAM_FRAC_START` | 2.5/3.6 | `/run` | Value used for "auto" before the first Slam has been measured. |
| `SLAM_BASE` | {2.5, 2.2, 2.0} | `/run` | Base Slam cast with 0 / 1 / 2 points in Improved Slam, used by "auto". |
| `AUTO_STEP` | 0.05 | `/run` | "auto" is rounded down to this step (0.667 → 0.65). 0.01 gives 0.66; 0 disables rounding. |
| `GCD` | 1.5 | `/run` | Global cooldown length. Don't change it. |
| `GCD_SLACK` | 0 | window | How far a GCD may run into the next Slam window. Slow weapons only; fast weapons always use 0. Keep 0 (§3). |
| `CAST_LOCK` | 0.50 | window | Ignore presses this long after sending Slam or a GCD ability, unless the game confirms the cast first. Stops double casts. |
| `SWING_JUMP` | 0.01 | `/run` | How much `st_timer` must jump up to count as a new swing. |
| `ST_UNIT` | "seconds" | `/run` | `"seconds"` if `st_timer` counts seconds left (SP_SwingTimer does), `"fraction"` if it goes from 1 to 0. |

### Fast weapons

| Parameter | Default | Where | What it does |
|---|---|---|---|
| `SLOW_WEAPON` | "auto" | window | `"yes"` = slow weapon rotation, no trade; `"no"` = fast weapon rotation, trade allowed (§4); `"auto"` = from the main hand's base speed. |
| `SLOW_SPEED` | 3.6 | `/run` | With "auto": a main hand this slow or slower counts as a slow weapon. |
| `TRADE_SOON` | 0.1 | `/run` | The second strike may come off cooldown up to this long after the first one's GCD (it used to be 1.0, which left the slot idle). |
| `TRADE_RAGE` | 10 | `/run` | At most this much rage counted from the auto in between, capped by the cautious measured rage per auto, and 0 when a Heroic Strike is queued (it replaces that auto). |
| `PAIR_STRIKES` | on | window | Fast weapons: when BT/MS and WW are both up and affordable, fire both (Slam, BT, auto, WW instead of the Slam, auto, Slam). |
| `PAIR_RAGE` | 0 | window | How much rage short of both costs the pair may start (0 = both affordable now). Capped by the measured rage per auto, and 0 when a Heroic Strike is queued. |
| `USE_OVERPOWER` | on | window | Overpower after a dodge, with the stance dance. |
| `OP_RAGE_LOSS` | 0 | window | Rage a stance swap may throw away above what Tactical Mastery keeps. |
| `OP_TAKE_BLOCKED` | on | window | Overpower may take a slot that costs the next Slam. |
| `AUTO_BERSERKER` | on | `/run` | In combat in your own Battle Stance (after a Charge): to Berserker as soon as the swap loses no rage. |
| `OP_STAY_BATTLE` | on | window | Stay in Battle after Overpower to dump the rage a swap would lose. |
| `OP_STAY_MAX` | 3 | `/run` | Longest stay in Battle when that's on. |
| `TARGET_SETTLE` | 0.4 | `/run` | After a target change, WarSlam doesn't queue through Nampower for this long (a queued spell keeps the target it was queued on). |
| `OP_FROM_AOE` | off | `/run` | Without Nampower: also open the Overpower window on Whirlwind / Cleave dodges (may be another mob). With Nampower they always count, checked by mob ID. |
| `OP_WINDOW` | 4 | `/run` | How long after a dodge WarSlam still goes for Overpower. 5s in theory, but on OctoWoW it's refused past about 4s. If one is refused anyway, WarSlam takes the window as closed and swaps back. |
| `BLOODRAGE` | dw | window | Bloodrage to complete a pair: `off`, `dw` (after Death Wish, while its cooldown outlasts Bloodrage's), `always`. |
| `BLOODRAGE_DW_SLACK` | 15 | `/run` | Bloodrage may come back up to this many seconds after Death Wish is usable again. |
| `BLOODRAGE_MIN_HP` | 0.30 | `/run` | No Bloodrage below this share of your health. |
| `BLOODRAGE_DW_AFTER` | 15 | `/run` | Bloodrage is held for this many seconds into Death Wish, then used as soon as it doesn't overflow rage (0 = off). |
| `DW_JUJU` | on | window | Use a Juju Flurry after an armed Death Wish (skipped if you have none). |
| `DW_JUJU_DELAY` | 9 | window | Seconds between Death Wish and the Juju Flurry (5–15). It waits for the end of a Slam cast, so it can come a little later. |
| `PAIR_TIMEOUT` | 4 | `/run` | Forget an unfinished pair after this many seconds. |
| `PAIR_HS_AT` | 90 | window | Fast weapons: Heroic Strike needs this much rage while a BT + WW pair is near (both strikes off cooldown within `PAIR_HS_SOON`). |
| `PAIR_HS_SOON` | 3 | `/run` | How many seconds ahead a pair counts as "near" for the Heroic Strike threshold. |

### Rage dumps and costs

| Parameter | Default | Where | What it does |
|---|---|---|---|
| Heroic Strike at rage | 71 | window (`WarSlamModes.ST.dumpAt`) | Single target dump threshold. |
| Cleave at rage | 50 | window (`WarSlamModes.MT.dumpAt`) | Multi target dump threshold. |
| `HS_BASE` | 15 | `/run` | Heroic Strike cost before talents; WarSlam subtracts 1 per Improved Heroic Strike point it finds. |
| `SLAM_COST`, `BT_COST`, `MS_COST`, `WW_COST`, `CLEAVE_COST`, `SHOUT_COST` | 15, 30, 30, 25, 20, 10 | `/run` | Rage costs used to check what you can afford. |
| `SUNDER_COST` | 15 | `/run` | 12 with 3/3 Improved Sunder Armor. |

### Sunder, Battle Shout, opener

| Parameter | Default | Where | What it does |
|---|---|---|---|
| `USE_SUNDER` | off | window | Sunder in the single target rotation (§7). Also turns on tracking of other players' Sunders. |
| `SUNDER_URGENT` | 4 | `/run` | Seconds left at which Sunder goes before everything. |
| `SUNDER_REFRESH` | 8 | `/run` | Seconds left at which a 5-stack is refreshed in the next GCD slot (0 = leave it to the urgent rule). |
| `SUNDER_DUR` | 30 | `/run` | Sunder duration. |
| `USE_SHOUT` | on | window | Keep Battle Shout up. |
| `SHOUT_REFRESH` | 10 | `/run` | Seconds left at which Battle Shout is recast. |
| `OPENER` | on | window | Boss opener (§8). |
| `OPENER_ANY` | off | window | Use the opener on every fight, e.g. on a dummy. |
| `OPENER_SHOUT` | 60 | `/run` | In the opener, recast Battle Shout if it has this many seconds or fewer left. |
| `STALL` | 1.0 | `/run` | Swing timer stuck at 0 this long, outside a Slam cast: the swing counts as stalled and GCD abilities go out without waiting for a Slam window. |
| `PVP_BASIC` | on | window | In a battleground or against an enemy player: only Slam + Bloodthirst / Mortal Strike / Whirlwind (+ Heroic Strike / Cleave). |

### Nampower

| Parameter | Default | Where | What it does |
|---|---|---|---|
| `USE_NAMPOWER` | on | window | Use Nampower queuing if it's installed. |
| `NP_LEAD` | 0.30 | window | How early WarSlam may queue, up to 2s; also capped by Nampower's window. Longer = the choice is made right after the last cast, but it's fixed earlier, so a late Windfury reset is more likely to make it wrong. |
| `NP_SpellQueueWindowMs` | 300 rec. | window (Nampower) | Nampower's own queue window. |
| `NP_QueueCastTimeSpells` | on rec. | window (Nampower) | Needed to queue Slam. |
| `NP_QueueInstantSpells` | on rec. | window (Nampower) | Needed to queue Bloodthirst/Whirlwind/Sunder/Shout. |
| `NP_QueueSpellsOnCooldown` | on rec. | window (Nampower) | Bloodthirst queues as it comes off cooldown. |
| `NP_QueueOnSwingSpells` | off rec. | window (Nampower) | Leave off: WarSlam handles Heroic Strike/Cleave itself. |

Nampower settings are saved by the game in `WTF\Config.wtf` and apply to all
your spells.

### Interface and diagnostics

| Parameter | Default | Where | What it does |
|---|---|---|---|
| `MINIMAP_SHOW`, `MINIMAP_ANGLE` | on, 225 | minimap icon / `/warslam minimap` | Minimap icon and its position. |
| `DEBUG` | off | window, `/warslam debug` | Every decision in chat. |
| Log to file | off | window, `/warslam log` | Every decision in the log file (§11). Keep off in raids. |

## 11. Reading the log

```
[ST] st=0.78 (29% of swing left) rem=0.78s slamCast=1.83s slamFrac=0.600 swing=2.64 rage=50 free=35 queued=nil slammed=yes | NP queue in 0.09s: 26% left then
GCD check: GCD 1.50s - slack 0.00s vs next slam window closes in 1.75s -> OK
queue Bloodthirst (fires in 0.09s)
```

- `st`, `% of swing left`, `rem`: the swing timer at this press.
- `swing`: current hasted swing time. `slamCast`: last measured Slam cast.
- `rage` / `free`: your rage, and what's left after reserved Heroic
  Strike/Cleave and Slam costs.
- `slammed`: whether you already Slammed in this swing.
- `NP queue in 0.09s: 26% left then`: Nampower mode. The decision is made for
  the moment the cast or GCD ends, 0.09s from now.
- `GCD check ... OK / BLOCKED`: the §3 rule. `TRADE check`: the §4 rule.
- Other lines: `waiting: GCD / Slam cast`, `locked` (double-press lock),
  `URGENT Sunder`, `OPENER`, `SWING new swing ... auto / reset`, `SUNDER
  landed by you / other`, `PROC ...`, `TEST ...`.
