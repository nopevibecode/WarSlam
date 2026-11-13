-- WarSlamUI: settings window for WarSlam
-- Open with /warslam config. Values are saved in SavedVariables (WarSlamSettings).

local CFG   = WarSlamConfig
local MODES = WarSlamModes

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff8800WarSlam:|r " .. msg)
end

------------------------------------------------------------------------
-- Settings persistence
--   WarSlamSettings          = current settings (+ minimap position)
--   WarSlamSettings.profiles = { [name] = { settings } }
--   WarSlamSettings.weapons  = { [main hand item id] = profile name }
------------------------------------------------------------------------
-- settings that belong to a profile
local PROFILE_KEYS = { "SLAM_FRAC", "GCD_SLACK", "CAST_LOCK", "USE_SUNDER", "USE_SHOUT",
  "OPENER", "OPENER_ANY", "SLOW_WEAPON", "PVP_BASIC", "ST_DUMP", "MT_DUMP", "USE_NAMPOWER", "NP_LEAD",
  "PAIR_STRIKES", "PAIR_RAGE", "PAIR_HS_AT", "SUNDER_ANY", "SUNDER_BUILD_GCD", "DW_JUJU", "DW_JUJU_DELAY",
  "USE_OVERPOWER", "OP_RAGE_LOSS", "OP_STAY_BATTLE", "OP_TAKE_BLOCKED" }
local OTHER_KEYS = { "MINIMAP_SHOW", "MINIMAP_ANGLE" }

local function Get(k)
  if k == "ST_DUMP" then return MODES.ST.dumpAt end
  if k == "MT_DUMP" then return MODES.MT.dumpAt end
  return CFG[k]
end
local function Set(k, v)
  if v == nil then return end
  if k == "ST_DUMP" then MODES.ST.dumpAt = v
  elseif k == "MT_DUMP" then MODES.MT.dumpAt = v
  else CFG[k] = v end
end

-- defaults = whatever WarSlam.lua ships with
local DEFAULTS = {}
for i = 1, table.getn(PROFILE_KEYS) do DEFAULTS[PROFILE_KEYS[i]] = Get(PROFILE_KEYS[i]) end
for i = 1, table.getn(OTHER_KEYS) do DEFAULTS[OTHER_KEYS[i]] = Get(OTHER_KEYS[i]) end

local function Apply(t, keys)
  keys = keys or PROFILE_KEYS
  for i = 1, table.getn(keys) do Set(keys[i], t[keys[i]]) end
end

local function Snapshot()
  local t = {}
  for i = 1, table.getn(PROFILE_KEYS) do t[PROFILE_KEYS[i]] = Get(PROFILE_KEYS[i]) end
  return t
end

local function Save()
  if type(WarSlamSettings) ~= "table" then WarSlamSettings = {} end
  for i = 1, table.getn(PROFILE_KEYS) do WarSlamSettings[PROFILE_KEYS[i]] = Get(PROFILE_KEYS[i]) end
  for i = 1, table.getn(OTHER_KEYS) do WarSlamSettings[OTHER_KEYS[i]] = Get(OTHER_KEYS[i]) end
  if type(WarSlamSettings.profiles) ~= "table" then WarSlamSettings.profiles = {} end
  if type(WarSlamSettings.weapons) ~= "table" then WarSlamSettings.weapons = {} end
end

------------------------------------------------------------------------
-- Profiles
------------------------------------------------------------------------
local selectedProfile = nil   -- shown in the profile list
local frame                    -- the settings window (built on first open)

local function ProfileNames()
  local names = {}
  for n in pairs(WarSlamSettings.profiles) do table.insert(names, n) end
  table.sort(names)
  return names
end

function WarSlamProfileSave(name)
  if not name or name == "" then Print("type a profile name first") return end
  WarSlamSettings.profiles[name] = Snapshot()
  WarSlamSettings.active = name
  selectedProfile = name
  Print("profile '" .. name .. "' saved")
end

function WarSlamProfileLoad(name, why)
  local p = name and WarSlamSettings.profiles[name]
  if not p then Print("no profile '" .. tostring(name) .. "'") return end
  Apply(p)
  WarSlamSettings.active = name
  selectedProfile = name
  Save()
  if WarSlamUpdateEvents then WarSlamUpdateEvents() end
  if frame and frame:IsShown() and frame.RefreshAll then frame.RefreshAll() end
  Print("profile '" .. name .. "' loaded" .. (why or ""))
end

function WarSlamProfileDelete(name)
  if not name or not WarSlamSettings.profiles[name] then return end
  WarSlamSettings.profiles[name] = nil
  for id, n in pairs(WarSlamSettings.weapons) do
    if n == name then WarSlamSettings.weapons[id] = nil end
  end
  if WarSlamSettings.active == name then WarSlamSettings.active = nil end
  if selectedProfile == name then selectedProfile = nil end
  Print("profile '" .. name .. "' deleted")
end

-- link a profile to the main hand you have equipped now
function WarSlamProfileLink(name)
  local _, wname, wid = WarSlamWeapon()
  if not wid then Print("no main hand weapon equipped") return end
  if not name or not WarSlamSettings.profiles[name] then Print("select or save a profile first") return end
  WarSlamSettings.weapons[wid] = name
  Print("'" .. tostring(wname) .. "' now loads profile '" .. name .. "'")
