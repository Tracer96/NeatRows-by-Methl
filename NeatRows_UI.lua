-- NeatRows by Methl (Vanilla 1.12 / Turtle WoW)
-- UI: main frame, toolbar, tabs with wrapping, grid, styling, button pool

NeatRows_UI = NeatRows_UI or {}

local UI = NeatRows_UI

UI.colors = {
  bg = {0.06, 0.06, 0.06, 0.92},
  border = {0.25, 0.25, 0.25, 0.95},
  divider = {1, 1, 1, 0.10},

  tabActiveBorder = {0.85, 0.70, 0.25, 0.95},
  tabInactiveBorder = {0.28, 0.28, 0.28, 0.95},
  tabActiveBg = {0.10, 0.10, 0.10, 0.96},
  tabInactiveBg = {0.08, 0.08, 0.08, 0.92},

  hover = {1, 1, 1, 0.20},
}

function UI:ApplyBackdrop(frame, bgAlpha)
  if not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  local a = bgAlpha or UI.colors.bg[4]
  frame:SetBackdropColor(UI.colors.bg[1], UI.colors.bg[2], UI.colors.bg[3], a)
  frame:SetBackdropBorderColor(UI.colors.border[1], UI.colors.border[2], UI.colors.border[3], UI.colors.border[4])
end

function UI:CreateDivider(parent)
  local tex = parent:CreateTexture(nil, "ARTWORK")
  tex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Separator")
  tex:SetHeight(8)
  tex:SetTexCoord(0, 1, 0, 1)
  tex:SetVertexColor(1, 1, 1, 0.55)
  return tex
end

function UI:FormatMoney(money)
  money = money or 0
  local gold = floor(money / (100 * 100))
  local silver = floor((money - gold * 100 * 100) / 100)
  local copper = money - gold * 100 * 100 - silver * 100

  if gold > 0 then
    return string.format("%dg %ds %dc", gold, silver, copper)
  elseif silver > 0 then
    return string.format("%ds %dc", silver, copper)
  else
    return string.format("%dc", copper)
  end
end

local function CreateShadowedText(parent, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template)
  fs:SetShadowColor(0, 0, 0, 0.85)
  fs:SetShadowOffset(1, -1)
  return fs
end

