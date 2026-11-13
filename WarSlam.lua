-- WarSlam: one-button Slam rotation for vanilla 1.12 warriors
--
-- Macros:
--   /run WarSlamST()   single target: Slam > (Sunder to 5 stacks, optional) > BT/MS > Whirlwind, Heroic Strike at 71+ rage
--   /run WarSlamMT()   multi target:  Slam > Whirlwind > BT/MS (no Sunder), Cleave at 50+ rage
--
-- BT/MS = Bloodthirst for Fury, Mortal Strike for Arms, detected automatically.
--   (/run WarSlam() still works and is the same as WarSlamST)
--
-- Settings window: /warslam config   (values are saved between sessions)
--
-- Requires a swing timer addon that exposes the global `st_timer`:
-- seconds remaining until the next main-hand auto (default), or a 0-1
-- fraction of the swing if your addon works that way (set ST_UNIT below).
--
-- Slam timing: Slam starts only while more than SLAM_FRAC (default 0.60)
-- of the current swing is left, and only once per swing. SLAM_FRAC can
-- also be "auto": Slam cast time / swing time, measured from your real
-- Slam casts (2.5 / 3.6 = 0.694), so a Slam never delays the auto. Everything is relative
-- to your current (hasted) swing; only the 1.5s GCD is in fixed seconds.
--
-- Nampower (optional): if the Nampower client mod is installed, WarSlam
-- decides the next spell slightly before the current Slam cast or GCD ends
-- and sends it early so Nampower queues it. It then goes out on the first
-- possible frame instead of waiting for your next key press. Without
-- Nampower (or with USE_NAMPOWER off) WarSlam works exactly as before.
--
-- Heroic Strike / Cleave are "on next swing" and off the GCD, so they are
-- queued in the same press as Slam or a GCD ability. While one is queued,
-- its rage is set aside so Slam/BT/WW never spend the rage it needs.