end

function WarSlamProfileUnlink()
  local _, wname, wid = WarSlamWeapon()
  if wid and WarSlamSettings.weapons[wid] then
    WarSlamSettings.weapons[wid] = nil
    Print("'" .. tostring(wname) .. "' is no longer linked to a profile")
  end
end

-- Base profiles: simulated best settings for common 2H speeds (Flurry + ~6% haste).
-- Created once, from your current settings, with these changes:
local BASE_PROFILES = {
  -- Slow weapon rotation "auto": 3.40 / 3.50 are fast weapons (Slam trade, BT + WW pair),
  -- 3.60 / 3.80 slow ones
  ["Base 3.40"] = { speed = 3.40, SLAM_FRAC = 0.60,   SLOW_WEAPON = "auto" },  -- Auto window would cost 2-4 strikes/min here
  ["Base 3.50"] = { speed = 3.50, SLAM_FRAC = "auto", SLOW_WEAPON = "auto" },
  ["Base 3.60"] = { speed = 3.60, SLAM_FRAC = "auto", SLOW_WEAPON = "auto" },
  ["Base 3.80"] = { speed = 3.80, SLAM_FRAC = "auto", SLOW_WEAPON = "auto" },
}

local function CreateBaseProfiles()
  local v = WarSlamSettings.baseProfiles
  if not v then
    for name, b in pairs(BASE_PROFILES) do
      if not WarSlamSettings.profiles[name] then
        local p = Snapshot()
        p.SLAM_FRAC, p.SLOW_WEAPON = b.SLAM_FRAC, b.SLOW_WEAPON
        WarSlamSettings.profiles[name] = p
      end
    end
  elseif v < 2 then
    -- version 1 forced "Slow weapon rotation = Yes" in every base profile, which
    -- switched off the fast weapon rules (trade, BT + WW pair) for 3.40 / 3.50
    for name in pairs(BASE_PROFILES) do
      local p = WarSlamSettings.profiles[name]
      if p and p.SLOW_WEAPON == "yes" then p.SLOW_WEAPON = "auto" end
    end
    local act = WarSlamSettings.active
    if act and BASE_PROFILES[act] and CFG.SLOW_WEAPON == "yes" then
      CFG.SLOW_WEAPON = "auto"
      Save()
    end
  end
  WarSlamSettings.baseProfiles = 2
end

-- base profile for a weapon speed, if one exists (and still exists)
local function BaseProfileFor(speed)
  if not speed then return nil end
  for name, b in pairs(BASE_PROFILES) do
    if math.abs(b.speed - speed) < 0.005 and WarSlamSettings.profiles[name] then return name end
  end
  return nil
end

-- called by WarSlam.lua when the main hand changes
function WarSlamOnWeaponChanged(id, name, speed)
  if not (WarSlamSettings and WarSlamSettings.weapons) then return end
  local p = id and WarSlamSettings.weapons[id]
  if not p then p = BaseProfileFor(speed) end   -- no link: the base profile for its speed
  if p and WarSlamSettings.profiles[p] and WarSlamSettings.active ~= p then
    WarSlamProfileLoad(p, " for " .. tostring(name))
  end
  if frame and frame:IsShown() and frame.RefreshAll then frame.RefreshAll() end
end

------------------------------------------------------------------------
-- Nampower CVars (saved by the game itself in Config.wtf)
------------------------------------------------------------------------
local function NPInstalled()
  return WarSlamNampower and WarSlamNampower.installed()
end

local function GetNP(name)
  local ok, v = pcall(GetCVar, name)
  if ok then return v end
  return nil
end

local function SetNP(name, value)
  if not NPInstalled() then return end
  local ok = pcall(SetCVar, name, tostring(value))
  if not ok then Print("could not set " .. name) end
end

-- what WarSlam works best with
local NP_RECOMMENDED = {
  NP_QueueCastTimeSpells   = "1",
  NP_QueueInstantSpells    = "1",
  NP_QueueSpellsOnCooldown = "1",
  NP_QueueOnSwingSpells    = "0",  -- WarSlam handles Heroic Strike / Cleave itself
  NP_SpellQueueWindowMs    = "300",
}

local loader = CreateFrame("Frame")
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function()
  if event ~= "VARIABLES_LOADED" then return end
  if type(WarSlamSettings) == "table" then
    -- older versions had an on/off trade switch
    if WarSlamSettings.SLOW_WEAPON == nil and WarSlamSettings.TRADE_SLAM == false then
      WarSlamSettings.SLOW_WEAPON = "yes"
    end
    WarSlamSettings.TRADE_SLAM = nil
    Apply(WarSlamSettings, PROFILE_KEYS)
    Apply(WarSlamSettings, OTHER_KEYS)
  end
  Save()
  CreateBaseProfiles()
  if WarSlamUI_CreateMinimap then WarSlamUI_CreateMinimap() end
  if WarSlamUpdateEvents then WarSlamUpdateEvents() end
end)

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------
local widgets = {}
local refreshing = false
local cur            -- the tab page widgets are being created on
local currentTab = 1 -- remembered while the game runs