function NeatRows:CreateMainFrame()
  local db = self.db

  local f = CreateFrame("Frame", "NeatRowsFrame", UIParent)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  f:EnableMouse(true)

  UI:ApplyBackdrop(f)

  f:SetMinResize(520, 420)

  local w = db.size.w or 760
  local h = db.size.h or 560
  f:SetWidth(w)
  f:SetHeight(h)

  f:ClearAllPoints()
  f:SetPoint(db.pos.point or "CENTER", UIParent, db.pos.relPoint or "CENTER", db.pos.x or 0, db.pos.y or 0)

  f:Hide()

  -- Header (drag region)
  local header = CreateFrame("Button", nil, f)
  header:SetHeight(56)
  header:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
  header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
  header:EnableMouse(true)

  header:SetScript("OnMouseDown", function()
    if NeatRows.db.lockFrame then return end
    if arg1 == "LeftButton" then
      f:StartMoving()
    end
  end)
  header:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
    NeatRows:SaveFramePosition()
  end)

  local title = CreateShadowedText(header, "GameFontNormalLarge")
  title:SetText("NeatRows")
  title:SetPoint("TOP", header, "TOP", 0, 2)

  local subtitle = CreateShadowedText(header, "GameFontHighlightSmall")
  subtitle:SetText("by Methl")
  subtitle:SetTextColor(0.80, 0.80, 0.80, 0.95)
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)

  local moneyText = CreateShadowedText(header, "GameFontHighlightSmall")
  moneyText:SetPoint("RIGHT", header, "RIGHT", -4, 0)
  moneyText:SetJustifyH("RIGHT")
  moneyText:SetText(UI:FormatMoney(GetMoney and GetMoney() or 0))

  local divider = UI:CreateDivider(f)
  divider:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -70)
  divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -70)

  -- Close button (small, subtle)
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() f:Hide() end)

  -- Resize grip
  local grip = CreateFrame("Button", nil, f)
  grip:SetWidth(20); grip:SetHeight(20)
  grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
  grip:EnableMouse(true)

  local gripTex = grip:CreateTexture(nil, "OVERLAY")
  gripTex:SetAllPoints(grip)
  gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  gripTex:SetAlpha(0.65)

  grip:SetScript("OnMouseDown", function()
    if arg1 ~= "LeftButton" then return end
    f:StartSizing("BOTTOMRIGHT")
  end)
  grip:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
    -- Clamp size to screen
    local maxW = UIParent:GetWidth() - 60
    local maxH = UIParent:GetHeight() - 60
    local nw = NR_Clamp(f:GetWidth(), 520, maxW)
    local nh = NR_Clamp(f:GetHeight(), 420, maxH)
    f:SetWidth(nw); f:SetHeight(nh)
    NeatRows:SaveFrameSize()
    NeatRows:QueueRefresh("resize")
  end)

  -- Toolbar
  local toolbar = self:CreateToolbar(f)
  toolbar:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -78)
  toolbar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -78)

  -- Tabs container
  local tabsHost = CreateFrame("Frame", nil, f)
  tabsHost:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -10)
  tabsHost:SetPoint("TOPRIGHT", toolbar, "BOTTOMRIGHT", 0, -10)
  tabsHost:SetHeight(60)

  -- Scroll area
  local scrollFrame = CreateFrame("ScrollFrame", "NeatRowsScrollFrame", f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", tabsHost, "BOTTOMLEFT", 0, -8)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 14)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(1)
  content:SetHeight(1)
  scrollFrame:SetScrollChild(content)

  -- Empty state
  local emptyText = CreateShadowedText(f, "GameFontHighlight")
  emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
  emptyText:SetTextColor(0.85, 0.85, 0.85, 0.85)
  emptyText:Hide()

  self.frame = f
  self.ui = {
    header = header,
    title = title,
    subtitle = subtitle,
    moneyText = moneyText,
    toolbar = toolbar,
    tabsHost = tabsHost,
    scrollFrame = scrollFrame,
    content = content,
    emptyText = emptyText,
    tabButtons = {},
    tabRows = {},
    buttonPool = {},
    activeButtons = 0,
  }

  -- Update layout on show
  f:SetScript("OnShow", function()
    NeatRows:QueueRefresh("show")
  end)

  -- Mousewheel scrolling
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function()
    local delta = arg1 or 0
    local cur = scrollFrame:GetVerticalScroll()
    local step = 60
    scrollFrame:SetVerticalScroll(NR_Clamp(cur - delta * step, 0, (content:GetHeight() - scrollFrame:GetHeight())))
  end)
end