------------------------------------------------------------------------
-- CONFIG (edit these)
------------------------------------------------------------------------
local CFG = {
  ST_UNIT        = "seconds", -- "seconds" (st_timer = seconds left) or "fraction" (st_timer goes 1 -> 0)
  SLAM_FRAC      = 0.60, -- fraction of swing that must be left to start Slam; or "auto" = measured Slam cast / swing time
  SLAM_FRAC_START = 2.5 / 3.6, -- used for "auto" until the first Slam has been measured
  SLAM_BASE      = { 2.5, 2.2, 2.0 }, -- base Slam cast with 0 / 1 / 2 points in Improved Slam (this server)
  AUTO_STEP      = 0.05, -- "auto" is rounded DOWN to this step (0.667 -> 0.65): Slam may start a
                         -- touch later, clipping the auto slightly, for more room for GCDs
  GCD            = 1.5,  -- global cooldown in seconds (not affected by haste)
  GCD_SLACK      = 0,    -- seconds a GCD may run past the point where the next slam is no longer possible.
                         -- Keep at 0: anything above 0 lets a GCD cost you the next slam.
  SWING_JUMP     = 0.01, -- st_timer rising by more than this = a new swing started (auto or Windfury)
  CAST_LOCK      = 0.50, -- max time to ignore presses after sending Slam / a GCD ability; released as soon as the game confirms the cast

  SLAM_COST      = 15,
  SUNDER_COST    = 15,   -- 12 with 3/3 Improved Sunder Armor
  BT_COST        = 30,
  MS_COST        = 30,
  WW_COST        = 25,
  HS_BASE        = 15,   -- Heroic Strike cost before Improved Heroic Strike (-1 rage per point, read from talents)
  CLEAVE_COST    = 20,

  SUNDER_DUR     = 30,   -- Sunder Armor duration
  SUNDER_REFRESH = 8,    -- 5 stacks with this many seconds (or fewer) left: refresh it in the next GCD slot
                         -- (first GCD ability after Battle Shout); 0 = leave it to the urgent rule below
  SUNDER_URGENT  = 4,    -- this many seconds (or fewer) left: Sunder goes before everything, Slam included
  USE_SUNDER     = false, -- single target: include Sunder Armor in the GCD priority
  USE_SHOUT      = true,  -- keep Battle Shout up (first GCD ability when missing or running out)

  -- Fast weapons: when a GCD after a Slam would cost the next Slam, still take
  -- it if a second strike (BT / MS / WW) will be ready to fill that swing:
  -- auto, Slam + BT, auto, WW (+ another GCD if it fits), auto, Slam...
  SLOW_WEAPON    = "auto", -- "yes" = slow weapon rotation (Slam + GCD, no trade), "no" = fast weapon
                           -- rotation (trade allowed), "auto" = from your main hand's base speed
  SLOW_SPEED     = 3.6,    -- auto: a main hand this slow or slower counts as a slow weapon
  TRADE_SOON     = 0.1,  -- the 2nd strike may come off cooldown up to this long after the 1st one's GCD
  TRADE_RAGE     = 10,   -- at most this much rage counted from the auto in between (capped by the measured rage per auto, 0 with HS queued)
  -- Fast weapons, both strikes up: when Bloodthirst / Mortal Strike AND Whirlwind are both ready
  -- and you have the rage for both, fire both rather than Slamming:
  -- auto, Slam, BT, auto, WW (instead of the Slam), auto, Slam...
  PAIR_STRIKES   = true,
  PAIR_RAGE      = 0,    -- rage you may be short of for the pair (0 = both must be affordable now)
  PAIR_TIMEOUT   = 4,    -- forget an unfinished pair after this many seconds
  DW_COST        = 10,
  DW_JUJU        = true,  -- after an armed Death Wish, use a Juju Flurry from your bags
  DW_JUJU_DELAY  = 9,     -- ...this many seconds after Death Wish (not usable during a Slam cast, so it can come a bit later)
  JUJU_NAME      = "Juju Flurry",
  USE_OVERPOWER  = true,  -- Overpower after a dodge, dancing Berserker -> Battle -> Berserker
  OP_RAGE_LOSS   = 0,     -- rage a stance swap may throw away (above what Tactical Mastery keeps)
  OP_TAKE_BLOCKED = true, -- Overpower may take a GCD slot that costs the next Slam
  OP_STAY_BATTLE = false, -- after Overpower, stay in Battle to spend rage before swapping back
  OP_STAY_MAX    = 3,     -- ...but never longer than this many seconds
  OP_COST        = 5,
  OP_WINDOW      = 5,     -- Overpower is usable this long after the dodge
  SUNDER_BUILD_GCD = true, -- boss, under 5 Sunders: no Slam, chain BT / WW / Sunder GCDs
  SUNDER_ANY     = false, -- full Sunder priority on every target (dummy tests); off = bosses only
  PAIR_HS_AT     = 90,   -- pair coming up: Heroic Strike only at this much rage (instead of 72)
  PAIR_HS_SOON   = 3,    -- "coming up" = BT/MS and WW both off cooldown within this many seconds
  SHOUT_REFRESH  = 10,    -- refresh Battle Shout with this many seconds (or fewer) left
  SHOUT_COST     = 10,

  -- Opener: between the 1st and 2nd auto of a fight, skip Slam and use the
  -- GCDs for Battle Shout and Sunder Armor (then Bloodthirst / Whirlwind)
  OPENER         = true,  -- use the opener
  OPENER_ANY     = false, -- false = boss fights only (skull-level target); true = every fight
  OPENER_SHOUT   = 60,    -- opener recasts Battle Shout if it has this many seconds or fewer left

  -- PvP: in a battleground, or against an enemy player, only Slam + Bloodthirst /
  -- Mortal Strike / Whirlwind (+ Heroic Strike / Cleave): no Battle Shout, Sunder or opener
  PVP_BASIC      = true,
  STALL          = 0.3,  -- swing timer stuck at 0 this long (target out of reach, kiting...): the
                         -- swing is stalled, so GCD abilities go out without waiting for a Slam window

  USE_NAMPOWER   = true, -- use Nampower spell queuing when Nampower is installed
  NP_LEAD        = 0.30, -- queue at most this many seconds before the cast/GCD ends
                         -- (also capped by Nampower's own NP_SpellQueueWindowMs)

  MINIMAP_SHOW   = true, -- minimap button (toggle with /warslam minimap)
  MINIMAP_ANGLE  = 225,  -- its position around the minimap, in degrees

  DEBUG          = false, -- toggle with /warslam debug
}

-- Per-mode behaviour
local MODES = {
  ST = {
    gcds       = { "Battle Shout", "Sunder Armor", "Overpower", "MAIN", "Whirlwind" }, -- priority order; MAIN = Bloodthirst or Mortal Strike
                                                       -- Sunder here while building stacks (< 5) or with
                                                       -- 8s or less left; 4s or less: urgent rule
    dump       = "Heroic Strike",
    dumpAt     = 71,  -- queue Heroic Strike at this much rage or more
  },
  MT = {
    gcds       = { "Battle Shout", "Whirlwind", "MAIN", "Overpower" },
    dump       = "Cleave",
    dumpAt     = 50,  -- queue Cleave at this much rage or more
  },
}

WarSlamConfig = CFG   -- tweak in-game, e.g. /run WarSlamConfig.SLAM_FRAC=0.6  (or "auto")
WarSlamModes  = MODES -- e.g. /run WarSlamModes.ST.dumpAt=80

------------------------------------------------------------------------
-- Spellbook lookup
------------------------------------------------------------------------
local idx = {}

local function ScanSpells()
  idx = {}
  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end
    idx[name] = i -- later entries are higher ranks
    i = i + 1
  end
end

-- returns a spellbook index whose name really is `name` (rescans if stale)
local function Index(name)
  local i = idx[name]
  if not i or GetSpellName(i, BOOKTYPE_SPELL) ~= name then
    ScanSpells()
    i = idx[name]
  end
  return i
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff8800WarSlam:|r " .. msg)
end

------------------------------------------------------------------------
-- Logging to SavedVariables:
--   WTF\Account\<ACCOUNT>\SavedVariables\WarSlam.lua
-- The game writes that file on /reload or logout.
------------------------------------------------------------------------
local LOG_MAX = 5000
local function Log(msg)
  if not (WarSlamLog and WarSlamLog.enabled) then return end
  local lines = WarSlamLog.lines
  table.insert(lines, string.format("%s %.3f %s", date("%H:%M:%S"), GetTime(), msg))
  local n = table.getn(lines)
  if n > LOG_MAX + 500 then          -- trim oldest in one go
    local keep = {}
    for i = n - LOG_MAX + 1, n do table.insert(keep, lines[i]) end
    WarSlamLog.lines = keep
  end
end

-- decision trace: chat when debug is on, file when logging is on
local function Dbg(msg)
  if CFG.DEBUG then Print(msg) end
  Log(msg)
end
local function Tracing()
  return CFG.DEBUG or (WarSlamLog and WarSlamLog.enabled)
end

-- seconds left on a spell's cooldown (includes the GCD); 999 if unknown spell
local function CD(name)
  local i = Index(name)
  if not i then return 999 end
  local start, dur = GetSpellCooldown(i, BOOKTYPE_SPELL)
  if not start or start == 0 then return 0 end
  local left = start + dur - GetTime()
  if left < 0 then return 0 end
  return left
end

-- cast by name, never by slot number
local CAST_NAME = { ["Slam"] = "Slam()" }
local lastGcdCastAt = -10
local lastGcdName = nil  -- last GCD ability sent (Slam included): a pair may only follow a Slam
local procWatch = {}   -- procWatch.current = proc being followed (see extra attack tracking)
-- lead > 0: Nampower will fire it that many seconds from now (queued)
local function Cast(name, lead)
  lead = lead or 0
  if name ~= "Heroic Strike" and name ~= "Cleave" then lastGcdCastAt = GetTime() + lead; lastGcdName = name end
  local pc = procWatch.current
  if pc and not pc.nextCast and name ~= "Heroic Strike" and name ~= "Cleave" then
    pc.nextCast = string.format("%s %s +%.2fs", lead > 0 and "queued" or "cast", name, GetTime() - pc.t)
  end
  if Tracing() then
    if lead > 0 then Dbg(string.format("queue %s (fires in %.2fs)", name, lead)) else Dbg("cast " .. name) end
  end
  CastSpellByName(CAST_NAME[name] or name)
end

local COST = {
  ["Slam"]          = function() return CFG.SLAM_COST end,
  ["Sunder Armor"]  = function() return CFG.SUNDER_COST end,
  ["Bloodthirst"]   = function() return CFG.BT_COST end,
  ["Mortal Strike"] = function() return CFG.MS_COST end,
  ["Whirlwind"]     = function() return CFG.WW_COST end,
  ["Heroic Strike"] = function() return WarSlamHsCost() end,
  ["Cleave"]        = function() return CFG.CLEAVE_COST end,
  ["Battle Shout"]  = function() return CFG.SHOUT_COST end,
  ["Death Wish"]    = function() return CFG.DW_COST end,
  ["Overpower"]     = function() return CFG.OP_COST end,
}

------------------------------------------------------------------------
-- Nampower detection
------------------------------------------------------------------------
local function NPInstalled()
  return type(QueueSpellByName) == "function"
      or type(GetCastInfo) == "function"
      or type(GetSpellIdCooldown) == "function"
end

-- read a Nampower CVar safely (nil if it doesn't exist)
local function NPCVar(name)
  local ok, v = pcall(GetCVar, name)
  if ok then return v end
  return nil
end

local function NPActive()
  return CFG.USE_NAMPOWER and NPInstalled()
end

-- how far ahead WarSlam may queue: our NP_LEAD, capped by Nampower's window
local function NPWindow()
  local w = CFG.NP_LEAD
  local v = tonumber(NPCVar("NP_SpellQueueWindowMs"))
  if v and v / 1000 < w then w = v / 1000 end
  if w < 0 then w = 0 end
  return w
end

-- is Nampower set to queue this kind of spell?
local function NPQueues(castTime)
  local v
  if castTime then v = NPCVar("NP_QueueCastTimeSpells") else v = NPCVar("NP_QueueInstantSpells") end
  return v == nil or v == "1"   -- default is on
end

WarSlamNampower = { installed = NPInstalled, active = NPActive, window = NPWindow }

------------------------------------------------------------------------
-- Spec detection: Bloodthirst (Fury) or Mortal Strike (Arms)
------------------------------------------------------------------------
local function TabPoints(tab)
  local _, _, points = GetTalentTabInfo(tab)
  return points or 0
end

local function MainStrike()
  local bt = Index("Bloodthirst")
  local ms = Index("Mortal Strike")
  if bt and not ms then return "Bloodthirst" end
  if ms and not bt then return "Mortal Strike" end
  if bt and ms then
    -- both known (shouldn't happen on a normal talent tree):
    -- go with whichever tree has more points (1 = Arms, 2 = Fury)
    if TabPoints(1) > TabPoints(2) then return "Mortal Strike" end
    return "Bloodthirst"
  end
  return nil -- neither talent taken
end

local function SpecName()
  local m = MainStrike()
  if m == "Mortal Strike" then return "Arms" end
  if m == "Bloodthirst" then return "Fury" end
  return "unknown (no BT / MS)"
end

------------------------------------------------------------------------
-- Equipped main hand: base speed (from its tooltip), name and item id
------------------------------------------------------------------------
local weapon = { speed = nil, name = nil, id = nil, link = false }
local scanTip

local function ScanWeapon()
  local link = GetInventoryItemLink("player", 16)
  if link == weapon.link then return end   -- same main hand: nothing to do
  weapon.link = link
  local id, name, speed = nil, nil, nil
  if link then
    local _, _, i = string.find(link, "item:(%d+)")
    local _, _, n = string.find(link, "%[(.+)%]")
    id, name = tonumber(i), n
    if not scanTip then
      scanTip = CreateFrame("GameTooltip", "WarSlamScanTip", nil, "GameTooltipTemplate")
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", 16)
    for li = 1, (scanTip:NumLines() or 0) do
      local r = getglobal("WarSlamScanTipTextRight" .. li)
      local t = r and r:GetText()
      if t then
        local _, _, sp = string.find(t, "Speed (%d+%.%d+)")
        if sp then speed = tonumber(sp) break end
      end
    end
    scanTip:Hide()
  end
  local changed = id ~= weapon.id
  weapon.speed, weapon.name, weapon.id = speed, name, id
  if changed and WarSlamOnWeaponChanged then WarSlamOnWeaponChanged(id, name, speed) end
end

function WarSlamWeapon() return weapon.speed, weapon.name, weapon.id end

-- Improved Slam points (nil until talents are readable)
local impSlam = nil
local impHS = nil      -- points in Improved Heroic Strike (0-3)
local tmPoints = nil   -- points in Tactical Mastery (0-5): 5 rage kept per point on a stance swap
local function ScanTalents()
  if type(GetNumTalentTabs) ~= "function" then return end
  local slam, hs, tm = 0, 0, 0   -- talent not found: no points
  for tab = 1, GetNumTalentTabs() do
    for i = 1, (GetNumTalents(tab) or 0) do
      local name, _, _, _, rank = GetTalentInfo(tab, i)
      if name == "Improved Slam" then slam = rank or 0 end
      if name == "Improved Heroic Strike" then hs = rank or 0 end
      if name == "Tactical Mastery" then tm = rank or 0 end
    end
  end
  impSlam, impHS, tmPoints = slam, hs, tm
end

-- rage a stance swap keeps: 5 per Tactical Mastery point
function WarSlamRageKept()
  if tmPoints == nil then ScanTalents() end
  return 5 * (tmPoints or 0), tmPoints
end

-- Heroic Strike rage cost from talents: 15, minus 1 per Improved Heroic Strike point
function WarSlamHsCost()
  if impHS == nil then ScanTalents() end
  return CFG.HS_BASE - (impHS or 0), impHS
end

-- base Slam cast from talents (before haste)
local function SlamBaseCast()
  if impSlam == nil then ScanTalents() end
  if impSlam == nil then return nil end
  local t = CFG.SLAM_BASE
  return t[impSlam + 1] or t[table.getn(t)]
end
function WarSlamImpSlam() return impSlam, SlamBaseCast() end

-- is the slow weapon rotation in use? (no Slam trade)
local function SlowWeapon()
  if CFG.SLOW_WEAPON == "yes" then return true end
  if CFG.SLOW_WEAPON == "no" then return false end
  local sp = weapon.speed
  if not sp then return true end          -- unknown weapon: keep the plain rotation
  return sp >= CFG.SLOW_SPEED - 0.001
end
WarSlamSlowWeapon = SlowWeapon

------------------------------------------------------------------------
-- Battle Shout: seconds left on your own buff (0 if missing)
------------------------------------------------------------------------
local function ShoutTimeLeft()
  if type(GetPlayerBuff) == "function" then
    for i = 0, 31 do
      local idx = GetPlayerBuff(i, "HELPFUL")
      if not idx or idx < 0 then break end
      local tex = GetPlayerBuffTexture(idx)
      if tex and string.find(tex, "BattleShout") then
        return GetPlayerBuffTimeLeft(idx) or 0
      end
    end
    return 0
  end
  -- fallback: buff present, duration unknown
  if type(UnitBuff) ~= "function" then return 999 end
  for i = 1, 32 do
    local tex = UnitBuff("player", i)
    if not tex then break end
    if string.find(tex, "BattleShout") then return 999 end
  end
  return 0
end
WarSlamShoutTimeLeft = ShoutTimeLeft

------------------------------------------------------------------------
-- Sunder tracking
------------------------------------------------------------------------
-- sunderAt[key] = { t = GetTime() of the last Sunder that landed, by = "you" / "other" }
-- key = the mob's GUID when Nampower (or SuperWoW) can give it, else its name.
-- With Nampower, every Sunder cast by anyone nearby is seen (SPELL_GO events),
-- so the refresh is timed from the latest Sunder, whoever cast it.
local sunderAt = {}
local sunderPrev, sunderPrevKey, sunderPending = nil, nil, 0
local sunderSeen = false        -- true once a Nampower Sunder event has been received

local SUNDER_IDS = { [7386] = true, [7405] = true, [8380] = true, [11596] = true, [11597] = true }
local spellNameCache = {}
local function IsSunderId(id)
  if not id then return false end
  if SUNDER_IDS[id] then return true end
  local n = spellNameCache[id]
  if n == nil then
    n = false
    if type(GetSpellNameAndRankForId) == "function" then
      local ok, name = pcall(GetSpellNameAndRankForId, id)
      if ok and name then n = name end
    end
    spellNameCache[id] = n
  end
  return n == "Sunder Armor"
end

local function TargetKey()
  if not UnitExists("target") then return nil end
  if type(GetUnitGUID) == "function" then
    local ok, g = pcall(GetUnitGUID, "target")
    if ok and type(g) == "string" and g ~= "" and g ~= "0x0000000000000000" then return g end
  end
  local _, g = UnitExists("target")         -- SuperWoW returns the GUID here
  if type(g) == "string" and string.find(g, "^0x") then return g end
  return UnitName("target")
end

local function SunderStacks()
  local i = 1
  while true do
    local tex, count = UnitDebuff("target", i)
    if not tex then return 0 end
    if string.find(tex, "Sunder") then return count or 1 end
    i = i + 1
  end
end

------------------------------------------------------------------------
-- Cast state + swing tracking
------------------------------------------------------------------------
local slamCastMeasured = nil -- last real Slam cast time, seconds
local slamRatio = nil        -- last real Slam cast time / swing time at that moment

-- the Slam window actually in use: value, measured?, last cast, swing at that cast
local slamRatioCast, slamRatioSwing = nil, nil
local function RoundDown(v)
  local step = CFG.AUTO_STEP
  if not step or step <= 0 then return v end
  return math.floor(v / step + 0.0001) * step
end
-- The Slam window in use. Returns: value, source, a, b, raw
--   "talent":   a = base Slam cast (Improved Slam), b = base weapon speed, raw = a / b
--   "measured": a = last Slam cast, b = swing at that cast (no weapon speed known)
--   "start":    nothing known yet
--   "fixed":    SLAM_FRAC is a number
-- Haste shortens Slam and the swing alike, so base cast / base speed is
-- the same fraction as the real cast / real swing.
function WarSlamSlamFrac()
  if CFG.SLAM_FRAC ~= "auto" then return CFG.SLAM_FRAC, "fixed" end
  local base, sp = SlamBaseCast(), weapon.speed
  if base and sp and sp > 0 then return RoundDown(base / sp), "talent", base, sp, base / sp end
  if slamRatio then return RoundDown(slamRatio), "measured", slamRatioCast, slamRatioSwing, slamRatio end
  return RoundDown(CFG.SLAM_FRAC_START), "start", nil, nil, CFG.SLAM_FRAC_START
end
-- last real Slam, as a check: ratio, cast, swing
function WarSlamSlamMeasured() return slamRatio, slamRatioCast, slamRatioSwing end
local slamEndAt = nil        -- GetTime() at which the current Slam cast finishes
local casting = false
local slamCasting = false
local lastSlam, prevSlam = 0, 0
local lastST, swingStart = nil, 0
local inCombat, combatSwings = false, 0   -- swings (autos / resets) since combat started
local combatStartAt = nil
-- Overpower: open for OP_WINDOW seconds after your target dodges
local opUntil, opTarget = nil, nil
local lastSwapAt = -10      -- last stance swap sent
local battleDoneAt = nil    -- in Battle with no Overpower left to do since then
-- Sunder build guard: if my Sunders don't raise the visible stacks (sunder-
-- immune target, raid debuff limit), the build phase would never end and no
-- Slam would ever go out: give up on it for that target until combat ends
local build = { since = nil, sunderAt = nil, before = 0, fails = 0, off = nil }

local zeroSince = nil                     -- since when st_timer has been sitting at 0
local queuedName, queuedAt = nil, -1 -- Heroic Strike / Cleave waiting for the next swing
-- rage an auto actually brings (measured): the pair counts on it for its 2nd strike
local autoRage, autoRageN = 15, 0      -- running average, number of autos measured
local autoDev = 5                      -- average spread around it (dodges, glances, crits)
local rageWatch = nil                  -- { at =, gain = } after a real auto (no HS on it)
local lastRage = nil

------------------------------------------------------------------------
-- Strike test: counts Slam + Bloodthirst/Mortal Strike + Whirlwind
-- (plus Heroic Strike / Cleave and autos as extra info) over a fixed time,
-- from the combat log. Start with /warslam test [seconds].
------------------------------------------------------------------------
local STRIKES = { "Slam", "Bloodthirst", "Mortal Strike", "Whirlwind", "Overpower" }
local EXTRAS  = { "Heroic Strike", "Cleave" }
local test = nil        -- running test
local lastLine = {}     -- [spell] = time of last counted line (Whirlwind / Cleave hit several targets)

local function SettingsSnapshot()
  local np = WarSlamNampower and WarSlamNampower.active()
  local win = np and WarSlamNampower.window() or 0
  return string.format("slamFrac=%s gcdSlack=%.2f sunder=%s nampower=%s lead=%.2f weapon=%s (%s) %s",
    tostring(CFG.SLAM_FRAC), CFG.GCD_SLACK, CFG.USE_SUNDER and "on" or "off",
    np and "on" or "off", win, tostring(weapon.name), tostring(weapon.speed),
    SlowWeapon() and "slow" or "fast")
end

local function TestFinish()
  if not test then return end
  local t = test
  test = nil
  local dur = t.duration
  if t.startAt then
    local elapsed = GetTime() - t.startAt
    if elapsed < dur then dur = elapsed end
  else
    Print("strike test cancelled (no strike landed)")
    return
  end
  local total = t.counts["Slam"] + t.counts["Bloodthirst"] + t.counts["Mortal Strike"] + t.counts["Whirlwind"]
  local perMin = dur > 0 and total * 60 / dur or 0
  local line = string.format(
    "TEST %.0fs: %d strikes (%.1f/min) | Slam %d, BT %d, MS %d, WW %d, OP %d | HS %d, Cleave %d, Sunder %d, autos %d | %s | %s",
    dur, total, perMin, t.counts["Slam"], t.counts["Bloodthirst"], t.counts["Mortal Strike"],
    t.counts["Whirlwind"], t.counts["Overpower"] or 0, t.counts["Heroic Strike"], t.counts["Cleave"], t.sunders or 0, t.autos,
    t.start or "start: ?", t.settings)
  if t.procs then
    local parts = {}
    for src, n in pairs(t.procs) do table.insert(parts, src .. " " .. n) end
    line = line .. " | procs: " .. table.concat(parts, ", ")
  end
  Print(line)
  if WarSlamLog then
    if type(WarSlamLog.tests) ~= "table" then WarSlamLog.tests = {} end
    table.insert(WarSlamLog.tests, date("%Y-%m-%d %H:%M:%S") .. " " .. line)
  end
  Log(line)
end

local function TestStart(seconds)
  seconds = tonumber(seconds) or 60
  if seconds < 5 then seconds = 5 end
  test = { duration = seconds, counts = {}, autos = 0, settings = SettingsSnapshot() }
  for i = 1, table.getn(STRIKES) do test.counts[STRIKES[i]] = 0 end
  for i = 1, table.getn(EXTRAS) do test.counts[EXTRAS[i]] = 0 end
  Print(string.format("strike test armed: %ds, starts at your first Slam / BT / MS / WW. (%s)", seconds, test.settings))
  Log("TEST armed " .. seconds .. "s " .. test.settings)
end

local function TestStrikeLine(msg)
  if not test then return end
  local now = GetTime()
  local all = { STRIKES, EXTRAS }
  for g = 1, 2 do
    local list = all[g]
    for i = 1, table.getn(list) do
      local name = list[i]
      if string.find(msg, "Your " .. name .. " ", 1, true) == 1 then
        -- one cast that hits several targets only counts once
        if not lastLine[name] or now - lastLine[name] > 0.2 then
          if g == 1 and not test.startAt then
            test.startAt = now
            -- how the test started: fresh pull (opener, no rage, no Sunders)
            -- or mid-fight, so tests can be compared like for like
            local into = (inCombat and combatStartAt) and now - combatStartAt or 0
            test.start = string.format("start: %s, %d Sunder on target, %d rage",
              into < 4 and "fresh pull" or string.format("%.0fs into fight", into),
              SunderStacks(), UnitMana("player") or 0)
            Print("strike test started (" .. test.start .. ")")
          end
          if test.startAt and now - test.startAt <= test.duration then
            test.counts[name] = test.counts[name] + 1
          end
        end
        lastLine[name] = now
        return
      end
    end
  end
end

local function TestAutoLine()
  if test and test.startAt and GetTime() - test.startAt <= test.duration then
    test.autos = test.autos + 1
  end
end

WarSlamTest = { start = TestStart, finish = TestFinish, running = function() return test ~= nil end }

------------------------------------------------------------------------
-- Extra attack procs (Hand of Justice, Wing of the Timelord, Windfury...)
-- For each proc: what attack triggered it, where in the swing, and the
-- attacks that came next. Saved in the log and shown by /warslam procs.
------------------------------------------------------------------------
local PROC_MAX = 500
local lastAttack = nil   -- { name, t, pct }

local function SwingPct()
  if type(st_timer) ~= "number" then return -1 end
  if CFG.ST_UNIT == "fraction" then return math.floor(st_timer * 100) end
  local sp = UnitAttackSpeed("player")
  if not sp or sp <= 0 then return -1 end
  return math.floor(st_timer / sp * 100)
end

local function ProcFinish()
  local p = procWatch.current
  if not p then return end
  procWatch.current = nil
  local nexts = {}
  for i = 1, table.getn(p.next) do
    local n = p.next[i]
    table.insert(nexts, string.format("%s +%.2fs (%d%% left)", n.name, n.t - p.t, n.pct))
  end
  local trig = "unknown"
  if p.trigger then
    trig = string.format("%s %.2fs before (%d%% of swing left)", p.trigger.name, p.t - p.trigger.t, p.trigger.pct)
  end
  local line = string.format("PROC %s x%d at %d%% of swing left | trigger: %s | next: %s | WarSlam: %s",
    p.source, p.count, p.pct, trig,
    table.getn(nexts) > 0 and table.concat(nexts, ", ") or "none",
    p.nextCast or "nothing yet")
  Log(line)
  if CFG.DEBUG then Print(line) end
  if WarSlamLog then
    if type(WarSlamLog.procs) ~= "table" then WarSlamLog.procs = {} end
    table.insert(WarSlamLog.procs, date("%H:%M:%S") .. " " .. line)
    local n = table.getn(WarSlamLog.procs)
    if n > PROC_MAX + 50 then
      local keep = {}
      for i = n - PROC_MAX + 1, n do table.insert(keep, WarSlamLog.procs[i]) end
      WarSlamLog.procs = keep
    end
  end
end

-- every attack of yours: autos ("auto") and abilities ("Slam", "Heroic Strike"...)
local function ProcAttackLine(name)
  local now = GetTime()
  local pct = SwingPct()
  local p = procWatch.current
  if p then
    table.insert(p.next, { name = name, t = now, pct = pct })
    if table.getn(p.next) >= 3 then ProcFinish() end
  end
  lastAttack = { name = name, t = now, pct = pct }
end

local function ProcLine(msg)
  local _, _, count, source = string.find(msg, "^You gain (%d+) extra attacks? through (.+)%.$")
  if not source then return false end
  if procWatch.current then ProcFinish() end
  local now = GetTime()
  local trig = nil
  if lastAttack and now - lastAttack.t < 0.5 then trig = lastAttack end
  procWatch.lastAt = now
  procWatch.current = { source = source, count = tonumber(count) or 1, t = now, pct = SwingPct(),
                        trigger = trig, next = {} }
  if test and test.startAt then
    test.procs = test.procs or {}
    test.procs[source] = (test.procs[source] or 0) + 1
  end
  return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("UNIT_RAGE")
f:RegisterEvent("CHARACTER_POINTS_CHANGED")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:RegisterEvent("SPELLCAST_START")
f:RegisterEvent("SPELLCAST_STOP")
f:RegisterEvent("SPELLCAST_FAILED")
f:RegisterEvent("SPELLCAST_INTERRUPTED")
f:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
f:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
f:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
f:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
f:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("VARIABLES_LOADED")
-- Nampower events (ignored if Nampower isn't installed)
pcall(f.RegisterEvent, f, "SPELL_GO_SELF")    -- your own casts only: cheap

-- Other players' casts (SPELL_GO_OTHER fires for every spell anyone nearby
-- casts) and deaths are only needed to track everyone's Sunders, so they're
-- only listened to while Sunder is enabled.
local listeningOthers = nil
function WarSlamUpdateEvents()
  local want = CFG.USE_SUNDER and true or false
  if want == listeningOthers then return end
  listeningOthers = want
  if want then
    pcall(f.RegisterEvent, f, "SPELL_GO_OTHER")
    pcall(f.RegisterEvent, f, "UNIT_DIED")
  else
    pcall(f.UnregisterEvent, f, "SPELL_GO_OTHER")
    pcall(f.UnregisterEvent, f, "UNIT_DIED")
  end
end
WarSlamUpdateEvents()

-- Watch st_timer every frame: when it jumps back up, a new swing just
-- started (normal auto or Windfury reset). Haste-independent.
local function UpdateSwing()
  if type(st_timer) == "number" then
    if lastST and st_timer > lastST + CFG.SWING_JUMP then
      swingStart = GetTime()
      -- a (queued) Slam that started together with this auto belongs to the new swing
      if slamCasting and swingStart - lastSlam < 0.3 then swingStart = lastSlam - 0.001 end
      -- real auto: the timer had run out. Reset (Windfury, Hand of Justice...):
      -- it jumped back up mid-swing, or right after an "extra attack" message.
      local before = lastST
      if CFG.ST_UNIT == "fraction" then before = lastST * (UnitAttackSpeed("player") or 1) end
      local reset = before > 0.15 or (procWatch.lastAt and GetTime() - procWatch.lastAt < 0.3)
      Log(string.format("SWING new swing (st %.2f -> %.2f)%s", lastST, st_timer, reset and " reset" or " auto"))
      -- the opener lasts until the 2nd real auto, whatever procs in between
      if inCombat and not reset then combatSwings = combatSwings + 1 end
      -- the swing that just landed used up any queued HS / Cleave
      if not reset then
        -- measure this auto's rage unless a queued HS / Cleave replaced it
        if queuedName and queuedAt < swingStart then rageWatch = nil
        else rageWatch = { at = swingStart, gain = 0 } end
      end
      if queuedName and queuedAt < swingStart then queuedName = nil end
    end
    lastST = st_timer
    if st_timer <= 0.01 then
      if not zeroSince then zeroSince = GetTime() end
    else
      zeroSince = nil
    end
  end
end
f:SetScript("OnUpdate", function()
  UpdateSwing()
  if rageWatch and GetTime() - rageWatch.at > 0.5 then
    if rageWatch.gain > 0 then
      autoRageN = autoRageN + 1
      local k = autoRageN < 5 and 1 / autoRageN or 0.2   -- plain average first, then smoothed
      local d = rageWatch.gain - autoRage
      if d < 0 then d = -d end
      autoDev = autoDev + (d - autoDev) * k
      autoRage = autoRage + (rageWatch.gain - autoRage) * k
    end
    rageWatch = nil
  end
  if test and test.startAt and GetTime() - test.startAt > test.duration then TestFinish() end
  if procWatch.current and GetTime() - procWatch.current.t > 3 then ProcFinish() end
end)

f:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    if type(WarSlamLog) ~= "table" then WarSlamLog = {} end
    if WarSlamLog.enabled == nil then WarSlamLog.enabled = false end
    if type(WarSlamLog.lines) ~= "table" then WarSlamLog.lines = {} end
    return
  end
  if event == "SPELLCAST_START" then
    lastGcdCastAt = -10   -- game confirmed the cast: release the double-press lock
    Log(string.format("EVENT cast start %s (%s ms) st=%s", tostring(arg1), tostring(arg2), tostring(st_timer)))
    casting = true
    if arg1 == "Slam" then
      slamCasting = true
      prevSlam, lastSlam = lastSlam, GetTime()
      slamEndAt = nil
      -- arg2 = real cast time in ms (includes talents / any haste)
      if arg2 and tonumber(arg2) and tonumber(arg2) > 0 then
        slamCastMeasured = tonumber(arg2) / 1000
        slamEndAt = GetTime() + slamCastMeasured
        local sp = UnitAttackSpeed("player")
        if sp and sp > 0 then
          slamRatio = slamCastMeasured / sp
          slamRatioCast, slamRatioSwing = slamCastMeasured, sp
        end
      end
    end

  elseif event == "SPELLCAST_STOP" then
    lastGcdCastAt = -10   -- instant ability went off (or Slam finished): release the lock
    Log("EVENT cast stop st=" .. tostring(st_timer))
    casting, slamCasting = false, false

  elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
    lastGcdCastAt = -10
    -- with Nampower, a spell queued behind the Slam can fail (e.g. not enough
    -- rage) right as the Slam finishes: that's not the Slam failing
    local queuedFail = event == "SPELLCAST_FAILED" and slamCasting and slamEndAt
                       and GetTime() > slamEndAt - 0.25
    Log("EVENT " .. event .. (queuedFail and " (queued spell, Slam unaffected)" or "") .. " st=" .. tostring(st_timer))
    if not queuedFail then
      -- a slam that never landed shouldn't count as "slammed this swing"
      if slamCasting then lastSlam = prevSlam end
      casting, slamCasting = false, false
    end

  elseif event == "UNIT_RAGE" then
    if arg1 == "player" then
      local r = UnitMana("player")
      if rageWatch and lastRage and r > lastRage and GetTime() - rageWatch.at <= 0.5 then
        rageWatch.gain = rageWatch.gain + (r - lastRage)
      end
      lastRage = r
    end

  elseif event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
    TestAutoLine()
    ProcAttackLine("auto")
    -- "You attack. X dodges." -> Overpower window
    if event == "CHAT_MSG_COMBAT_SELF_MISSES" and arg1 then
      local _, _, who = string.find(arg1, "^You attack%. (.+) dodges%.$")
      if who then
        opUntil, opTarget = GetTime() + CFG.OP_WINDOW, who
        if Tracing() then Dbg("OVERPOWER window: " .. who .. " dodged your auto") end
      end
    end

  elseif event == "CHAT_MSG_SPELL_SELF_BUFF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
    if arg1 then ProcLine(arg1) end

  elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
    -- "Your Bloodthirst was dodged by X." -> Overpower window
    if arg1 then
      local _, _, sp, who = string.find(arg1, "^Your (.-) was dodged by (.+)%.$")
      if who then
        opUntil, opTarget = GetTime() + CFG.OP_WINDOW, who
        if Tracing() then Dbg("OVERPOWER window: " .. who .. " dodged your " .. sp) end
      end
    end
    if arg1 and not ProcLine(arg1) then
      TestStrikeLine(arg1)
      local _, _, spell = string.find(arg1, "^Your (.-) [hcwmfibrp][a-z]* ")
      if spell then ProcAttackLine(spell) end
    end
    -- undo the Sunder timestamp if it was dodged / parried / missed
    if sunderPrevKey and GetTime() - sunderPending < 1.5
       and string.find(arg1, "^Your Sunder Armor")
       and (string.find(arg1, "dodged") or string.find(arg1, "parried")
            or string.find(arg1, "missed")) then
      sunderAt[sunderPrevKey] = sunderPrev
      sunderPrevKey = nil
    end

  elseif event == "SPELL_GO_SELF" or event == "SPELL_GO_OTHER" then
    -- Nampower: arg2 spellId, arg3 casterGuid, arg4 targetGuid, arg6 targets hit
    if IsSunderId(tonumber(arg2)) and arg4 and arg4 ~= "0x0000000000000000"
       and (tonumber(arg6) or 1) > 0 then
      sunderSeen = true
      local by = (event == "SPELL_GO_SELF") and "you" or "other"
      sunderAt[arg4] = { t = GetTime(), by = by }
      sunderPrevKey = nil   -- confirmed by the server: no need for the dodge undo
      Log("SUNDER landed by " .. by .. " on " .. tostring(arg4))
      if by == "you" and test and test.startAt then test.sunders = (test.sunders or 0) + 1 end
    end

  elseif event == "UNIT_DIED" then
    if arg1 then sunderAt[arg1] = nil end

  elseif event == "PLAYER_REGEN_DISABLED" then
    Log("---- combat start ----")
    build.since, build.sunderAt, build.fails, build.off = nil, nil, 0, nil
    inCombat = true
    combatStartAt = GetTime()
    -- the opening auto often lands just before combat is flagged
    if GetTime() - swingStart < 0.5 then combatSwings = 1 else combatSwings = 0 end

  elseif event == "PLAYER_REGEN_ENABLED" then
    Log("---- combat end ----")
    inCombat, combatSwings = false, 0
    sunderAt = {} -- forget timers after combat
    queuedName = nil

  elseif event == "UNIT_INVENTORY_CHANGED" then
    if arg1 == "player" then ScanWeapon() end

  elseif event == "CHARACTER_POINTS_CHANGED" then
    ScanTalents()

  else
    ScanSpells()
    ScanTalents()   -- spells changed: maybe a respec
    if event == "PLAYER_ENTERING_WORLD" then ScanWeapon() end
  end
end)

------------------------------------------------------------------------
-- GCD ability checks
------------------------------------------------------------------------
-- seconds of Sunder left on the target at time `at`; nil if no Sunder on it.
-- If the target has Sunder but no Sunder was seen landing (applied before
-- WarSlam was watching, or out of range), it's assumed fresh from the
-- moment it was first noticed, so it still gets refreshed.
local function SunderTimeLeft(at)
  if not UnitExists("target") or UnitIsDead("target") then return nil end
  local key = TargetKey()
  if SunderStacks() == 0 then
    sunderAt[key] = nil          -- fell off (or never there): forget the old timer
    return nil
  end
  local rec = sunderAt[key]
  if not rec then
    rec = { t = GetTime(), by = "unseen" }
    sunderAt[key] = rec
  end
  return CFG.SUNDER_DUR - (at - rec.t)
end

local function WantSunder(now)
  if not UnitExists("target") or UnitIsDead("target") then return false end
  if SunderStacks() < 5 then return true end          -- real debuff: anyone's Sunders count
  local left = SunderTimeLeft(now)
  return left ~= nil and left <= CFG.SUNDER_REFRESH
end

local function ModeHasSunder(mode)
  for k = 1, table.getn(mode.gcds) do
    if mode.gcds[k] == "Sunder Armor" then return true end
  end
  return false
end

local function CastSunder(now, lead)
  if NPInstalled() then
    -- Nampower reports every Sunder that actually lands (SPELL_GO_SELF), so
    -- don't assume it: a queued Sunder can still be replaced or fail, and
    -- marking it done early let the next press queue something else over it.
    Cast("Sunder Armor", lead)
    return
  end
  -- no Nampower: assume it lands; undone if dodged/parried/missed
  local key = TargetKey()
  sunderPrev, sunderPrevKey, sunderPending = sunderAt[key], key, now
  sunderAt[key] = { t = now + lead, by = "you" }
  Cast("Sunder Armor", lead)
end

-- for /warslam: what WarSlam knows about the current target's Sunder
function WarSlamSunderStatus()
  if not UnitExists("target") then return "no target" end
  local left = SunderTimeLeft(GetTime())
  local rec = sunderAt[TargetKey()]
  local age = (left and rec) and string.format("~%.1fs left (last Sunder by %s), refresh at %ds left, urgent at %ds left",
    left, rec.by, CFG.SUNDER_REFRESH, CFG.SUNDER_URGENT) or "no Sunder on target"
  return string.format("%d stacks, %s (%s)", SunderStacks(), age,
    sunderSeen and "tracking everyone's Sunders" or "tracking your own Sunders only")
end

-- ready now (lead = 0) or by the time we can act (lead > 0, Nampower queue)
------------------------------------------------------------------------
-- Stances (Battle / Berserker) for Overpower
------------------------------------------------------------------------
local function StanceIndex(name)
  if type(GetNumShapeshiftForms) ~= "function" then return nil end
  for i = 1, (GetNumShapeshiftForms() or 0) do
    local _, n, active = GetShapeshiftFormInfo(i)
    if n == name then return i, active end
  end
  return nil
end

-- name of the stance you're in (nil if unknown)
local function ActiveStance()
  if type(GetNumShapeshiftForms) ~= "function" then return nil end
  for i = 1, (GetNumShapeshiftForms() or 0) do
    local _, n, active = GetShapeshiftFormInfo(i)
    if active then return n end
  end
  return nil
end

local function StanceReady()
  if GetTime() - lastSwapAt < 1.0 then return false end     -- 1s stance cooldown
  return true
end

-- rage a swap would throw away right now
local function SwapLoss(rage)
  local loss = rage - (WarSlamRageKept())
  if loss < 0 then loss = 0 end
  return loss
end

local function SwapTo(name, why)
  local i = StanceIndex(name)
  if not i then return false end
  CastShapeshiftForm(i)
  lastSwapAt = GetTime()
  if Tracing() then Dbg("STANCE: " .. name .. " (" .. why .. ")") end
  return true
end

-- Overpower window open on your target, and Overpower off cooldown by then
local function OPUp(now, lead)
  if not CFG.USE_OVERPOWER or not opUntil or not Index("Overpower") then return false end
  if opUntil - (now + (lead or 0)) < 0.2 then return false end
  if opTarget ~= UnitName("target") then return false end
  return CD("Overpower") <= (lead or 0) + 0.02
end

local function Ready(name, rage, lead)
  -- stance rules: Whirlwind needs Berserker Stance, Overpower Battle Stance
  if name == "Whirlwind" or name == "Overpower" then
    local st = ActiveStance()
    if st and st ~= (name == "Whirlwind" and "Berserker Stance" or "Battle Stance") then return false end
  end
  return CD(name) <= (lead or 0) + 0.02 and rage >= COST[name]()
end

-- the GCD slot is free for Overpower: cast it in Battle Stance, or swap to
-- Battle first (off the GCD) when the swap wastes no more than OP_RAGE_LOSS.
-- Returns true when it did something (this press is used).
local function TryOverpower(now, lead, rage, free, where)
  if not OPUp(now, lead) or not inCombat then return false end
  local st = ActiveStance()
  if st == "Battle Stance" then
    if Ready("Overpower", free, lead) then
      if Tracing() then Dbg("OVERPOWER (" .. where .. ")") end
      Cast("Overpower", lead)
      return true
    end
    return false
  end
  if st ~= "Berserker Stance" or casting or not StanceReady() then return false end
  local loss = SwapLoss(rage)
  local after = rage - loss - (free < rage and (rage - free) or 0)  -- what's left for Overpower
  if loss > CFG.OP_RAGE_LOSS or after < COST["Overpower"]() then
    if Tracing() then Dbg(string.format("OVERPOWER skipped: swap would lose %d rage (max %d), %d left after (rage %d, free %d)", loss, CFG.OP_RAGE_LOSS, after, rage, free)) end
    return false
  end
  return SwapTo("Battle Stance", string.format("Overpower in the %s, %d rage lost", where, loss))
end

------------------------------------------------------------------------
-- The button
------------------------------------------------------------------------
-- in a battleground, or targeting an enemy player
local function InPvP()
  if UnitExists("target") and UnitIsPlayer("target") and UnitCanAttack("player", "target") then
    return true
  end
  if type(GetBattlefieldStatus) == "function" then
    for i = 1, (MAX_BATTLEFIELD_QUEUES or 3) do
      local status = GetBattlefieldStatus(i)
      if status == "active" then return true end
    end
  end
  return false
end
WarSlamInPvP = InPvP

local function IsBossTarget()
  if not UnitExists("target") then return false end
  if UnitLevel("target") == -1 then return true end           -- skull
  local c = UnitClassification and UnitClassification("target")
  return c == "worldboss"
end

-- full Sunder rules (build first, refresh, urgent) on bosses; elsewhere Sunder
-- is only an opportunity strike when the damage strikes lack rage
local function SunderFull()
  if build.off and build.off == UnitName("target") then return false end  -- Sunders don't show: trash rules
  return CFG.SUNDER_ANY or IsBossTarget()
end

-- in the opener: after the 1st auto of the fight, before the 2nd
local function OpenerActive()
  if not CFG.OPENER or not inCombat or combatSwings ~= 1 then return false end
  return CFG.OPENER_ANY or IsBossTarget()
end
WarSlamOpenerActive = OpenerActive

-- Bloodthirst / Mortal Strike / Whirlwind of this mode, in priority order
local function StrikeList(mode)
  local strikes = {}
  for k = 1, table.getn(mode.gcds) do
    local n = mode.gcds[k]
    if n == "MAIN" then n = MainStrike() end
    if n and (n == "Bloodthirst" or n == "Mortal Strike" or n == "Whirlwind") and Index(n) then
      table.insert(strikes, n)
    end
  end
  return strikes
end

-- fast weapon, pair on, and BT/MS + WW both off cooldown soon (Heroic Strike holds its rage)
local function PairSoon(mode)
  if not CFG.PAIR_STRIKES or SlowWeapon() then return false end
  local strikes = StrikeList(mode)
  if table.getn(strikes) < 2 then return false end
  for i = 1, table.getn(strikes) do
    if CD(strikes[i]) > CFG.PAIR_HS_SOON then return false end
  end
  return true
end

local pair = nil   -- { first =, second =, at =, sent = }: a pair of strikes in progress

------------------------------------------------------------------------
-- Strikes with stance needs: Overpower (Battle), Whirlwind (Berserker)
------------------------------------------------------------------------
-- can this strike go out in the slot that starts in `lead` seconds,
-- counting the stance swap it may need (and the rage that swap throws away)?
local function StrikeUsable(name, now, lead, rage, free)
  if not Index(name) or CD(name) > lead + 0.02 then return false end
  local st = ActiveStance()
  if name == "Overpower" then
    if not CFG.USE_OVERPOWER or not opUntil or opUntil - (now + lead) < 0.2 then return false end
    if opTarget ~= UnitName("target") then return false end
    if st == "Battle Stance" then return free >= COST["Overpower"]() end
    if st ~= "Berserker Stance" then return false end
    local loss = SwapLoss(rage)
    return loss <= CFG.OP_RAGE_LOSS and free - loss >= COST["Overpower"]()
  end
  if name == "Whirlwind" and st == "Battle Stance" then
    return free - SwapLoss(rage) >= COST["Whirlwind"]()      -- the swap back comes first
  end
  return Ready(name, free, lead)
end

-- cast a strike, swapping stance first if it needs one ("swap": the cast
-- comes on the next press; "wait": the stance can't change yet)
local function CastStrike(name, lead, why)
  local st = ActiveStance()
  local need = (name == "Overpower" and "Battle Stance") or (name == "Whirlwind" and "Berserker Stance")
  if need and st and st ~= need then
    if casting or not StanceReady() then return "wait" end
    SwapTo(need, why)
    return "swap"
  end
  Cast(name, lead)
  return "cast"
end

-- would this pair work, rage and stances included? `incoming`: rage the auto
-- in between brings (0 when none lands or a Heroic Strike replaces it)
local function PairWorks(first, second, now, lead, rage, free, incoming)
  if CD(first) > lead + 0.02 or CD(second) > lead + CFG.GCD + 0.05 then return false end
  local keep = WarSlamRageKept()
  local reserve = rage - free                        -- Heroic Strike / Slam already paid for
  local st = ActiveStance()
  local r = free
  if first == "Overpower" then
    if not opUntil or opUntil - (now + lead) < 0.4 or opTarget ~= UnitName("target") then return false end
    if st == "Berserker Stance" then
      local loss = SwapLoss(rage)
      if loss > CFG.OP_RAGE_LOSS then return false end
      r = r - loss
    elseif st ~= "Battle Stance" then return false end
    st = "Battle Stance"
    r = r - COST["Overpower"]()
  else
    if first == "Whirlwind" and st ~= "Berserker Stance" then return false end
    r = r - COST[first]()
  end
  if r < 0 then return false end                     -- the 1st strike must be affordable now
  -- after Overpower the rage is down to what the swap kept: don't count on
  -- the auto for the 2nd strike, a short one would leave it stranded
  if first ~= "Overpower" then r = r + incoming end
  if second == "Overpower" then
    if not opUntil or opUntil - (now + lead + CFG.GCD) < 0.3 or opTarget ~= UnitName("target") then return false end
    if st == "Berserker Stance" then
      local loss = r + reserve - keep
      if loss < 0 then loss = 0 end
      if loss > CFG.OP_RAGE_LOSS then return false end
      r = r - loss
    elseif st ~= "Battle Stance" then return false end
    return r >= COST["Overpower"]()
  end
  if second == "Whirlwind" and st == "Battle Stance" then
    local loss = r + reserve - keep                  -- the swap back throws this away
    if loss > 0 then r = r - loss end
  end
  return r >= COST[second]()
end

-- best pair for the next two GCD slots: one with Overpower first (its window
-- is short), strike before Overpower when the rage is above what a swap keeps
local function ChoosePair(mode, now, lead, rage, free, incoming, pvp)
  local strikes = StrikeList(mode)
  if CFG.USE_OVERPOWER and not pvp and Index("Overpower") and opUntil then
    for i = 1, table.getn(strikes) do
      if PairWorks(strikes[i], "Overpower", now, lead, rage, free, incoming) then return strikes[i], "Overpower" end
      if PairWorks("Overpower", strikes[i], now, lead, rage, free, incoming) then return "Overpower", strikes[i] end
    end
  end
  for i = 1, table.getn(strikes) do
    for j = 1, table.getn(strikes) do
      if i ~= j and PairWorks(strikes[i], strikes[j], now, lead, rage, free, incoming) then
        return strikes[i], strikes[j]
      end
    end
  end
  return nil
end

-- start a pair: its 1st strike now (or the stance swap it needs)
local function StartPair(first, second, now, lead, why)
  pair = { first = first, second = second, at = now, sent = false }
  if CastStrike(first, lead, why) == "cast" then pair.sent = true end
end

-- would the GCD list pick Battle Shout or Sunder right now? (they keep priority over a pair)
local function UtilityWanted(mode, opener, pvp, now, lead, free, gcdFits)
  if pvp then return false end
  for k = 1, table.getn(mode.gcds) do
    local n = mode.gcds[k]
    if n == "Battle Shout" and Index(n) and Ready(n, free, lead) then
      local left = ShoutTimeLeft() - lead
      if (CFG.USE_SHOUT and left <= CFG.SHOUT_REFRESH) or (opener and left <= CFG.OPENER_SHOUT) then return true end
    elseif n == "Sunder Armor" and (opener or (CFG.USE_SUNDER and SunderFull())) and Index(n) and Ready(n, free, lead) then
      -- building (under 5) always wins; a 5-stack refresh only when it can
      -- actually go in this slot, else it would block the pair for nothing
      -- (the urgent rule still refreshes it at 4s)
      if WantSunder(now) and (SunderStacks() < 5 or gcdFits or opener) then return true end
    end
  end
  return false
end


------------------------------------------------------------------------
-- Death Wish on demand: /run WarSlamDW() arms it, WarSlam fires it in the
-- next GCD slot and disarms once it has really gone off (cooldown started).
-- Juju Flurry follows DW_JUJU_DELAY seconds later (items are off the GCD).
------------------------------------------------------------------------
local function FindBagItem(name)
  for bag = 0, 4 do
    for slot = 1, (GetContainerNumSlots(bag) or 0) do
      local link = GetContainerItemLink(bag, slot)
      if link and string.find(link, "[" .. name .. "]", 1, true) then return bag, slot end
    end
  end
  return nil
end

local dwArmedAt = nil      -- armed by the macro
local jujuAt = nil         -- use Juju Flurry from this time on

-- start time of Death Wish's current cooldown (nil if not on its own cooldown)
local function DWStart()
  local i = Index("Death Wish")
  if not i then return nil end
  local start, dur = GetSpellCooldown(i, BOOKTYPE_SPELL)
  if not start or start == 0 or not dur or dur < 10 then return nil end  -- GCD only
  return start
end

function WarSlamDW()
  if not Index("Death Wish") then Print("Death Wish not in your spellbook") return end
  if dwArmedAt then
    dwArmedAt = nil
    Print("Death Wish disarmed")
    return
  end
  local left = CD("Death Wish")
  if left > CFG.GCD + 0.1 then
    Print(string.format("Death Wish is on cooldown (%ds left)", math.floor(left)))
    return
  end
  dwArmedAt = GetTime()
  local juju = ""
  if CFG.DW_JUJU then
    if FindBagItem(CFG.JUJU_NAME) then juju = ", then " .. CFG.JUJU_NAME .. " " .. CFG.DW_JUJU_DELAY .. "s later"
    else juju = " (no " .. CFG.JUJU_NAME .. " in your bags: Death Wish only)" end
  end
  Print("Death Wish armed: next GCD" .. juju)
  if UIErrorsFrame then UIErrorsFrame:AddMessage("WarSlam: Death Wish next GCD", 1, 0.8, 0) end
end

-- did the armed Death Wish go off? -> disarm, schedule the Juju
local function DWCheck(now)
  if not dwArmedAt then return end
  local start = DWStart()
  if start and start >= dwArmedAt - 0.5 then
    dwArmedAt = nil
    if CFG.DW_JUJU then jujuAt = start + CFG.DW_JUJU_DELAY end
    Log(string.format("DW: Death Wish went off%s", jujuAt and string.format(", %s at +%ds", CFG.JUJU_NAME, CFG.DW_JUJU_DELAY) or ""))
  end
end


-- Juju Flurry on yourself (it asks for a target: point it at you)
local function UseJuju(now)
  if not jujuAt or now < jujuAt then return end
  local bag, slot = FindBagItem(CFG.JUJU_NAME)
  if not bag then
    Log("DW: no " .. CFG.JUJU_NAME .. " in your bags")
    jujuAt = nil
    return
  end
  local start, dur = GetContainerItemCooldown(bag, slot)
  if start and start > 0 and start + dur - now > 0.2 then return end   -- its own cooldown
  if Tracing() then Dbg("DW: using " .. CFG.JUJU_NAME) end
  UseContainerItem(bag, slot)
  if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit("player") end
  jujuAt = nil
end
WarSlamDWArmed = function() return dwArmedAt ~= nil, jujuAt end

-- rage the trade may count on from the auto before its 2nd strike: none when
-- a queued HS / Cleave replaces that auto, else the cautious measured figure
local function TradeIncoming(rem, lead)
  if queuedName or rem >= lead + CFG.GCD + 0.3 then return 0 end
  local inc = math.floor(autoRage - autoDev / 2)
  if inc > CFG.TRADE_RAGE then inc = CFG.TRADE_RAGE end
  if inc < 0 then inc = 0 end
  return inc
end

local function Run(modeName)
  local mode = MODES[modeName]
  local np = NPActive()
  -- mid-Slam: without Nampower there's nothing to do until it ends
  if casting and not (np and slamCasting and slamEndAt) then return end
  if type(st_timer) ~= "number" then
    if Tracing() then Dbg("st_timer missing - is the swing timer addon loaded?") end
    return
  end

  UpdateSwing()                                 -- catch an auto that landed this very frame
  local now    = GetTime()
  local swing  = UnitAttackSpeed("player")      -- current speed, Flurry included
  local remSec, frac
  if CFG.ST_UNIT == "fraction" then
    frac, remSec = st_timer, st_timer * swing
  else
    remSec, frac = st_timer, st_timer / swing
  end
  local slamCast = slamCastMeasured or 0       -- last measured Slam cast (log only)
  local slamFrac = CFG.SLAM_FRAC
  if slamFrac == "auto" then slamFrac = (WarSlamSlamFrac()) end
  local rage   = UnitMana("player")

  -- 0) RAGE DUMP (off GCD): queue Heroic Strike / Cleave once per swing.
  --    It costs no rage until the swing lands, but it also stops that
  --    swing from generating rage, hence the high threshold.
  local hsAt = mode.dumpAt
  if pair then
    hsAt = hsAt + COST[pair.second]()            -- rage a pending pair still needs
  elseif PairSoon(mode) and CFG.PAIR_HS_AT > hsAt then
    hsAt = CFG.PAIR_HS_AT                         -- keep the rage for the BT + WW pair
  end
  if not casting and not queuedName and rage >= mode.dumpAt and rage < hsAt and Index(mode.dump) and Tracing() then
    Dbg(string.format("%s held: rage %d < %d (BT + WW pair coming up)", mode.dump, rage, hsAt))
  end
  if not casting and not queuedName and rage >= hsAt and Index(mode.dump) then
    Cast(mode.dump)
    queuedName, queuedAt = mode.dump, now
  end
  -- rage still free for GCD abilities once the queued strike is paid for
  local free = rage
  if queuedName then free = rage - COST[queuedName]() end
  DWCheck(now)
  if not casting then UseJuju(now) end

  -- STANCE: back to Berserker once the Overpower is done or its window closed
  -- (off the GCD). If that would throw away more rage than OP_RAGE_LOSS, stay
  -- in Battle and spend it first (Slam, BT, HS work there), unless WW is due.
  if ActiveStance() ~= "Battle Stance" or OPUp(now, 1.0) then battleDoneAt = nil end
  if CFG.USE_OVERPOWER and inCombat and not casting and ActiveStance() == "Battle Stance"
     and not OPUp(now, 1.0) and StanceIndex("Berserker Stance") and StanceReady() then
    if not battleDoneAt then battleDoneAt = now end
    local loss = SwapLoss(rage)
    -- optional: stay a little to spend the rage, never past OP_STAY_MAX or a due WW
    local stay = CFG.OP_STAY_BATTLE and loss > CFG.OP_RAGE_LOSS and now - battleDoneAt < CFG.OP_STAY_MAX
      and not (Index("Whirlwind") and CD("Whirlwind") <= 1.5)
    if not stay then
      SwapTo("Berserker Stance", string.format("Overpower done, %d rage lost", loss))
      return
    end
    if Tracing() then Dbg(string.format("STANCE: staying in Battle to spend rage (a swap would lose %d), %.1fs left", loss, CFG.OP_STAY_MAX - (now - battleDoneAt))) end
  end

  local gcd = CD("Slam")
  if gcd == 999 then
    if Tracing() then Dbg("Slam not found in spellbook") end
    return
  end

  -- how long until we can act: end of the Slam cast and/or the GCD
  local lead, what = gcd, "GCD"
  if casting then
    local castLeft = slamEndAt - now
    if castLeft < 0 then castLeft = 0 end
    if castLeft >= lead then lead, what = castLeft, "Slam cast" end
  end
  local window = 0
  if np then window = NPWindow() end
  if lead > window then
    if Tracing() then Dbg(string.format("waiting: %s %.2fs left", what, lead)) end
    return
  end
  if lead > 0.005 then
    -- Nampower: we'll queue. A key press can replace the queued spell, so no lock.
  else
    lead = 0
    -- a cast was just sent and the game hasn't confirmed it yet: don't double-press
    if now - lastGcdCastAt < CFG.CAST_LOCK then
      if Tracing() then Dbg(string.format("locked: last cast %.2fs ago", now - lastGcdCastAt)) end
      return
    end
  end

  -- Slam's rage is only spent when the cast finishes, so a spell queued
  -- during the cast must leave room for it (the log showed queued
  -- Bloodthirsts failing for lack of rage)
  if casting then free = free - CFG.SLAM_COST end

  -- swing state at the moment we can act (= now when lead is 0)
  local slammed = lastSlam >= swingStart
  local rem = remSec - lead
  -- the auto is waiting for this Slam cast to end: a Slam queued now would
  -- fire before the auto and push it back by a whole cast
  local autoPending = casting and rem <= 0.05
  local crossesAuto = lead > 0 and rem <= 0
  if lead > 0 and rem <= 0 then
    -- the auto lands before then, so that's a new swing
    if casting then
      rem = swing          -- the auto waits for the Slam cast, then a full swing starts
    else
      rem = swing + rem
    end
    slammed = false
  end
  local fr = rem / swing
  local pvp = CFG.PVP_BASIC and InPvP()
  local opener = OpenerActive() and not crossesAuto and not pvp

  if Tracing() then
    Dbg(string.format("[%s%s] st=%.2f (%d%% of swing left) rem=%.2fs slamCast=%.2fs slamFrac=%.3f swing=%.2f rage=%d free=%d queued=%s slammed=%s%s",
      modeName, pvp and " PvP" or "", st_timer, math.floor(frac * 100), remSec, slamCast, slamFrac, swing, rage, free, tostring(queuedName),
      slammed and "yes" or "no",
      (lead > 0) and string.format(" | NP queue in %.2fs: %d%% left then", lead, math.floor(fr * 100)) or ""))
  end

  -- 0b) SUNDER ABOUT TO FALL OFF: goes before everything, Slam included.
  --     Losing 5 stacks costs far more than one Slam.
  if not pvp and CFG.USE_SUNDER and ModeHasSunder(mode) and Index("Sunder Armor") and SunderFull() then
    local left = SunderTimeLeft(now + lead)
    if left and left <= CFG.SUNDER_URGENT then
      if Ready("Sunder Armor", free, lead) and (lead == 0 or NPQueues(false)) then
        if Tracing() then Dbg(string.format("URGENT Sunder: %.1fs left", left)) end
        CastSunder(now, lead)
        return
      elseif free < COST["Sunder Armor"]() then
        -- keep the rage for it rather than spending it on Slam
        if Tracing() then Dbg(string.format("URGENT Sunder: %.1fs left, saving rage (free=%d)", left, free)) end
        return
      end
    end
  end

  -- 0c) PAIR, 2nd strike: the 1st one went out, so this GCD slot goes to the
  --     2nd strike instead of the Slam (fast weapons, see PAIR_STRIKES)
  if pair then
    if now - pair.at > CFG.PAIR_TIMEOUT then
      pair = nil
    elseif not pair.sent then
      -- the 1st strike still has to go out (a stance swap came first)
      if StrikeUsable(pair.first, now, lead, rage, free) then
        if lead == 0 or NPQueues(false) then
          if CastStrike(pair.first, lead, "pair") == "cast" then pair.sent = true end
        end
        return
      end
      if Tracing() then Dbg("PAIR: " .. pair.first .. " no longer usable: pair dropped") end
      pair = nil
    elseif CD(pair.first) > CFG.GCD + 0.1 then          -- its own cooldown runs: it was cast
      if StrikeUsable(pair.second, now, lead, rage, free) and (lead == 0 or NPQueues(false)) then
        local n = pair.second
        local res = CastStrike(n, lead, "pair")
        if res == "cast" then
          pair = nil
          if Tracing() then Dbg("PAIR: " .. n .. " instead of the Slam") end
        end
        return
      end
      -- short of rage but the auto in between hasn't landed yet: wait for its rage
      if free < COST[pair.second]() and (swingStart <= pair.at or now - swingStart < 0.15) and CD(pair.second) <= lead + 0.05
         and not (queuedName and queuedAt <= now) then
        if Tracing() then Dbg(string.format("PAIR: %s needs %d rage (have %d): waiting for the auto", pair.second, COST[pair.second](), free)) end
        return
      end
      if Tracing() then Dbg(string.format("PAIR: %s not affordable (%d rage) or not ready: back to Slam", pair.second, free)) end
      pair = nil
    end
  end

  -- 0d) SUNDER BUILD (boss, under 5 stacks, after the opener): no Slam, GCDs
  --     back to back. BT / WW when ready (they chain with Sunder without
  --     the Slam cast in between), Sunder in the other slots.
  local building = CFG.SUNDER_BUILD_GCD and not pvp and not opener and inCombat and CFG.USE_SUNDER
     and ModeHasSunder(mode) and SunderFull() and Index("Sunder Armor")
     and UnitExists("target") and not UnitIsDead("target") and SunderStacks() < 5
     and build.off ~= UnitName("target")
  if building then
    local stacks = SunderStacks()
    if not build.since then build.since = now end
    -- did my last build Sunder add a stack?
    if build.sunderAt and now - build.sunderAt > 1.0 then
      if stacks > build.before then build.fails = 0 else build.fails = build.fails + 1 end
      build.sunderAt = nil
    end
    if build.fails >= 2 or now - build.since > 20 then
      build.off = UnitName("target")
      Log(string.format("BUILD: %s, back to the normal rotation for this target",
        build.fails >= 2 and "my Sunders don't show on the target" or "still under 5 Sunders after 20s"))
      building = false
    end
  else
    build.since, build.sunderAt = nil, nil
  end
  if building then
    pair = nil
    if lead > 0 and not NPQueues(false) then return end
    if dwArmedAt and Ready("Death Wish", free, lead) then
      if Tracing() then Dbg("BUILD: Death Wish (armed)") end
      Cast("Death Wish", lead)
      return
    end
    if TryOverpower(now, lead, rage, free, "Sunder build") then return end
    if Index("Battle Shout") and Ready("Battle Shout", free, lead) and CFG.USE_SHOUT
       and ShoutTimeLeft() - lead <= CFG.SHOUT_REFRESH then
      if Tracing() then Dbg("BUILD: Battle Shout") end
      Cast("Battle Shout", lead)
      return
    end
    local strikes = StrikeList(mode)
    -- a strike only if it leaves the rage for the next Sunder
    local keepSunder = COST["Sunder Armor"]()
    for i = 1, table.getn(strikes) do
      if Ready(strikes[i], free - keepSunder, lead) then
        if Tracing() then Dbg(string.format("BUILD (%d Sunder): %s instead of a Slam", SunderStacks(), strikes[i])) end
        Cast(strikes[i], lead)
        return
      end
    end
    if Ready("Sunder Armor", free, lead) then
      if Tracing() then Dbg(string.format("BUILD (%d Sunder): Sunder Armor", SunderStacks())) end
      if not build.sunderAt then build.sunderAt, build.before = now + lead, SunderStacks() end
      CastSunder(now, lead)
      return
    end
    if Tracing() then Dbg(string.format("BUILD: waiting for rage (free=%d)", free)) end
    return
  end

  -- 1) SLAM: one per swing, only while enough of the swing is left.
  --    (not in the opener: that swing's GCDs go to Battle Shout / Sunder)
  if opener and Tracing() then Dbg("OPENER: no Slam before the 2nd auto") end
  -- 1a) PAIR NOW (fast weapon): right after the auto, BT / MS and WW both up
  --     and the rage for both: two GCDs now, done before the next Slam
  --     window closes (auto, BT, WW, auto, Slam). Costs this swing's Slam,
  --     like any pair, but the strikes go out a swing earlier.
  if not opener and not slammed and fr > slamFrac and CFG.PAIR_STRIKES and not SlowWeapon()
     and not pair and not dwArmedAt and not autoPending and (lead == 0 or NPQueues(false))
     and not UtilityWanted(mode, opener, pvp, now, lead, free, false) then
    local nextClose = rem + swing * (1 - slamFrac)    -- next swing's Slam window closes
    if lead + 2 * CFG.GCD <= nextClose then
      local first, second = ChoosePair(mode, now, lead, rage, free, 0, pvp)
      if first then
        if Tracing() then
          Dbg(string.format("PAIR NOW: %s + %s up, rage %d: both before the next auto (done in %.2fs, next Slam window closes in %.2fs), Slam after it",
            first, second, free, lead + 2 * CFG.GCD, nextClose))
        end
        StartPair(first, second, now, lead, "pair now")
        return
      end
    end
  end

  if not opener and not slammed and fr > slamFrac then
    if autoPending then
      if Tracing() then Dbg("auto pending at end of Slam cast: Slam waits for the auto") end
      return
    end
    if free >= CFG.SLAM_COST and (lead == 0 or NPQueues(true)) then Cast("Slam", lead) end
    return
  end

  -- 2) GCD ABILITY: allowed only if its fixed 1.5s GCD is over before the
  --    NEXT swing's slam window closes, so the next slam still happens
  --    (late in that swing). After an early slam that's true; after a late
  --    slam or a Windfury reset it isn't.
  local slamLatest = swing * slamFrac              -- slam must start with at least this much swing left
  local windowEnd = rem + swing - slamLatest       -- seconds from then until next swing's slam window closes

  -- DEATH WISH armed by the macro: this GCD slot, whatever it costs
  if dwArmedAt and Index("Death Wish") and Ready("Death Wish", free, lead) and (lead == 0 or NPQueues(false)) then
    if Tracing() then Dbg("DW: Death Wish (armed) in this GCD slot") end
    pair = nil
    Cast("Death Wish", lead)
    return
  end

  -- PAIR, 1st strike: fast weapon, both strikes up, rage for both -> fire the
  -- 1st now even if it costs the next Slam; the 2nd replaces that Slam (0c)
  -- only in the 1st GCD slot after a Slam: after another GCD (Sunder, Shout,
  -- a strike), BT would be the 2nd GCD and WW the 3rd, which costs 2 Slams
  -- (the Slam of this swing: one from the previous swing doesn't count)
  -- ...or when the 1st strike fits as a normal GCD (its GCD ends before the
  -- next Slam window closes): then only the 2nd one costs a Slam
  local slack = CFG.GCD_SLACK
  if not SlowWeapon() then slack = 0 end
  local gcdFits = CFG.GCD - slack <= windowEnd
  local afterSlam = (lastGcdName == "Slam" and slammed) or gcdFits
  if not afterSlam and not pair and not opener and Tracing() and PairSoon(mode) then
    Dbg("PAIR: not after a Slam (last GCD: " .. tostring(lastGcdName) .. ") and BT/WW would cost this Slam too: wait for the next Slam")
  end
  if CFG.PAIR_STRIKES and not SlowWeapon() and not opener and not pair and afterSlam
     and (lead == 0 or NPQueues(false)) and not UtilityWanted(mode, opener, pvp, now, lead, free, gcdFits) then
    -- rage that comes in before the 2nd strike: the auto in between, if it
    -- lands in time and no HS / Cleave replaces it (capped by PAIR_RAGE)
    local incoming = 0
    if not queuedName and rem < lead + CFG.GCD + 0.3 then incoming = math.floor(autoRage - autoDev / 2) end
    if incoming < 0 then incoming = 0 end
    if incoming > CFG.PAIR_RAGE then incoming = CFG.PAIR_RAGE end
    local first, second = ChoosePair(mode, now, lead, rage, free, incoming, pvp)
    if first then
      if Tracing() then
        Dbg(string.format("PAIR: %s + %s are up, rage %d (+~%d from the auto): %s now, %s instead of the next Slam", first, second, free, incoming, first, second))
      end
      StartPair(first, second, now, lead, "pair")
      return
    elseif Tracing() and PairSoon(mode) then
      Dbg(string.format("PAIR: none affordable (rage %d, auto brings ~%d%s)", free, incoming, queuedName and ", HS queued" or ""))
    end
  end

  -- OVERPOWER alone in the next GCD slot, even a blocked one (it then costs
  -- the next Slam: 5 rage instead of 15), when no pair took it
  if CFG.OP_TAKE_BLOCKED and not pvp and not opener and not pair and (lead == 0 or NPQueues(false))
     and TryOverpower(now, lead, rage, free, "next GCD slot") then
    return
  end
  -- fast weapons: no slack (set above), a GCD that ends after the next Slam
  -- window would either clip the auto or cost that Slam (slow weapons keep GCD_SLACK)
  if Tracing() then
    Dbg(string.format("GCD check: GCD %.2fs - slack %.2fs vs next slam window closes in %.2fs -> %s",
      CFG.GCD, slack, windowEnd, (CFG.GCD - slack <= windowEnd) and "OK" or "BLOCKED"))
  end
  if lead > 0 and not NPQueues(false) then return end
  -- the auto is overdue and not landing (target out of reach): there's no
  -- Slam window to protect, so don't hold GCD abilities back for one
  local stalled = not casting and zeroSince and now - zeroSince > CFG.STALL
  if stalled then
    if Tracing() then Dbg(string.format("swing stalled for %.1fs: GCD abilities allowed", now - zeroSince)) end
  elseif CFG.GCD - slack > windowEnd then
    -- boss, still under 5 Sunders: a Sunder may take this slot (costs the Slam)
    if not pvp and CFG.USE_SUNDER and ModeHasSunder(mode) and SunderFull() and SunderStacks() < 5
       and Index("Sunder Armor") and Ready("Sunder Armor", free, lead) and WantSunder(now) then
      if Tracing() then Dbg(string.format("SUNDER build (%d stacks): takes the blocked slot", SunderStacks())) end
      CastSunder(now, lead)
      return
    end
    -- doesn't fit: trade the next Slam for two strikes, if two are coming
    if SlowWeapon() then return end
    local strikes = {}
    for k = 1, table.getn(mode.gcds) do
      local n = mode.gcds[k]
      if n == "MAIN" then n = MainStrike() end
      if n and (n == "Bloodthirst" or n == "Mortal Strike" or n == "Whirlwind") and Index(n) then
        table.insert(strikes, n)
      end
    end
    local first, second = nil, nil
    for i = 1, table.getn(strikes) do
      if not first and Ready(strikes[i], free, lead) then first = strikes[i] end
    end
    if first then
      for i = 1, table.getn(strikes) do
        local n = strikes[i]
        if n ~= first and CD(n) <= lead + CFG.GCD + CFG.TRADE_SOON then second = n end
      end
    end
    -- the trade only gains a strike if the 2nd one's GCD is also over before
    -- the Slam window of the swing after (otherwise it costs that Slam too)
    local fitsAfter = false
    if second then
      local secondStart = CFG.GCD
      local cd2 = CD(second) - lead
      if cd2 > secondStart then secondStart = cd2 end
      local secondEnd = secondStart + CFG.GCD
      local windowC = rem + swing + swing * (1 - slamFrac)  -- that Slam window closes then
      fitsAfter = secondEnd - slack <= windowC
    end
    local rageOK = first and second and fitsAfter and
      free >= COST[first]() + COST[second]() - TradeIncoming(rem, lead)
    if Tracing() then
      Dbg(string.format("TRADE check: now %s, next %s, fits before the following Slam: %s, rage %d -> %s",
        tostring(first), tostring(second), fitsAfter and "yes" or "no", free,
        rageOK and "trade the next Slam" or "no"))
    end
    if not rageOK then return end
    Cast(first, lead)
    return
  end

  for k = 1, table.getn(mode.gcds) do
    local name = mode.gcds[k]
    if name == "MAIN" then name = MainStrike() end
    if name == "Sunder Armor" and (pvp or not (opener or (CFG.USE_SUNDER and SunderFull()))) then name = nil end
    if name == "Battle Shout" and pvp then name = nil end
    if name == "Overpower" then
      if not pvp and TryOverpower(now, lead, rage, free, "free GCD slot") then return end
      name = nil
    end
    if name == "Battle Shout" then
      local left = ShoutTimeLeft() - lead
      if not ((CFG.USE_SHOUT and left <= CFG.SHOUT_REFRESH) or (opener and left <= CFG.OPENER_SHOUT)) then name = nil end
    end
    if name and Index(name) and Ready(name, free, lead) then
      if name == "Sunder Armor" then
        if WantSunder(now) then
          CastSunder(now, lead)
          return
        end
      else
        Cast(name, lead)
        return
      end
    end
  end
  -- not a boss: Sunder as an opportunity, when a damage strike is up but short of rage
  if not pvp and CFG.USE_SUNDER and not opener and not SunderFull() and ModeHasSunder(mode)
     and Index("Sunder Armor") and Ready("Sunder Armor", free, lead) and WantSunder(now) then
    local strikes = StrikeList(mode)
    for i = 1, table.getn(strikes) do
      local n = strikes[i]
      -- the auto before the next GCD slot must still pay for the strike after the Sunder
      local incoming = 0
      if not queuedName and rem < lead + CFG.GCD then incoming = math.floor(autoRage - autoDev / 2) end
      if CD(n) <= lead + 0.05 and free < COST[n]()
         and free - COST["Sunder Armor"]() + incoming >= COST[n]() then
        if Tracing() then Dbg(string.format("SUNDER opportunity: %s up but %d rage < %d", n, free, COST[n]())) end
        CastSunder(now, lead)
        return
      end
    end
  end
  if Tracing() then Dbg("no GCD ability ready (cooldown or rage: free=" .. free .. ")") end
end

function WarSlamST() Run("ST") end
function WarSlamMT() Run("MT") end
WarSlam = WarSlamST

------------------------------------------------------------------------
-- /warslam        -> show what the addon sees
-- /warslam config -> open the settings window (or click the minimap button)
-- /warslam minimap -> show / hide the minimap button
-- /warslam debug  -> toggle printing every decision to chat
-- /warslam log    -> toggle logging every decision to SavedVariables\WarSlam.lua
-- /warslam clear  -> empty the log and proc list
-- /warslam mem    -> memory: whole UI and WarSlam's logs
-- /warslam test [s]-> count strikes for s seconds (default 60) from your first strike
-- /warslam test stop / /warslam results
-- /warslam procs   -> last 10 extra attack procs (Hand of Justice, Windfury...)
-- /warslam profile [save|load|delete|link <name> | unlink]
------------------------------------------------------------------------
-- empties the decision log and the proc list (strike test results are kept)
function WarSlamClearLogs()
  if not WarSlamLog then return end
  WarSlamLog.lines = {}
  WarSlamLog.procs = {}
  if collectgarbage then collectgarbage() end
  Print("log cleared (strike test results kept)")
end

local function SizeKB(list)
  if type(list) ~= "table" then return 0, 0 end
  local n, bytes = table.getn(list), 0
  for i = 1, n do bytes = bytes + string.len(list[i]) + 24 end
  return n, bytes / 1024
end

function WarSlamMemInfo()
  local total = gcinfo and gcinfo() or 0
  local ln, lkb = SizeKB(WarSlamLog and WarSlamLog.lines)
  local pn, pkb = SizeKB(WarSlamLog and WarSlamLog.procs)
  local tn, tkb = SizeKB(WarSlamLog and WarSlamLog.tests)
  return string.format("UI Lua memory: %.1f MB (all addons) | WarSlam logs: %d lines, %d procs, %d tests (~%.0f KB) | file log %s | others' casts %s",
    total / 1024, ln, pn, tn, lkb + pkb + tkb,
    (WarSlamLog and WarSlamLog.enabled) and "ON" or "off",
    listeningOthers and "tracked (Sunder on)" or "ignored")
end

SLASH_WARSLAM1 = "/warslam"
SlashCmdList["WARSLAM"] = function(msg)
  if msg == "config" or msg == "ui" or msg == "options" then
    if WarSlamUI_Toggle then WarSlamUI_Toggle() end
    return
  end
  if msg == "minimap" then
    if WarSlamUI_ToggleMinimap then WarSlamUI_ToggleMinimap() end
    return
  end
  if msg == "debug" then
    CFG.DEBUG = not CFG.DEBUG
    Print("debug " .. (CFG.DEBUG and "ON" or "OFF"))
    return
  end
  if msg == "log" then
    WarSlamLog.enabled = not WarSlamLog.enabled
    Print("file log " .. (WarSlamLog.enabled and "ON" or "OFF") ..
      " (" .. table.getn(WarSlamLog.lines) .. " lines; written to SavedVariables\\WarSlam.lua on /reload or logout)")
    return
  end
  local _, _, cmd, rest = string.find(msg or "", "^(%S*)%s*(.-)$")
  if cmd == "profile" then
    local _, _, sub, pname = string.find(rest or "", "^(%S*)%s*(.-)$")
    if sub == "save" then WarSlamProfileSave(pname)
    elseif sub == "load" then WarSlamProfileLoad(pname)
    elseif sub == "delete" then WarSlamProfileDelete(pname)
    elseif sub == "link" then WarSlamProfileLink(pname)
    elseif sub == "unlink" then WarSlamProfileUnlink()
    else
      local names = {}
      for n in pairs(WarSlamSettings.profiles or {}) do table.insert(names, n) end
      table.sort(names)
      Print("profiles: " .. (table.getn(names) > 0 and table.concat(names, ", ") or "none") ..
        " | active: " .. tostring(WarSlamSettings.active) ..
        " | /warslam profile save|load|delete|link <name>, /warslam profile unlink")
    end
    return
  end
  if cmd == "test" then
    if rest == "stop" then TestFinish() else TestStart(rest) end
    return
  end
  if cmd == "procs" then
    local list = WarSlamLog and WarSlamLog.procs
    if not list or table.getn(list) == 0 then Print("no extra attack procs recorded yet") return end
    local n = table.getn(list)
    for i = math.max(1, n - 9), n do Print(list[i]) end
    return
  end
  if cmd == "results" then
    local list = WarSlamLog and WarSlamLog.tests
    if not list or table.getn(list) == 0 then Print("no strike tests yet") return end
    local n = table.getn(list)
    for i = math.max(1, n - 9), n do Print(list[i]) end
    return
  end
  if msg == "clear" then
    WarSlamClearLogs()
    return
  end
  if msg == "mem" then
    Print(WarSlamMemInfo())
    return
  end
  ScanSpells()
  local names = { "Slam", "Sunder Armor", "Bloodthirst", "Mortal Strike", "Whirlwind", "Heroic Strike", "Cleave", "Battle Shout" }
  for k = 1, table.getn(names) do
    local n = names[k]
    local i = idx[n]
    local found, rank
    if i then found, rank = GetSpellName(i, BOOKTYPE_SPELL) end
    Print(n .. " -> slot " .. tostring(i) .. " = " .. tostring(found) .. " " .. tostring(rank))
  end
  Print("spec: " .. SpecName() .. " -> using " .. tostring(MainStrike()))
  do
    local v, src, a, b, raw = WarSlamSlamFrac()
    if src == "talent" then
      Print(string.format("Slam window: auto = %.2f (Improved Slam %d -> %.1fs base cast / weapon %.2f = %.3f, rounded down)",
        v, impSlam or 0, a, b, raw))
    elseif src == "measured" then
      Print(string.format("Slam window: auto = %.2f (last Slam %.2fs / swing %.2fs = %.3f, rounded down)", v, a, b, raw))
    elseif src == "start" then
      Print(string.format("Slam window: auto = %.2f (weapon speed unknown, starting value)", v))
    else
      Print(string.format("Slam window: %.2f (fixed)", v))
    end
    local m, mc, ms = WarSlamSlamMeasured()
    if m then
      local line = string.format("last real Slam: %.2fs / swing %.2fs = %.3f", mc, ms, m)
      if src == "talent" and math.abs(m - raw) > 0.02 then
        line = line .. string.format(" |cffff4040differs from the talent formula (%.3f)|r", raw)
      end
      Print(line)
    end
  end
  Print(string.format("weapon: %s, base speed %s -> %s weapon rotation (setting: %s)",
    tostring(weapon.name), tostring(weapon.speed), SlowWeapon() and "slow" or "fast", tostring(CFG.SLOW_WEAPON)))
  Print("Sunder (" .. (CFG.USE_SUNDER and "on" or "off") .. "): " .. WarSlamSunderStatus())
  Print(string.format("Battle Shout (%s): %s, refresh at %ds left", CFG.USE_SHOUT and "on" or "off",
    (ShoutTimeLeft() > 0) and string.format("%.0fs left", ShoutTimeLeft()) or "missing", CFG.SHOUT_REFRESH))
  Print("st_timer = " .. tostring(st_timer) .. ", attack speed = " .. tostring(UnitAttackSpeed("player")))
  Print("ST: Heroic Strike at " .. MODES.ST.dumpAt .. " rage | MT: Cleave at " .. MODES.MT.dumpAt .. " rage")
  if NPInstalled() then
    Print(string.format("Nampower: installed, queuing %s (queue lead %.2fs, NP window %s ms, cast-time %s, instant %s)",
      CFG.USE_NAMPOWER and "ON" or "OFF", NPWindow(), tostring(NPCVar("NP_SpellQueueWindowMs")),
      tostring(NPCVar("NP_QueueCastTimeSpells")), tostring(NPCVar("NP_QueueInstantSpells"))))
  else
    Print("Nampower: not installed (normal mode)")
  end
end
