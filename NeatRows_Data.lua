-- NeatRows by Methl (Vanilla 1.12 / Turtle WoW)
-- Data: scan bags, item cache, categorization

NeatRows_Data = NeatRows_Data or {}
local D = NeatRows_Data

D.cache = D.cache or {
  byID = {}, -- [itemID] = { name, quality, type, subtype, texture, lastSeen }
}

local function ParseItemID(itemLink)
  if not itemLink then return nil end
  local id = string.match(itemLink, "item:(%d+):")
  if id then return tonumber(id) end
  return nil
end

function D:GetCached(itemID)
  if not itemID then return nil end
  return self.cache.byID[itemID]
end

function D:SetCached(itemID, data)
  if not itemID then return end
  self.cache.byID[itemID] = data
end

function D:GetItemInfoCached(itemLink, textureFallback, qualityFallback)
  local itemID = ParseItemID(itemLink)
  if not itemID then
    return nil, nil, nil, nil, nil, textureFallback, qualityFallback, nil
  end

  local cached = self:GetCached(itemID)
  if cached and cached.name then
    return itemID, cached.name, cached.type, cached.subtype, cached.quality, cached.texture or textureFallback, cached.quality or qualityFallback, cached
  end

  local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, tex = GetItemInfo(itemLink)
  if name then
    local data = {
      name = name,
      type = class,
      subtype = subclass,
      quality = quality,
      texture = tex or textureFallback,
      lastSeen = time(),
    }
    self:SetCached(itemID, data)
    return itemID, name, class, subclass, quality, data.texture, quality, data
  end

  -- Not in cache yet (client hasn't loaded info)
  return itemID, nil, nil, nil, qualityFallback, textureFallback, qualityFallback, nil
end

function D:CategorizeItem(item)
  -- Order matters; keep cheap checks first
  local t = item.type
  local st = item.subtype

  if not item.link then return "MISC" end

  if t == "Quest" then
    return "QUEST"
  end

  if t == "Consumable" then
    return "CONSUMABLES"
  end

  if t == "Trade Goods" then
    return "TRADE"
  end

  if t == "Weapon" or t == "Armor" then
    return "GEAR"
  end

  -- Subtype heuristics (vanilla strings vary by locale; keep minimal)
  if st == "Food & Drink" or st == "Potion" or st == "Bandage" then
    return "CONSUMABLES"
  end

  return "MISC"
end

function D:CategoryLabel(key)
  if key == "ALL" then return "All" end
  if key == "CONSUMABLES" then return "Consumables" end
  if key == "TRADE" then return "Trade Goods" end
  if key == "GEAR" then return "Gear" end
  if key == "QUEST" then return "Quest" end
  if key == "MISC" then return "Misc" end
  if key == "UNKNOWN" then return "Unknown" end
  return key
end

function D:ScanBags()
  local items = {}

  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local texture, count, locked, quality = GetContainerItemInfo(bag, slot)
      if texture then
        local link = GetContainerItemLink(bag, slot)
        local itemID, name, class, subclass, q2, tex2 = self:GetItemInfoCached(link, texture, quality)

        local item = {
          bag = bag,
          slot = slot,
          link = link,
          itemID = itemID,
          name = name,
          type = class,
          subtype = subclass,
          texture = tex2 or texture,
          count = count or 1,
          quality = q2 or quality,
          category = nil,
          _searchMatch = false,
        }

        item.category = self:CategorizeItem(item)
        table.insert(items, item)
      end
    end
  end

  return items
end

function D:BuildCategories(items, out)
  -- out: reused table
  for k in pairs(out) do out[k] = nil end

  out.ALL = out.ALL or { key = "ALL", label = self:CategoryLabel("ALL"), count = 0 }

  local n = table.getn(items)
  for i = 1, n do
    local it = items[i]
    out.ALL.count = out.ALL.count + 1

    local k = it.category or "UNKNOWN"
    if not out[k] then
      out[k] = { key = k, label = self:CategoryLabel(k), count = 0 }
    end
    out[k].count = out[k].count + 1
  end

  -- Ensure baseline keys exist if desired
  if not out.CONSUMABLES then out.CONSUMABLES = { key="CONSUMABLES", label=self:CategoryLabel("CONSUMABLES"), count=0 } end
  if not out.TRADE then out.TRADE = { key="TRADE", label=self:CategoryLabel("TRADE"), count=0 } end
  if not out.GEAR then out.GEAR = { key="GEAR", label=self:CategoryLabel("GEAR"), count=0 } end
  if not out.QUEST then out.QUEST = { key="QUEST", label=self:CategoryLabel("QUEST"), count=0 } end
  if not out.MISC then out.MISC = { key="MISC", label=self:CategoryLabel("MISC"), count=0 } end
end

function D:ComputeVisibleCategories(items, showEmptyTabs)
  local tmp = {}
  self:BuildCategories(items, tmp)

  local out = {}
  for k, v in pairs(tmp) do
    if showEmptyTabs or (v.count and v.count > 0) or k == "ALL" then
      out[k] = { key = k, label = v.label, count = v.count or 0 }
    end
  end
  return out
end