function NeatRows:CreateToolbar(parent)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetHeight(36)

  -- Search box
  local searchBG = CreateFrame("Frame", nil, bar)
  searchBG:SetWidth(240)
  searchBG:SetHeight(28)
  searchBG:SetPoint("LEFT", bar, "LEFT", 0, 0)
  UI:ApplyBackdrop(searchBG, 0.90)
  searchBG:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.95)

  local eb = CreateFrame("EditBox", nil, searchBG)
  eb:SetFontObject(GameFontHighlightSmall)
  eb:SetAutoFocus(false)
  eb:SetTextInsets(8, 22, 0, 0)
  eb:SetHeight(28)
  eb:SetPoint("TOPLEFT", searchBG, "TOPLEFT", 0, 0)
  eb:SetPoint("BOTTOMRIGHT", searchBG, "BOTTOMRIGHT", 0, 0)

  local placeholder = CreateShadowedText(searchBG, "GameFontDisableSmall")
  placeholder:SetText("Search…")
  placeholder:SetTextColor(0.6, 0.6, 0.6, 0.75)
  placeholder:SetPoint("LEFT", searchBG, "LEFT", 10, 0)

  local clear = CreateFrame("Button", nil, searchBG)
  clear:SetWidth(18); clear:SetHeight(18)
  clear:SetPoint("RIGHT", searchBG, "RIGHT", -6, 0)

  local xTex = clear:CreateTexture(nil, "OVERLAY")
  xTex:SetAllPoints(clear)
  xTex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
  xTex:SetAlpha(0.65)

  local function updatePlaceholder()
    local t = eb:GetText() or ""
    if t == "" then placeholder:Show() else placeholder:Hide() end
    if t == "" then clear:Hide() else clear:Show() end
  end

  eb:SetScript("OnTextChanged", function()
    updatePlaceholder()
    NeatRows:SetSearch(eb:GetText() or "")
  end)
  eb:SetScript("OnEscapePressed", function()
    eb:SetText("")
    eb:ClearFocus()
    updatePlaceholder()
  end)
  eb:SetScript("OnEnterPressed", function()
    eb:ClearFocus()
  end)

  clear:SetScript("OnClick", function()
    eb:SetText("")
    eb:ClearFocus()
    updatePlaceholder()
  end)
  clear:Hide()
  updatePlaceholder()

  -- Sort cycle button (compact)
  local sortBtn = CreateFrame("Button", nil, bar)
  sortBtn:SetWidth(110)
  sortBtn:SetHeight(28)
  sortBtn:SetPoint("LEFT", searchBG, "RIGHT", 10, 0)
  UI:ApplyBackdrop(sortBtn, 0.90)
  sortBtn:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.95)

  local sortText = CreateShadowedText(sortBtn, "GameFontHighlightSmall")
  sortText:SetPoint("CENTER", sortBtn, "CENTER", 0, 0)
  sortText:SetText("Sort: Quality")

  local sortModes = { "QUALITY", "NAME", "QUANTITY", "TYPE" }
  local sortLabels = {
    QUALITY = "Quality",
    NAME = "Name",
    QUANTITY = "Quantity",
    TYPE = "Type",
  }

  sortBtn:SetScript("OnClick", function()
    local cur = NeatRows.state.sortMode or "QUALITY"
    local idx = 1
    for i = 1, table.getn(sortModes) do
      if sortModes[i] == cur then idx = i break end
    end
    idx = idx + 1
    if idx > table.getn(sortModes) then idx = 1 end
    local nextMode = sortModes[idx]
    NeatRows:SetSortMode(nextMode)
    sortText:SetText("Sort: " .. (sortLabels[nextMode] or nextMode))
  end)

  -- Collapse/Expand placeholder (for future grouped sections)
  local collapseBtn = CreateFrame("Button", nil, bar)
  collapseBtn:SetWidth(120)
  collapseBtn:SetHeight(28)
  collapseBtn:SetPoint("LEFT", sortBtn, "RIGHT", 10, 0)
  UI:ApplyBackdrop(collapseBtn, 0.90)
  collapseBtn:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.95)

  local cText = CreateShadowedText(collapseBtn, "GameFontDisableSmall")
  cText:SetPoint("CENTER", collapseBtn, "CENTER", 0, 0)
  cText:SetText("Groups: N/A")

  collapseBtn:Disable()

  -- Settings gear placeholder
  local gear = CreateFrame("Button", nil, bar)
  gear:SetWidth(28); gear:SetHeight(28)
  gear:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
  UI:ApplyBackdrop(gear, 0.90)
  gear:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.95)

  local gTex = gear:CreateTexture(nil, "OVERLAY")
  gTex:SetAllPoints(gear)
  gTex:SetTexture("Interface\\Minimap\\UI-Minimap-TrackingBorder")
  gTex:SetTexCoord(0.15, 0.85, 0.15, 0.85)
  gTex:SetAlpha(0.55)

  gear:SetScript("OnClick", function()
    NeatRows:Print("Options panel not implemented yet.")
  end)

  self.ui = self.ui or {}
  self.ui.searchBox = eb
  self.ui.sortText = sortText

  return bar