local function Round(v, step)
  return math.floor(v / step + 0.5) * step
end

local function Tip(w, tip)
  if not tip then return end
  w:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(tip, 1, 1, 1, 1, 1)
    GameTooltip:Show()
  end)
  w:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function MakeSlider(key, label, minV, maxV, step, fmt, x, y, get, set, tip)
  local name = "WarSlamUISlider" .. key
  local s = CreateFrame("Slider", name, cur, "OptionsSliderTemplate")
  s:SetWidth(240)
  s:SetHeight(16)
  s:SetPoint("TOPLEFT", cur, "TOPLEFT", x, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  getglobal(name .. "Low"):SetText(string.format(fmt, minV))
  getglobal(name .. "High"):SetText(string.format(fmt, maxV))
  local text = getglobal(name .. "Text")
  s.Refresh = function()
    local v = get()
    refreshing = true
    if type(v) == "number" then s:SetValue(v) end
    refreshing = false
    if type(v) == "number" then
      text:SetText(label .. ": |cffffffff" .. string.format(fmt, v) .. "|r")
    else
      text:SetText(label .. ": |cffffffff" .. tostring(v) .. "|r")
    end
  end
  s:SetScript("OnValueChanged", function()
    if refreshing then return end
    local v = Round(this:GetValue(), step)
    set(v)
    Save()
    text:SetText(label .. ": |cffffffff" .. string.format(fmt, v) .. "|r")
  end)
  Tip(s, tip)
  table.insert(widgets, s)
  return s
end

local function MakeCheck(key, label, x, y, get, set, tip)
  local name = "WarSlamUICheck" .. key
  local c = CreateFrame("CheckButton", name, cur, "UICheckButtonTemplate")
  c:SetWidth(24)
  c:SetHeight(24)
  c:SetPoint("TOPLEFT", cur, "TOPLEFT", x, y)
  getglobal(name .. "Text"):SetText(label)
  c.Refresh = function()
    if get() then c:SetChecked(1) else c:SetChecked(nil) end
  end
  c:SetScript("OnClick", function()
    set(this:GetChecked() and true or false)
    Save()
    if frame.RefreshAll then frame.RefreshAll() end
  end)
  Tip(c, tip)
  table.insert(widgets, c)
  return c
end

-- options: list of { value =, text = } or a function returning one
local function MakeDropdown(key, x, y, width, options, get, set)
  local name = "WarSlamUIDrop" .. key
  local dd = CreateFrame("Frame", name, cur, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", cur, "TOPLEFT", x - 16, y)
  UIDropDownMenu_SetWidth(width, dd)
  local function List() if type(options) == "function" then return options() end return options end
  UIDropDownMenu_Initialize(dd, function()
    local list = List()
    for i = 1, table.getn(list) do
      local info = {}
      info.text = list[i].text
      info.value = list[i].value
      info.checked = (get() == list[i].value)
      info.func = function()
        set(this.value)
        if frame.RefreshAll then frame.RefreshAll() end
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  dd.Refresh = function()
    local v, list, txt = get(), List(), "-"
    for i = 1, table.getn(list) do if list[i].value == v then txt = list[i].text end end
    dd.selectedValue = v
    UIDropDownMenu_SetText(txt, dd)
  end
  table.insert(widgets, dd)
  return dd
end

local function MakeButton(name, text, x, y, width, onClick, tip)
  local b = CreateFrame("Button", name, cur, "UIPanelButtonTemplate")
  b:SetWidth(width)
  b:SetHeight(22)
  b:SetPoint("TOPLEFT", cur, "TOPLEFT", x, y)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  Tip(b, tip)
  return b
end

local function Label(x, y, font, width)
  local t = cur:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT", cur, "TOPLEFT", x, y)
  if width then t:SetWidth(width) t:SetJustifyH("LEFT") end
  return t
end

-- section title inside a tab
local function Head(x, y, text)
  local t = Label(x - 4, y, "GameFontNormal")
  t:SetText(text)
  return t
end

local W, H = 600, 560
local C1, C2 = 30, 315       -- the two columns of every tab
local TOP = -112             -- where tab content starts

local function Build()
  frame = CreateFrame("Frame", "WarSlamUIFrame", UIParent)
  frame:SetWidth(W)
  frame:SetHeight(H)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:SetFrameStrata("DIALOG")
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:Hide()
  table.insert(UISpecialFrames, "WarSlamUIFrame") -- Esc closes it
  -- while open, keep the live values (Auto Slam window, weapon) up to date
  local tick = 0
  frame:SetScript("OnUpdate", function()
    tick = tick + (arg1 or 0)
    if tick < 0.5 then return end
    tick = 0
    if frame.RefreshAuto then frame.RefreshAuto() end
    if frame.RefreshHeader then frame.RefreshHeader() end
    if frame.RefreshHsCost then frame.RefreshHsCost() end
  end)

  cur = frame
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -18)
  title:SetText("WarSlam")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

  ----------------------------------------------------------------------
  -- Header, on every tab: profile and weapon
  ----------------------------------------------------------------------
  local hProfile = Label(C1, -42, "GameFontHighlightSmall", W - 60)
  local hWeapon = Label(C1, -58, "GameFontHighlightSmall", W - 60)
  frame.RefreshHeader = function()
    local sp, wname, wid = WarSlamWeapon()
    local linked = wid and WarSlamSettings.weapons[wid]
    local base = not linked and BaseProfileFor(sp)
    local how = linked and "|cff20ff20linked to this weapon|r"
      or (base and ("|cffffd000" .. base .. " by speed|r")) or "|cff888888not linked|r"
    hProfile:SetText("Profile: |cffffffff" .. tostring(WarSlamSettings.active or "none") .. "|r  (" .. how .. ")")
    local slow = WarSlamSlowWeapon()
    hWeapon:SetText("Weapon: |cffffffff" .. tostring(wname or "none") .. "|r" ..
      (sp and string.format(" %.2f", sp) or "") .. "  -  " ..
      (slow and "|cff20ff20slow weapon rotation|r" or "|cffffd000fast weapon rotation|r"))
  end

  ----------------------------------------------------------------------
  -- Tabs
  ----------------------------------------------------------------------
  local TABS = { "Rotation", "Advanced", "Profiles & Tools" }
  local pages, tabButtons = {}, {}
  local function ShowTab(n)
    currentTab = n
    for i = 1, table.getn(pages) do
      if i == n then
        pages[i]:Show()
        tabButtons[i]:LockHighlight()    -- the selected tab stays lit
        tabButtons[i]:SetAlpha(1)
      else
        pages[i]:Hide()
        tabButtons[i]:UnlockHighlight()
        tabButtons[i]:SetAlpha(0.75)
      end
    end
  end
  frame.ShowTab = ShowTab
  local tw = 170
  for i = 1, table.getn(TABS) do
    local b = CreateFrame("Button", "WarSlamUITab" .. i, frame, "UIPanelButtonTemplate")
    b:SetWidth(tw)
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", frame, "TOPLEFT", C1 - 6 + (i - 1) * (tw + 8), -78)
    b:SetText(TABS[i])
    b.tab = i
    b:SetScript("OnClick", function() ShowTab(this.tab) end)
    tabButtons[i] = b
    local page = CreateFrame("Frame", nil, frame)
    page:SetAllPoints(frame)
    page:Hide()
    pages[i] = page
  end
  local line = frame:CreateTexture(nil, "ARTWORK")
  line:SetTexture(1, 1, 1, 0.15)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -106)
  line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -106)

  ----------------------------------------------------------------------
  -- Tab 1: Rotation (what you change per weapon or per fight)
  ----------------------------------------------------------------------
  cur = pages[1]
  local y = TOP

  Head(C1, y, "Slam")
  local slamSlider = MakeSlider("SlamFrac", "Slam window (swing left)", 0.40, 0.80, 0.01, "%.2f", C1, y - 26,
    function()
      if CFG.SLAM_FRAC == "auto" then return (WarSlamSlamFrac()) end   -- the value Auto uses now
      return CFG.SLAM_FRAC
    end,
    function(v) CFG.SLAM_FRAC = v end)
  local autoCheck = MakeCheck("SlamAuto", "Auto (Slam cast / weapon speed)", C1 - 4, y - 60,
    function() return CFG.SLAM_FRAC == "auto" end,
    function(on)
      if on then CFG.SLAM_FRAC = "auto" else CFG.SLAM_FRAC = Round(slamSlider:GetValue(), 0.01) end
    end,
    "Slam cast time (from your Improved Slam talent) divided\nby your weapon speed, rounded down to 0.05.")
  -- under the Auto box: what Auto is using right now
  local autoInfo = Label(C1 + 4, y - 84, "GameFontHighlightSmall", 260)
  frame.RefreshAuto = function()
    if CFG.SLAM_FRAC ~= "auto" then autoInfo:SetText("") return end
    local v, src, a, b, raw = WarSlamSlamFrac()
    local txt
    if src == "talent" then
      txt = string.format("Auto = %.2f  (%.1fs Slam / %.2f weapon = %.3f)", v, a, b, raw)
      local m = WarSlamSlamMeasured()
      if m and math.abs(m - raw) > 0.02 then
        txt = txt .. string.format(" |cffff4040last Slam: %.3f|r", m)
      end
    elseif src == "measured" then
      txt = string.format("Auto = %.2f  (last Slam %.2fs / %.2fs = %.3f)", v, a, b, raw)
    else
      txt = string.format("Auto = %.2f  (weapon speed unknown)", v)
    end
    autoInfo:SetText(txt)
  end

  y = y - 116
  Head(C1, y, "Rage dump")
  MakeSlider("StDump", "Heroic Strike at rage", 30, 100, 1, "%d", C1, y - 26,
    function() return MODES.ST.dumpAt end,
    function(v) MODES.ST.dumpAt = v end)
  MakeSlider("MtDump", "Cleave at rage", 20, 100, 1, "%d", C1, y - 74,
    function() return MODES.MT.dumpAt end,
    function(v) MODES.MT.dumpAt = v end)
  -- Heroic Strike cost: read from the Improved Heroic Strike talent
  local hsCostLabel = Label(C1, y - 102, "GameFontHighlightSmall", 260)
  frame.RefreshHsCost = function()
    local cost, pts = WarSlamHsCost()
    hsCostLabel:SetText(string.format("Heroic Strike cost: |cffffd000%d rage|r (Improved Heroic Strike %d/3)", cost, pts or 0))
  end

  y = y - 132
  Head(C1, y, "Cooldowns")
  MakeCheck("Juju", "Juju Flurry after Death Wish", C1 - 4, y - 20,
    function() return CFG.DW_JUJU end,
    function(on) CFG.DW_JUJU = on end,
    "After a Death Wish armed with /run WarSlamDW(), the next\nWarSlam press past the delay uses a Juju Flurry from your\nbags on you. Skipped if you have none. It can't be used\nduring a Slam cast, so it may come a little after the delay.")
  MakeSlider("JujuDelay", "Juju Flurry delay (s)", 5, 15, 1, "%d", C1, y - 64,
    function() return CFG.DW_JUJU_DELAY end,
    function(v) CFG.DW_JUJU_DELAY = v end)
  local dwNote = Label(C1, y - 94, "GameFontDisableSmall", 260)
  dwNote:SetText("Arm Death Wish for the next GCD with /run WarSlamDW()")

  -- right column
  y = TOP
  Head(C2, y, "Fast weapon")
  Label(C2, y - 22, "GameFontNormalSmall"):SetText("Slow weapon rotation")
  MakeDropdown("Slow", C2, y - 36, 150, {
      { value = "auto", text = "Auto (weapon speed)" },
      { value = "yes",  text = "Yes: Slam + GCD" },
      { value = "no",   text = "No: trade a Slam" },
    },
    function() return CFG.SLOW_WEAPON end,
    function(v) CFG.SLOW_WEAPON = v; Save() end)
  MakeCheck("Pair", "Fire BT + WW together", C2 - 4, y - 72,
    function() return CFG.PAIR_STRIKES end,
    function(on) CFG.PAIR_STRIKES = on end,
    "Fast weapons only: when Bloodthirst / Mortal Strike and\nWhirlwind are both up and affordable, fire both for one\nSlam: auto, Slam, BT, auto, WW, auto, Slam (or BT, WW\nright after the auto when both fit before the next Slam).\nRage leeway and Heroic Strike threshold: Advanced tab.")

  y = y - 116
  Head(C2, y, "Buffs & debuffs")
  MakeCheck("Sunder", "Sunder Armor (single target)", C2 - 4, y - 20,
    function() return CFG.USE_SUNDER end,
    function(on) CFG.USE_SUNDER = on; if WarSlamUpdateEvents then WarSlamUpdateEvents() end end,
    "Bosses: build to 5 stacks first (no Slam meanwhile, see\nAdvanced), refresh at 8s left, before everything at 4s.\nOther mobs: only when BT / WW are up but short of rage.\nWith Nampower, everyone's Sunders are tracked.")
  MakeCheck("Shout", "Keep Battle Shout up", C2 - 4, y - 44,
    function() return CFG.USE_SHOUT end,
    function(on) CFG.USE_SHOUT = on end,
    "Battle Shout is the first GCD ability when it's missing\nor has 10s or less left (both buttons).")
  MakeCheck("Opener", "Boss opener: Shout + Sunder", C2 - 4, y - 68,
    function() return CFG.OPENER end,
    function(on) CFG.OPENER = on end,
    "Between the 1st and 2nd auto of a boss fight, no Slam:\nthe GCDs go to Battle Shout (if 60s or less left),\nthen Sunder Armor.")
  MakeCheck("PvP", "PvP: only Slam + BT / MS / WW", C2 - 4, y - 92,
    function() return CFG.PVP_BASIC end,
    function(on) CFG.PVP_BASIC = on end,
    "In a battleground, or when your target is an enemy player:\nno Battle Shout, no Sunder, no opener. Just Slam, Bloodthirst /\nMortal Strike, Whirlwind and the Heroic Strike / Cleave dump.")

  y = y - 126
  Head(C2, y, "Overpower")
  MakeCheck("Overpower", "Overpower (stance dance)", C2 - 4, y - 20,
    function() return CFG.USE_OVERPOWER end,
    function(on) CFG.USE_OVERPOWER = on end,
    "After your target dodges: swap to Battle Stance,\nOverpower, swap back to Berserker. Swaps are off the GCD.\nSkipped when a swap would lose more rage than the slider.")
  MakeCheck("OpBlocked", "...even if it costs the next Slam", C2 - 4, y - 44,
    function() return CFG.OP_TAKE_BLOCKED end,
    function(on) CFG.OP_TAKE_BLOCKED = on end,
    "On: Overpower takes the next GCD slot, before BT + WW\npairs, even when that slot costs the next Slam\n(5 rage instead of 15).\nOff: only in slots that cost no Slam, or the Sunder build.")
  MakeSlider("OpLoss", "Rage a swap may lose", 0, 30, 5, "%d", C2, y - 88,
    function() return CFG.OP_RAGE_LOSS end,
    function(v) CFG.OP_RAGE_LOSS = v end,
    "0 = only swap when your rage fits in what Tactical\nMastery keeps (5 per point).")
  MakeCheck("OpStay", "Stay in Battle to spend rage", C2 - 4, y - 116,
    function() return CFG.OP_STAY_BATTLE end,
    function(on) CFG.OP_STAY_BATTLE = on end,
    "Off: back to Berserker right after Overpower,\neven if the swap loses rage.\nOn: stay in Battle to spend the rage first (Slam,\nBT, HS work there), at most 3s, or until WW is due.")
  local tmLabel = Label(C2 + 76, y - 2, "GameFontHighlightSmall", 200)
  frame.RefreshTM = function()
    local kept, pts = WarSlamRageKept()
    tmLabel:SetText(string.format("Tactical Mastery %d/5: keeps |cffffd000%d|r", pts or 0, kept))
  end

  ----------------------------------------------------------------------
  -- Tab 2: Advanced (set once)
  ----------------------------------------------------------------------
  cur = pages[2]
  y = TOP
  Head(C1, y, "Timing")
  MakeSlider("GcdSlack", "GCD slack (s, slow weapons only)", 0, 0.50, 0.05, "%.2f", C1, y - 26,
    function() return CFG.GCD_SLACK end,
    function(v) CFG.GCD_SLACK = v end,
    "How far a GCD may run into the next Slam window.\nFast weapons always use 0. Keep it at 0.")
  MakeSlider("CastLock", "Double-press lock (s)", 0, 1.00, 0.05, "%.2f", C1, y - 74,
    function() return CFG.CAST_LOCK end,
    function(v) CFG.CAST_LOCK = v end)

  y = y - 108
  Head(C1, y, "BT + WW pair")
  MakeSlider("PairRage", "Rage leeway", 0, 40, 5, "%d", C1, y - 26,
    function() return CFG.PAIR_RAGE end,
    function(v) CFG.PAIR_RAGE = v end,
    "How much rage short of both costs a pair may start,\ncounting on the auto in between (capped by what your\nautos really bring, 0 with Heroic Strike queued).")
  MakeSlider("PairHs", "Heroic Strike when a pair is near", 60, 100, 5, "%d", C1, y - 74,
    function() return CFG.PAIR_HS_AT end,
    function(v) CFG.PAIR_HS_AT = v end,
    "When BT and WW come off cooldown within 3s, Heroic\nStrike needs this much rage instead of the usual\nthreshold, so its rage goes to the pair.")

  y = y - 108
  Head(C1, y, "Sunder & opener")
  MakeCheck("SunderBuild", "Sunder build: no Slam", C1 - 4, y - 20,
    function() return CFG.SUNDER_BUILD_GCD end,
    function(on) CFG.SUNDER_BUILD_GCD = on end,
    "Bosses, under 5 Sunders (after the opener): no Slam,\nGCDs back to back: Battle Shout if due, BT / WW when\nready, Sunder in the other slots.")
  MakeCheck("SunderAny", "Boss Sunder rules on all mobs", C1 - 4, y - 44,
    function() return CFG.SUNDER_ANY end,
    function(on) CFG.SUNDER_ANY = on end,
    "On: the boss Sunder rules on every target\n(use it on a training dummy).\nOff: bosses only; other mobs get opportunity Sunders.")
  MakeCheck("OpenerAny", "Opener on every fight", C1 - 4, y - 68,
    function() return CFG.OPENER_ANY end,
    function(on) CFG.OPENER_ANY = on end,
    "Off: only against skull-level (boss) targets.\nTurn on to test the opener on a training dummy.")

  -- right column: Nampower
  y = TOP
  local npTitle = Head(C2, y, "Nampower")
  local npStatus = Label(C2 + 74, y - 2, "GameFontHighlightSmall")

  local npWidgets = {}
  local function NPW(w) table.insert(npWidgets, w); return w end

  NPW(MakeCheck("UseNP", "Use Nampower queuing", C2 - 4, y - 20,
    function() return CFG.USE_NAMPOWER end,
    function(on) CFG.USE_NAMPOWER = on end,
    "WarSlam sends the next spell just before the current\nSlam cast or GCD ends, so Nampower queues it."))
  NPW(MakeSlider("NpLead", "WarSlam queue lead (s)", 0.05, 2.00, 0.05, "%.2f", C2, y - 64,
    function() return CFG.NP_LEAD end,
    function(v) CFG.NP_LEAD = v end))
  NPW(MakeSlider("NpWindow", "Nampower queue window (ms)", 100, 2000, 50, "%d", C2, y - 112,
    function() return tonumber(GetNP("NP_SpellQueueWindowMs")) or 500 end,
    function(v) SetNP("NP_SpellQueueWindowMs", v) end))

  local function NPCheck(key, cvar, label, yy, tip)
    return NPW(MakeCheck(key, label, C2 - 4, yy,
      function() return GetNP(cvar) == "1" end,
      function(on) SetNP(cvar, on and 1 or 0) end, tip))
  end
  NPCheck("NpCast", "NP_QueueCastTimeSpells", "Queue cast-time spells (Slam)", y - 142)
  NPCheck("NpInstant", "NP_QueueInstantSpells", "Queue instant spells (BT / MS / WW)", y - 166)
  NPCheck("NpCooldown", "NP_QueueSpellsOnCooldown", "Queue spells coming off cooldown", y - 190)
  NPCheck("NpSwing", "NP_QueueOnSwingSpells", "Queue on-swing spells (HS / Cleave)", y - 214,
    "Leave off: WarSlam already queues Heroic Strike / Cleave\nonce per swing.")

  local rec = MakeButton("WarSlamUINpRecommended", "Recommended", C2, y - 246, 150,
    function()
      for k, v in pairs(NP_RECOMMENDED) do SetNP(k, v) end
      CFG.USE_NAMPOWER = true
      Save()
      frame.RefreshAll()
      Print("Nampower set to recommended values")
    end,
    "Cast-time, instant and off-cooldown queuing on,\non-swing queuing off, queue window 300 ms.\nThese are Nampower settings: they apply to all\nyour spells, not only WarSlam.")
  local npNote = Label(C2, y - 276, "GameFontDisableSmall", 240)
  npNote:SetText("Nampower settings are saved by the game, apply to all your spells, and aren't part of profiles.")

  frame.RefreshNP = function()
    local inst = NPInstalled()
    if inst then
      npStatus:SetText("|cff20ff20installed|r")
    else
      npStatus:SetText("|cffff2020not installed|r")
    end
    for i = 1, table.getn(npWidgets) do
      npWidgets[i]:EnableMouse(inst and true or false)
      npWidgets[i]:SetAlpha(inst and 1 or 0.4)
    end
    rec:EnableMouse(inst and true or false)
    rec:SetAlpha(inst and 1 or 0.4)
  end

  ----------------------------------------------------------------------
  -- Tab 3: Profiles & Tools
  ----------------------------------------------------------------------
  cur = pages[3]
  y = TOP
  Head(C1, y, "Profiles")
  Label(C1, y - 22, "GameFontNormalSmall"):SetText("Saved profiles")
  MakeDropdown("Profile", C1, y - 34, 160,
    function()
      local list = {}
      local names = ProfileNames()
      for i = 1, table.getn(names) do table.insert(list, { value = names[i], text = names[i] }) end
      if table.getn(list) == 0 then table.insert(list, { value = "__none", text = "(none yet)" }) end
      return list
    end,
    function() return selectedProfile or "__none" end,
    function(v) if v ~= "__none" then selectedProfile = v end end)

  MakeButton("WarSlamUIProfLoad", "Load", C1, y - 70, 80,
    function() WarSlamProfileLoad(selectedProfile); frame.RefreshAll() end,
    "Load the selected profile into the settings.")
  MakeButton("WarSlamUIProfDelete", "Delete", C1 + 88, y - 70, 80,
    function() WarSlamProfileDelete(selectedProfile); frame.RefreshAll() end)

  Label(C1, y - 102, "GameFontNormalSmall"):SetText("Save current settings as")
  local nameBox = CreateFrame("EditBox", "WarSlamUIProfileName", cur, "InputBoxTemplate")
  nameBox:SetWidth(160)
  nameBox:SetHeight(20)
  nameBox:SetPoint("TOPLEFT", cur, "TOPLEFT", C1 + 6, y - 116)
  nameBox:SetAutoFocus(false)
  nameBox:SetMaxLetters(24)
  local function SaveFromBox()
    local n = nameBox:GetText()
    if n and n ~= "" then
      WarSlamProfileSave(n)
      nameBox:SetText("")
      nameBox:ClearFocus()
      frame.RefreshAll()
    else
      Print("type a profile name first")
    end
  end
  nameBox:SetScript("OnEnterPressed", SaveFromBox)
  nameBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  MakeButton("WarSlamUIProfSave", "Save", C1 + 176, y - 115, 70, SaveFromBox,
    "Save all current settings under this name.\nSaving under an existing name updates it.")

  MakeButton("WarSlamUIProfLink", "Link to this weapon", C1, y - 152, 150,
    function() WarSlamProfileLink(selectedProfile); frame.RefreshAll() end,
    "Link the selected profile to the main hand you have\nequipped now. Equipping it later loads the profile.")
  MakeButton("WarSlamUIProfUnlink", "Unlink", C1 + 158, y - 152, 80,
    function() WarSlamProfileUnlink(); frame.RefreshAll() end)

  local pNote = Label(C1, y - 186, "GameFontDisableSmall", 250)
  pNote:SetText("Equipping a linked weapon loads its profile. An unlinked weapon uses the Base profile of its speed (3.40 / 3.50 / 3.60 / 3.80) if there is one.")

  -- right column: test, logs, minimap
  y = TOP
  Head(C2, y, "Strike test")
  local testBtn = MakeButton("WarSlamUITest", "Start 60s test", C2, y - 22, 150,
    function()
      if WarSlamTest.running() then WarSlamTest.finish() else WarSlamTest.start(60) end
      frame.RefreshAll()
    end,
    "Counts Slam + Bloodthirst / Mortal Strike + Whirlwind\nfor 60s from your first strike, with your current\nsettings. /warslam results shows past tests.")

  y = y - 60
  Head(C2, y, "Logs")
  MakeCheck("Log", "Log to file", C2 - 4, y - 20,
    function() return WarSlamLog and WarSlamLog.enabled end,
    function(on) if WarSlamLog then WarSlamLog.enabled = on end end,
    "Written to WTF\\Account\\<account>\\SavedVariables\\WarSlam.lua\non /reload or logout.")
  MakeCheck("Debug", "Debug to chat", C2 - 4, y - 44,
    function() return CFG.DEBUG end,
    function(on) CFG.DEBUG = on end)
  local memText = Label(C2, y - 74, "GameFontHighlightSmall", 250)
  frame.RefreshMem = function() memText:SetText(WarSlamMemInfo and WarSlamMemInfo() or "") end
  MakeButton("WarSlamUIClear", "Clear logs", C2, y - 108, 100,
    function()
      if WarSlamClearLogs then WarSlamClearLogs() end
      frame.RefreshMem()
    end,
    "Empties the decision log and the proc list.\nStrike test results are kept.\nThe file shrinks at your next /reload or logout.")

  y = y - 146
  Head(C2, y, "Minimap")
  MakeCheck("Minimap", "Show the minimap button", C2 - 4, y - 20,
    function() return CFG.MINIMAP_SHOW end,
    function(on)
      if (on and true or false) ~= (CFG.MINIMAP_SHOW and true or false) and WarSlamUI_ToggleMinimap then
        WarSlamUI_ToggleMinimap()
      end
    end,
    "Also: /warslam minimap")

  ----------------------------------------------------------------------
  -- Bottom, on every tab: defaults
  ----------------------------------------------------------------------
  cur = frame
  local reset = CreateFrame("Button", "WarSlamUIReset", frame, "UIPanelButtonTemplate")
  reset:SetWidth(100)
  reset:SetHeight(22)
  reset:SetPoint("BOTTOM", frame, "BOTTOM", 0, 18)
  reset:SetText("Defaults")
  Tip(reset, "Resets WarSlam's own settings.\nNampower settings are not changed.")
  reset:SetScript("OnClick", function()
    Apply(DEFAULTS, PROFILE_KEYS)   -- the minimap button stays where it is
    Save()
    if WarSlamUpdateEvents then WarSlamUpdateEvents() end
    frame.RefreshAll()
    Print("settings reset to defaults")
  end)

  frame.RefreshAll = function()
    for i = 1, table.getn(widgets) do widgets[i].Refresh() end
    frame.RefreshNP()
    frame.RefreshMem()
    frame.RefreshHeader()
    frame.RefreshHsCost()
    frame.RefreshTM()
    frame.RefreshAuto()
    if WarSlamTest.running() then testBtn:SetText("Stop test") else testBtn:SetText("Start 60s test") end
    -- grey out the slider while Auto is on
    if CFG.SLAM_FRAC == "auto" then
      slamSlider:EnableMouse(false)
      slamSlider:SetAlpha(0.4)
    else
      slamSlider:EnableMouse(true)
      slamSlider:SetAlpha(1)
    end
  end

  ShowTab(currentTab)
