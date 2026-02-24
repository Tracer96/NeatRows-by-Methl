-- NeatRows by Methl (Vanilla 1.12 / Turtle WoW)
-- Sort + Search

NeatRows_SortFilter = NeatRows_SortFilter or {}
local SF = NeatRows_SortFilter

local function lower(s)
  if not s then return "" end
  return string.lower(s)
end

function SF:ApplySearch(items, query, tabKey)
  query = query or ""
  local q = lower(query)
  local filterTab = tabKey or "ALL"

  local out = {}
  local n = table.getn(items)

  for i = 1, n do
    local it = items[i]
    it._searchMatch = false

    local tabOk = (filterTab == "ALL") or (it.category == filterTab)
    if tabOk then
      if q == "" then
        table.insert(out, it)
      else
        local name = lower(it.name)
        if name ~= "" and string.find(name, q, 1, true) then
          it._searchMatch = true
          table.insert(out, it)
        else
          -- If name missing (GetItemInfo not ready), fall back to link
          local link = lower(it.link)
          if link ~= "" and string.find(link, q, 1, true) then
            it._searchMatch = true
            table.insert(out, it)
          end
        end
      end
    end
  end

  return out
end

local function stableTie(a, b)
  if a.bag ~= b.bag then return a.bag < b.bag end
  return a.slot < b.slot
end

function SF:ApplySort(items, mode)
  mode = mode or "QUALITY"

  table.sort(items, function(a, b)
    if mode == "NAME" then
      local an = lower(a.name)
      local bn = lower(b.name)
      if an ~= bn then return an < bn end
      return stableTie(a, b)

    elseif mode == "QUANTITY" then
      local ac = a.count or 1
      local bc = b.count or 1
      if ac ~= bc then return ac > bc end
      local an = lower(a.name)
      local bn = lower(b.name)
      if an ~= bn then return an < bn end
      return stableTie(a, b)

    elseif mode == "TYPE" then
      local at = lower(a.type)
      local bt = lower(b.type)
      if at ~= bt then return at < bt end
      local ast = lower(a.subtype)
      local bst = lower(b.subtype)
      if ast ~= bst then return ast < bst end
      local an = lower(a.name)
      local bn = lower(b.name)
      if an ~= bn then return an < bn end
      return stableTie(a, b)

    else -- QUALITY
      local aq = a.quality or 1
      local bq = b.quality or 1
      if aq ~= bq then return aq > bq end
      local an = lower(a.name)
      local bn = lower(b.name)
      if an ~= bn then return an < bn end
      return stableTie(a, b)
    end
  end)

  return items
end