end

-- Tabs
local function TabSetActive(btn, active)
  if active then
    btn._active = true
    btn:SetBackdropColor(UI.colors.tabActiveBg[1], UI.colors.tabActiveBg[2], UI.colors.tabActiveBg[3], UI.colors.tabActiveBg[4])
    btn:SetBackdropBorderColor(UI.colors.tabActiveBorder[1], UI.colors.tabActiveBorder[2], UI.colors.tabActiveBorder[3], UI.colors.tabActiveBorder[4])
    btn.text:SetTextColor(1, 0.93, 0.74, 0.98)
  else
    btn._active = false
    btn:SetBackdropColor(UI.colors.tabInactiveBg[1], UI.colors.tabInactiveBg[2], UI.colors.tabInactiveBg[3], UI.colors.tabInactiveBg[4])
    btn:SetBackdropBorderColor(UI.colors.tabInactiveBorder[1], UI.colors.tabInactiveBorder[2], UI.colors.tabInactiveBorder[3], UI.colors.tabInactiveBorder[4])
    btn.text:SetTextColor(0.86, 0.86, 0.86, 0.92)
  end
end

local function TabSetHover(btn, hovering)
  if btn._active then return end
  if hovering then
    btn:SetBackdropBorderColor(0.40, 0.40, 0.40, 0.95)
    btn.text:SetTextColor(0.95, 0.95, 0.95, 0.98)
  else
    btn:SetBackdropBorderColor(UI.colors.tabInactiveBorder[1], UI.colors.tabInactiveBorder[2], UI.colors.tabInactiveBorder[3], UI.colors.tabInactiveBorder[4])
    btn.text:SetTextColor(0.86, 0.86, 0.86, 0.92)
  end
end

function UI:AcquireTabButton(owner, index)
  local ui = owner.ui
  local btn = ui.tabButtons[index]
  if btn then
    btn:Show()
    return btn
  end

  btn = CreateFrame("Button", nil, ui.tabsHost)
  btn:SetHeight(22)
  btn:SetWidth(110)
  UI:ApplyBackdrop(btn, 0.92)

  btn.text = CreateShadowedText(btn, "GameFontHighlightSmall")
  btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)

  btn:SetScript("OnEnter", function() TabSetHover(btn, true) end)
  btn:SetScript("OnLeave", function() TabSetHover(btn, false) end)

  btn:SetScript("OnClick", function()
    NeatRows:SetActiveTab(btn.key)
  end)

  ui.tabButtons[index] = btn
  return btn
end

function UI:HideUnusedTabs(owner, startIndex)
  local ui = owner.ui
  local i = startIndex
  while ui.tabButtons[i] do
    ui.tabButtons[i]:Hide()
    i = i + 1
  end
end