end

function WarSlamUI_Toggle()
  if not frame then Build() end
  if frame:IsShown() then
    frame:Hide()
  else
    frame.RefreshAll()
    frame:Show()
  end
end

------------------------------------------------------------------------
-- Minimap button: click = settings window, drag = move around the minimap
------------------------------------------------------------------------
local mm
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function PlaceMinimap()
  local a = math.rad(CFG.MINIMAP_ANGLE or 225)
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
end

function WarSlamUI_CreateMinimap()
  if mm then return end
  mm = CreateFrame("Button", "WarSlamMinimapButton", Minimap)
  mm:SetWidth(31)
  mm:SetHeight(31)
  mm:SetFrameStrata("MEDIUM")
  mm:SetFrameLevel(8)
  mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = mm:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\Ability_Warrior_DecisiveStrike") -- the Slam icon
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("TOPLEFT", mm, "TOPLEFT", 6, -5)

  local border = mm:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(53)
  border:SetHeight(53)
  border:SetPoint("TOPLEFT", mm, "TOPLEFT", 0, 0)

  mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  mm:RegisterForDrag("LeftButton")
  mm:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      if SlashCmdList and SlashCmdList["WARSLAM"] then SlashCmdList["WARSLAM"]("") end
    else
      WarSlamUI_Toggle()
    end
  end)
  mm:SetScript("OnDragStart", function()
    this:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      px, py = px / scale, py / scale
      CFG.MINIMAP_ANGLE = math.deg(atan2(py - my, px - mx))
      PlaceMinimap()
    end)
  end)
  mm:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    Save()
  end)
  mm:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("WarSlam")
    GameTooltip:AddLine("Click: settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click: status", 1, 1, 1)
    GameTooltip:AddLine("Drag: move", 1, 1, 1)
    GameTooltip:Show()
  end)
  mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

  PlaceMinimap()
  if CFG.MINIMAP_SHOW then mm:Show() else mm:Hide() end
end

function WarSlamUI_ToggleMinimap()
  if not mm then WarSlamUI_CreateMinimap() end
  CFG.MINIMAP_SHOW = not CFG.MINIMAP_SHOW
  if CFG.MINIMAP_SHOW then mm:Show() else mm:Hide() end
  Save()
  Print("minimap button " .. (CFG.MINIMAP_SHOW and "shown" or "hidden") .. " (/warslam minimap to toggle)")
end
