-- NeatRows by Methl (Vanilla 1.12 / Turtle WoW)
-- Main: init, events, state, helpers, slash commands

NeatRows = NeatRows or {}

-- Global helper used by NeatRows_UI
function NR_Clamp(v, mn, mx)
  if v < mn then return mn end
  if v > mx then return mx end
  return v
end

local DB_DEFAULTS = {
  pos          = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
  size         = { w = 760, h = 560 },
  buttonSize   = 36,
  padding      = 6,
  maxTabsPerRow = 6,
  showEmptyTabs = false,
  lockFrame    = false,
}

NeatRows.state = {
  sortMode          = "QUALITY",
  search            = "",
  tabKey            = "ALL",
  tabOrder          = {},
  visibleCategories = {},
  items             = {},
  refreshPending    = false,
}

-- ------------------------------------------------------------------ helpers --

function NeatRows:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff44bbffNeatRows|r: " .. tostring(msg))
end

function NeatRows:SaveFramePosition()
  if not self.frame then return end
  local point, _, relPoint, x, y = self.frame:GetPoint()
  self.db.pos.point    = point    or "CENTER"
  self.db.pos.relPoint = relPoint or "CENTER"
  self.db.pos.x        = x        or 0
  self.db.pos.y        = y        or 0
end

function NeatRows:SaveFrameSize()
  if not self.frame then return end
  self.db.size.w = self.frame:GetWidth()
  self.db.size.h = self.frame:GetHeight()
end

-- ------------------------------------------------------------------- state --

function NeatRows:SetSearch(text)
  self.state.search = text or ""
  self:QueueRefresh("search")
end

function NeatRows:SetSortMode(mode)
  self.state.sortMode = mode or "QUALITY"
  self:QueueRefresh("sort")
end

function NeatRows:SetActiveTab(key)
  self.state.tabKey = key or "ALL"
  NeatRows_UI:SetActiveTab(self, key)
end

-- ------------------------------------------------------------------ refresh --

function NeatRows:QueueRefresh(reason)
  if self.state.refreshPending then return end
  self.state.refreshPending = true
  self.frame:SetScript("OnUpdate", function()
    NeatRows.frame:SetScript("OnUpdate", nil)
    NeatRows.state.refreshPending = false
    NeatRows:Refresh()
  end)
end

function NeatRows:Refresh()
  if not self.frame or not self.frame:IsShown() then return end

  local items = NeatRows_Data:ScanBags()
  self.state.items = items

  NeatRows_UI:RebuildTabList(self, items)
  NeatRows_UI:SetActiveTab(self, self.state.tabKey, true)

  local filtered = NeatRows_SortFilter:ApplySearch(items, self.state.search, self.state.tabKey)
  NeatRows_SortFilter:ApplySort(filtered, self.state.sortMode)
  NeatRows_UI:LayoutGrid(self, filtered)

  if self.ui and self.ui.moneyDisplay then
    NeatRows_UI:UpdateMoneyDisplay(self.ui.moneyDisplay, GetMoney and GetMoney() or 0)
  end
end

-- ------------------------------------------------------------------- toggle --

function NeatRows:Toggle()
  if not self.frame then return end
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

-- -------------------------------------------------------------------- init --

local function ApplyDefaults(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      if type(v) == "table" then
        dst[k] = {}
        ApplyDefaults(dst[k], v)
      else
        dst[k] = v
      end
    elseif type(v) == "table" and type(dst[k]) == "table" then
      ApplyDefaults(dst[k], v)
    end
  end
end

function NeatRows:OnLoad()
  NeatRowsDB = NeatRowsDB or {}
  ApplyDefaults(NeatRowsDB, DB_DEFAULTS)
  self.db = NeatRowsDB

  self:CreateMainFrame()
  self:Print("Loaded. Type /nr to open.")
end

-- ------------------------------------------------------------------ events --

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_MONEY")

eventFrame:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    NeatRows:OnLoad()
  elseif event == "BAG_UPDATE" then
    if NeatRows.frame and NeatRows.frame:IsShown() then
      NeatRows:QueueRefresh("bag")
    end
  elseif event == "PLAYER_MONEY" then
    if NeatRows.ui and NeatRows.ui.moneyDisplay then
      NeatRows_UI:UpdateMoneyDisplay(NeatRows.ui.moneyDisplay, GetMoney and GetMoney() or 0)
    end
  end
end)

-- ------------------------------------------------------------------ slash ---

SLASH_NEATROWS1 = "/nr"
SLASH_NEATROWS2 = "/neatrows"
SlashCmdList["NEATROWS"] = function(msg)
  NeatRows:Toggle()
end

-- --------------------------------------------------------- bag key hooks ---
-- Hook OpenAllBags / CloseAllBags so pressing B opens/closes NeatRows
-- instead of the default bag frames (Vanilla 1.12 compatible).

function OpenAllBags()
  if NeatRows.frame then
    NeatRows.frame:Show()
  end
end

function CloseAllBags()
  if NeatRows.frame then
    NeatRows.frame:Hide()
  end
end

-- ToggleBag is called when a bag-bar slot is clicked; route it through
-- NeatRows:Toggle() so the custom frame opens/closes as expected.
-- The bag id parameter is intentionally ignored; we manage a single window.
function ToggleBag()
  if NeatRows.frame then
    NeatRows:Toggle()
  end
end