function UI:RebuildTabList(owner, items)
  local ui = owner.ui
  if not ui or not ui.tabsHost then return end

  local db = owner.db
  local maxPerRow = db.maxTabsPerRow or 6
  if maxPerRow < 1 then maxPerRow = 6 end

  local categories = NeatRows_Data:ComputeVisibleCategories(items, db.showEmptyTabs)

  -- Build tab order: All first, then by count desc
  local keys = {}
  for k, v in pairs(categories) do
    if k ~= "ALL" then
      table.insert(keys, k)
    end
  end

  table.sort(keys, function(a, b)
    return (categories[a].count or 0) > (categories[b].count or 0)
  end)

  local ordered = { "ALL" }
  for i = 1, table.getn(keys) do table.insert(ordered, keys[i]) end

  owner.state.visibleCategories = categories
  owner.state.tabOrder = ordered

  -- Layout tabs with wrapping
  local paddingX = 6
  local paddingY = 6
  local tabW = 112
  local tabH = 22

  local rowCount = ceil(table.getn(ordered) / maxPerRow)
  if rowCount < 1 then rowCount = 1 end

  -- Resize tabs host height based on rows
  local hostH = rowCount * tabH + (rowCount - 1) * paddingY
  ui.tabsHost:SetHeight(hostH)

  local idx = 1
  for r = 1, rowCount do
    for c = 1, maxPerRow do
      local key = ordered[idx]
      if not key then break end
      local info = categories[key]
      local label = info.label or key
      local count = info.count or 0

      local btn = UI:AcquireTabButton(owner, idx)
      btn.key = key
      btn.text:SetText(label .. "  |cff9aa0a6" .. count .. "|r")

      btn:ClearAllPoints()
      local x = (c - 1) * (tabW + paddingX)
      local y = - (r - 1) * (tabH + paddingY)
      btn:SetPoint("TOPLEFT", ui.tabsHost, "TOPLEFT", x, y)
      btn:SetWidth(tabW)
      btn:SetHeight(tabH)

      idx = idx + 1
    end
  end

  UI:HideUnusedTabs(owner, idx)
end

function UI:SetActiveTab(owner, key, noRefresh)
  local ui = owner.ui
  if not ui then return end
  local ordered = owner.state.tabOrder or {}
  local activeKey = key or "ALL"
  owner.state.tabKey = activeKey

  for i = 1, table.getn(ordered) do
    local btn = ui.tabButtons[i]
    if btn and btn:IsShown() then
      TabSetActive(btn, btn.key == activeKey)
    end
  end

  if not noRefresh then
    owner:QueueRefresh("tabstyle")
  end
end

-- Item buttons
local function SetItemButtonHover(btn, on)
  if on then
    btn.hover:SetAlpha(0.18)
  else
    btn.hover:SetAlpha(0.00)
  end
end

function UI:AcquireItemButton(owner, index)
  local ui = owner.ui
  local btn = ui.buttonPool[index]
  if btn then
    btn:Show()
    return btn
  end

  btn = CreateFrame("Button", nil, ui.content)
  btn:SetWidth(owner.db.buttonSize)
  btn:SetHeight(owner.db.buttonSize)
  btn:EnableMouse(true)

  -- Background card
  UI:ApplyBackdrop(btn, 0.96)
  btn:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  btn:SetBackdropBorderColor(0.18, 0.18, 0.18, 0.95)

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
  btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 2)
  btn.count:SetJustifyH("RIGHT")

  btn.quality = btn:CreateTexture(nil, "BORDER")
  btn.quality:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  btn.quality:SetBlendMode("ADD")
  btn.quality:SetAlpha(0.0)
  btn.quality:SetPoint("TOPLEFT", btn, "TOPLEFT", -6, 6)
  btn.quality:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 6, -6)

  btn.hover = btn:CreateTexture(nil, "HIGHLIGHT")
  btn.hover:SetTexture("Interface\\Buttons\\WHITE8X8")
  btn.hover:SetAllPoints(btn)
  btn.hover:SetVertexColor(1, 1, 1, 1)
  btn.hover:SetAlpha(0.0)

  btn.searchGlow = btn:CreateTexture(nil, "OVERLAY")
  btn.searchGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  btn.searchGlow:SetBlendMode("ADD")
  btn.searchGlow:SetPoint("TOPLEFT", btn, "TOPLEFT", -6, 6)
  btn.searchGlow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 6, -6)
  btn.searchGlow:SetVertexColor(1, 1, 1, 1)
  btn.searchGlow:SetAlpha(0.0)

  btn:SetScript("OnEnter", function()
    SetItemButtonHover(btn, true)
    if btn.bag and btn.slot then
      GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
      GameTooltip:SetBagItem(btn.bag, btn.slot)
      GameTooltip:Show()
    end
  end)
  btn:SetScript("OnLeave", function()
    SetItemButtonHover(btn, false)
    GameTooltip:Hide()
  end)

  btn:SetScript("OnClick", function()
    if not btn.bag or not btn.slot then return end
    -- Let modified clicks work as expected
    if IsShiftKeyDown() and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
      local link = GetContainerItemLink(btn.bag, btn.slot)
      if link then
        ChatFrameEditBox:Insert(link)
      end
      return
    end
    PickupContainerItem(btn.bag, btn.slot)
  end)

  ui.buttonPool[index] = btn
  return btn
end

function UI:ReleaseAllButtons(owner, startIndex)
  local ui = owner.ui
  local i = startIndex
  while ui.buttonPool[i] do
    ui.buttonPool[i]:Hide()
    i = i + 1
  end
end

local function QualityColor(q)
  if not q then return 0.18, 0.18, 0.18 end
  -- Vanilla-like item quality colors (approx)
  if q == 0 then return 0.62, 0.62, 0.62 end -- poor
  if q == 1 then return 1.00, 1.00, 1.00 end -- common
  if q == 2 then return 0.12, 1.00, 0.00 end -- uncommon
  if q == 3 then return 0.00, 0.44, 0.87 end -- rare
  if q == 4 then return 0.64, 0.21, 0.93 end -- epic
  if q == 5 then return 1.00, 0.50, 0.00 end -- legendary
  return 1.00, 1.00, 1.00
end

function UI:LayoutGrid(owner, items)
  local ui = owner.ui
  if not ui then return end

  local scrollFrame = ui.scrollFrame
  local content = ui.content
  local emptyText = ui.emptyText

  local buttonSize = owner.db.buttonSize or 36
  local pad = owner.db.padding or 6
  local margin = 10

  local availableW = scrollFrame:GetWidth() - 2
  if availableW < 200 then availableW = 200 end

  local cols = floor((availableW - margin * 2 + pad) / (buttonSize + pad))
  cols = NR_Clamp(cols, 6, 18)

  local count = table.getn(items)
  if count == 0 then
    UI:ReleaseAllButtons(owner, 1)
    content:SetHeight(1)
    emptyText:Show()
    local q = owner.state.search or ""
    if q ~= "" then
      emptyText:SetText("No results for '" .. q .. "'.")
    else
      emptyText:SetText("No items found.")
    end
    return
  end

  emptyText:Hide()

  for i = 1, count do
    local it = items[i]
    local btn = UI:AcquireItemButton(owner, i)

    btn.bag = it.bag
    btn.slot = it.slot

    btn.icon:SetTexture(it.texture or nil)
    if it.count and it.count > 1 then
      btn.count:SetText(it.count)
      btn.count:Show()
    else
      btn.count:SetText("")
      btn.count:Hide()
    end

    -- Quality border glow
    if it.quality and it.quality >= 2 then
      local r, g, b = QualityColor(it.quality)
      btn.quality:SetVertexColor(r, g, b, 1)
      btn.quality:SetAlpha(0.55)
    else
      btn.quality:SetAlpha(0.0)
    end

    -- Search highlight glow (subtle)
    if owner.state.search and owner.state.search ~= "" and it._searchMatch then
      btn.searchGlow:SetAlpha(0.40)
    else
      btn.searchGlow:SetAlpha(0.0)
    end

    -- Position
    local row = floor((i - 1) / cols)
    local col = (i - 1) - row * cols

    local x = margin + col * (buttonSize + pad)
    local y = -margin - row * (buttonSize + pad)

    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
    btn:SetWidth(buttonSize)
    btn:SetHeight(buttonSize)
  end

  UI:ReleaseAllButtons(owner, count + 1)

  local rows = ceil(count / cols)
  local height = margin * 2 + rows * buttonSize + (rows - 1) * pad
  if height < 1 then height = 1 end
  content:SetHeight(height)
  content:SetWidth(availableW)
end